#!/bin/bash
#SBATCH --time=4-23:59:59
#SBATCH --partition=k2-lowpri,k2-bioinf
#SBATCH --mem=220G
#SBATCH --cpus-per-task=16
#SBATCH --mail-user=l.dillon@qub.ac.uk
#SBATCH --mail-type=END,BEGIN,FAIL
#SBATCH --error=build_kraken-%j.err
#SBATCH --output=build_kraken-%j.out
#SBATCH --job-name=build_kraken_db

source activate /mnt/scratch2/igfs-anaconda/conda-envs/kraken2_2.17.1

DBNAME=kraken2_db_clean
TAXDIR=dereplicated_results/gtdbtk_all/gtdb-taxdump/R220
LIST=medium_high_list_updated_clean.txt
DONE="$DBNAME.added.done"

# Set to "--no-masking" to skip low-complexity masking (faster); leave empty to mask
MASK_FLAG=""

# Set up the DB only on a fresh start; on a requeue, resume where it stopped
if [[ ! -d "$DBNAME/taxonomy" ]]; then
    mkdir -p "$DBNAME/taxonomy"
    cp "$TAXDIR/nodes.dmp" "$TAXDIR/names.dmp" "$DBNAME/taxonomy/"
    : > "$DONE"
fi
[[ -f "$DONE" ]] || : > "$DONE"
mkdir -p tagged_fastas

# genome <tab> taxid, restricted to genomes in your list (CRs stripped)
CLEAN_LIST=$(mktemp)
trap 'rm -f "$CLEAN_LIST"' EXIT
tr -d '\r' < "$LIST" > "$CLEAN_LIST"
awk 'NR==FNR {want[$1]=1; next} ($1 in want)' "$CLEAN_LIST" "$TAXDIR/taxid.map" > list_with_taxid.tsv

echo "Matched genomes: $(wc -l < list_with_taxid.tsv)"

# Drop genomes already added in a previous attempt
# Guard against empty $DONE — NR==FNR fails silently with an empty first file
if [[ -s "$DONE" ]]; then
    awk 'NR==FNR {d[$1]=1; next} !($1 in d)' "$DONE" list_with_taxid.tsv > todo.tsv
else
    cp list_with_taxid.tsv todo.tsv
fi

echo "Genomes to add: $(wc -l < todo.tsv) (already done: $(wc -l < "$DONE"))"

while IFS=$'\t' read -r f taxid; do
    fasta="fasta_files_for_drep/${f}.fasta"

    if [[ ! -f "$fasta" ]]; then
        echo "WARNING: missing $fasta" >&2
        continue
    fi

    # Unique contig IDs + correctly placed taxid tag
    awk -v g="$f" -v t="$taxid" \
        '/^>/ {n++; print ">" g "_" n "|kraken:taxid|" t; next} {print}' \
        "$fasta" > "tagged_fastas/${f}.fa"

    if kraken2-build --add-to-library "tagged_fastas/${f}.fa" --db "$DBNAME" $MASK_FLAG; then
        echo "$f" >> "$DONE"
        rm -f "tagged_fastas/${f}.fa"
    else
        echo "ERROR: failed to add $f, stopping" >&2
        exit 1
    fi
done < todo.tsv

kraken2-build --build --db "$DBNAME" --threads "$SLURM_CPUS_PER_TASK"

# Only report success if the core files exist
if [[ -s "$DBNAME/hash.k2d" && -s "$DBNAME/opts.k2d" && -s "$DBNAME/taxo.k2d" ]]; then
    echo "Build complete"
    rmdir tagged_fastas 2>/dev/null || true
else
    echo "ERROR: build did not produce the expected files" >&2
    exit 1
fi
