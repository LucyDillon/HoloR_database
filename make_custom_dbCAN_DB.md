# How to make the dbCAN custom databases:

## Step 1: Run dbCAN on protein files
```
#!/bin/bash
#SBATCH --time=7-23:59:59
#SBATCH --partition=k2-lowpri,k2-bioinf
#SBATCH --job-name=dbCAN_holor
#SBATCH --mem=50G
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mail-user=ldillon05@qub.ac.uk
#SBATCH --mail-type=END,BEGIN,FAIL
#SBATCH --error=dbCAN_holor-%j.err
#SBATCH --output=dbCAN_holor-%j.out

set -euo pipefail

source activate /mnt/scratch2/igfs-anaconda/conda-envs/dbCAN

JOB_NUM=$1
START=$(( (JOB_NUM - 1) * 1000 + 1 ))
END=$(( JOB_NUM * 1000 ))

echo "Job $JOB_NUM: lines $START to $END"

mkdir -p dbcan_out

sed -n "${START},${END}p" dbcan_missing.txt | while read -r i; do

    sample="${i%.fasta}"
    input="dereplicated_results/bakta/${i}/${sample}.faa"

    if [[ ! -f "$input" ]]; then
        echo "WARNING: missing $input — skipping" >&2
        continue
    fi

    if [[ -f "dbcan_out/${sample}/overview.txt" ]]; then
        echo "SKIP: $sample already done"
        continue
    fi

    echo "Processing: $sample"

    run_dbcan CAZyme_annotation \
        --input_raw_data  "$input" \
        --mode            protein \
        --db_dir          /mnt/scratch2/igfs-databases/dbcan_db \
        --output_dir      dbcan_out/${sample} \
        --methods         diamond,hmm,dbCANsub \
        --threads         8

done
```

## Step 2: Aggregate all the overview.tsv files
```
#!/usr/bin/env python3
# collect_cazyme_ids.py
# Scans all dbcan_out/*/overview.tsv, filters ≥2 method agreement
# Outputs: cazyme_proteins.tsv  (sample, protein_id, families)

import os
import sys
from pathlib import Path
from multiprocessing import Pool

DBCAN_OUT = Path("dbcan_out")
MIN_TOOLS = 2

def parse_overview(sample_dir):
    overview = sample_dir / "overview.tsv"
    if not overview.exists():
        return []
    sample = sample_dir.name
    results = []
    with open(overview) as fh:
        header = fh.readline()  # skip header
        for line in fh:
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 6:
                continue
            gene_id, ec, hmmer, dbcansub, diamond, n_tools = parts[:6]
            try:
                if int(n_tools) < MIN_TOOLS:
                    continue
            except ValueError:
                continue
            # Use HMMER family as primary (most specific); fall back to DIAMOND
            family = hmmer.split("|")[0] if hmmer != "-" else diamond.split("|")[0]
            if family == "-":
                continue
            results.append(f"{sample}\t{gene_id}\t{family}\n")
    return results

def main():
    sample_dirs = [d for d in DBCAN_OUT.iterdir() if d.is_dir()]
    print(f"Found {len(sample_dirs)} sample directories", file=sys.stderr)
    
    with Pool(processes=32) as pool:
        all_results = pool.map(parse_overview, sample_dirs)
    
    with open("cazyme_proteins.tsv", "w") as out:
        out.write("sample\tprotein_id\tfamily\n")
        for chunk in all_results:
            out.writelines(chunk)

if __name__ == "__main__":
    main()
```

