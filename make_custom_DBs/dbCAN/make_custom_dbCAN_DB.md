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
# Concatenate and dereplicate
cd cazyme_seqs
for i in *faa; do cat $i; done > all_cazymes_raw.fa
# Dereplicate at 90% identity (adjust -c and -n for your memory budget)
cd-hit -i all_cazymes_raw.faa \
       -o all_cazymes_90.faa \
       -c 0.90 -n 5 \
       -T 32 -M 64000 \
       -d 0

# Fix family names in headers
python3 -I - <<'EOF'
import re, sys

with open("all_cazymes_100.faa") as fh, open("all_cazymes_100_fixed.faa", "w") as out:
    for line in fh:
        if line.startswith(">"):
            parts = line[1:].rstrip().split("|")
            if len(parts) >= 2:
                parts[1] = re.sub(r'\([^)]*\)', '', parts[1]).split('+')[0].strip()
            out.write(">" + "|".join(parts) + "\n")
        else:
            out.write(line)
EOF
# Check the number of gene families (it should be ~700)
grep "^>" all_cazymes_100_fixed.faa | awk -F'|' '{print $2}' | sort -u | wc -l

# Build DIAMOND database
diamond makedb \
    --in  all_cazymes_90.faa \
    --db  custom_cazyme_diamond \
    --threads 32
```
## Step 5: Build custom HMM database
```
# Convert to two-line FASTA, sort by family, split into per-family files
awk '/^>/{if(seq) print seq; print; seq=""} !/^>/{seq=seq$0} END{if(seq) print seq}' \
    all_cazymes_100_fixed.faa > all_cazymes_2line.faa

paste - - < all_cazymes_2line.faa \
    | sort -t'|' -k2,2 --parallel=4 \
    | tr '\t' '\n' > all_cazymes_sorted.faa

# Stream through sorted file — one file open at a time
python3 -I - <<'EOF'
from pathlib import Path
Path("family_seqs").mkdir(exist_ok=True)
current_family, current_handle, n = None, None, 0
with open("all_cazymes_sorted.faa") as fh:
    for line in fh:
        if line.startswith(">"):
            parts = line[1:].split("|")
            family = parts[1] if len(parts) >= 2 else None
            if family != current_family:
                if current_handle: current_handle.close()
                current_family = family
                current_handle = open(f"family_seqs/{family}.faa", "w") if family else None
                if family: n += 1
            if current_handle: current_handle.write(line)
        elif current_handle:
            current_handle.write(line)
if current_handle: current_handle.close()
print(f"Wrote {n} family files", file=__import__('sys').stderr)
EOF
# Filter family list to valid CAZyme families
find family_seqs -name "*.faa" > family_list_orig.txt

# Keep only real CAZyme class prefixes
grep -P '^family_seqs/(GH|GT|PL|CE|AA|CBM)[0-9]' family_list_orig.txt > family_list.txt
wc -l family_list.txt

## Build HMM profiles (file name: build_hmms_array.sh)
#!/bin/bash
#SBATCH --job-name=build_hmms
#SBATCH --partition=k2-medpri,k2-bioinf
#SBATCH --array=1-747
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=6:00:00
#SBATCH --output=logs/build_hmms-%A-%a.out
#SBATCH --error=logs/build_hmms-%A-%a.err

MAFFT=/mnt/scratch2/igfs-anaconda/conda-envs/mafft_v7.525/bin/mafft
HMMBUILD=/mnt/scratch2/igfs-anaconda/conda-envs/hmmer_3.4/bin/hmmbuild

mkdir -p family_hmms logs

faa=$(sed -n "${SLURM_ARRAY_TASK_ID}p" family_list.txt)
[[ -z "$faa" ]] && exit 0

family=$(basename "$faa" .faa)
hmm="family_hmms/${family}.hmm"

[[ -f "$hmm" ]] && [[ -s "$hmm" ]] && exit 0   # skip if already done and non-empty

# Skip if fewer than 2 sequences
n=$(grep -c "^>" "$faa")
if (( n < 2 )); then
    echo "SKIP: $family has only $n sequence(s)"
    exit 0
fi

# Subsample to 2000 sequences if needed
input_faa="$faa"
if (( n > 2000 )); then
    tmpfile="/tmp/${family}_sub_${SLURM_ARRAY_TASK_ID}.faa"
    python3 -I - "$faa" "$tmpfile" <<'EOF'
import sys, random

in_faa, out_faa = sys.argv[1], sys.argv[2]

seqs = []
current_header = None
current_seq = []
with open(in_faa) as fh:
    for line in fh:
        if line.startswith(">"):
            if current_header:
                seqs.append((current_header, "".join(current_seq)))
            current_header = line
            current_seq = []
        else:
            current_seq.append(line)
    if current_header:
        seqs.append((current_header, "".join(current_seq)))

random.seed(42)
sampled = random.sample(seqs, min(2000, len(seqs)))

with open(out_faa, "w") as out:
    for header, seq in sampled:
        out.write(header)
        out.write(seq)
EOF
    input_faa="$tmpfile"
fi

# Align and build HMM
"$MAFFT" --quiet --auto --thread "$SLURM_CPUS_PER_TASK" "$input_faa" \
    | "$HMMBUILD" --informat afa -n "$family" --cpu "$SLURM_CPUS_PER_TASK" "$hmm" -

echo "Exit code: $?"

[[ "$input_faa" != "$faa" ]] && rm -f "$input_faa"


# Concatenate and press HMMs
cat family_hmms/*.hmm > custom_cazyme.hmm
hmmpress custom_cazyme.hmm
```
## Step 6: Test custom databases using dbCAN
```
#!/bin/bash
#SBATCH --time=23:59:59
#SBATCH --partition=k2-medpri,k2-bioinf
#SBATCH --job-name=dbCAN_holor
#SBATCH --mem=50G
#SBATCH --ntasks=1
#SBATCH --mail-user=ldillon05@qub.ac.uk
#SBATCH --mail-type=END,BEGIN,FAIL
#SBATCH --error=dbCAN_holor-%j.err
#SBATCH --output=dbCAN_holor-%j.out

source activate /mnt/scratch2/igfs-anaconda/conda-envs/dbCAN


run_dbcan CAZyme_annotation \
    --input_raw_data  02f06-5270-4861-9fb9-956eae9f4ff6/02f06-5270-4861-9fb9-956eae9f4ff6.faa \
    --mode            protein \
    --db_dir          dbCAN_dbs/ \
    --output_dir      test_dbCAN/ \
    --methods         diamond,hmm \
```