## Step 3: Extract and rename the sequences
```
#!/bin/bash
#SBATCH --time=04:00:00
#SBATCH --partition=k2-medpri,k2-bioinf
#SBATCH --job-name=extract_seqs
#SBATCH --array=1-82        # adjust: ceil(n_samples / 1000)
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --output=logs/extract_seqs-%A-%a.out
#SBATCH --error=logs/extract_seqs-%A-%a.err

mkdir -p cazyme_seqs logs

JOB_NUM=$SLURM_ARRAY_TASK_ID
START=$(( (JOB_NUM - 1) * 1000 + 1 ))
END=$(( JOB_NUM * 1000 ))

sed -n "${START},${END}p" sample_dirs.txt | while read -r sample_dir; do

    sample=$(basename "$sample_dir")
    faa="${sample_dir}/uniInput.faa"
    overview="${sample_dir}/overview.tsv"
    outfile="cazyme_seqs/${sample}.faa"

    [[ -f "$outfile" ]] && continue
    [[ ! -f "$faa" ]]   && continue
    [[ ! -f "$overview" ]] && continue

    python3 -I - "$overview" "$faa" "$outfile" "$sample" <<'PYEOF'
import sys

overview, faa, outfile, sample = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

lookup = {}
with open(overview) as fh:
    fh.readline()
    for line in fh:
        parts = line.rstrip().split("\t")
        if len(parts) < 6:
            continue
        gene_id, ec, hmmer, dbcansub, diamond, n_tools = parts[:6]
        try:
            if int(n_tools) < 2:
                continue
        except ValueError:
            continue
        family = hmmer.split("|")[0] if hmmer != "-" else diamond.split("|")[0]
        if family != "-":
            lookup[gene_id] = family

if not lookup:
    sys.exit(0)

keep = False
with open(faa) as fa, open(outfile, "w") as out:
    for line in fa:
        if line.startswith(">"):
            pid = line[1:].split()[0]
            if pid in lookup:
                out.write(f">{pid}|{lookup[pid]}|{sample}\n")
                keep = True
            else:
                keep = False
        elif keep:
            out.write(line)
PYEOF

done
```
## Step 4: Build custom DIAMOND database
```
cd cazyme_seqs
for i in *faa; do cat $i; done > all_cazymes_raw.fa
# Dereplicate at 90% identity (adjust -c and -n for your memory budget)
cd-hit -i all_cazymes_raw.faa \
       -o all_cazymes_90.faa \
       -c 0.90 -n 5 \
       -T 32 -M 64000 \
       -d 0

# Build DIAMOND database
diamond makedb \
    --in  all_cazymes_90.faa \
    --db  custom_cazyme_diamond \
    --threads 32
```
## Step 5: Build custom HMM database
```
# Split sequences by family
python3 - <<'EOF'
from pathlib import Path
import sys

Path("family_seqs").mkdir(exist_ok=True)
handles = {}
current_family = None
write = False

with open("all_cazymes_90.faa") as fh:
    for line in fh:
        if line.startswith(">"):
            parts = line[1:].split("|")
            if len(parts) >= 2:
                family = parts[1]
                if family not in handles:
                    handles[family] = open(f"family_seqs/{family}.faa", "w")
                current_family = family
                handles[current_family].write(line)
        else:
            if current_family:
                handles[current_family].write(line)

for h in handles.values():
    h.close()
print(f"Wrote {len(handles)} family FASTA files", file=sys.stderr)
EOF

# Align each family and build HMM (SLURM array or parallel)
build_family_hmm() {
    faa="$1"
    family=$(basename "$faa" .faa)
    hmm="family_hmms/${family}.hmm"
    [[ -f "$hmm" ]] && return
    mkdir -p family_hmms

    # Cap at 5000 seqs per family to keep alignment tractable
    n=$(grep -c "^>" "$faa")
    if (( n > 5000 )); then
        seqtk sample -s42 "$faa" 5000 > /tmp/${family}_sub.faa
        faa=/tmp/${family}_sub.faa
    fi

    mafft --auto --thread 4 "$faa" 2>/dev/null | \
        hmmbuild --cpu 4 "$hmm" - > /dev/null 2>&1
}
export -f build_family_hmm

find family_seqs -name "*.faa" | \
    parallel -j 8 build_family_hmm {}

# Concatenate and press
cat family_hmms/*.hmm > custom_cazyme.hmm
hmmpress custom_cazyme.hmm
```
## Step 6: Test custom databases using dbCAN
```
run_dbcan CAZyme_annotation \
    --input_raw_data  sample.faa \
    --mode            protein \
    --db_dir          /path/to/your/custom_db_dir \
    --output_dir      out/ \
    --methods         diamond,hmm \
    --threads         8
```
