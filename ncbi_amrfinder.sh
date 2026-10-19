#!/bin/bash
#SBATCH --time=7-23:59:59
#SBATCH --partition=k2-lowpri,k2-bioinf
#SBATCH --mail-user=ldillon05@qub.ac.uk
#SBATCH --mem=50G
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --error=ncbi_amrfinder_NEW-%j.err
#SBATCH --output=ncbi_amrfinder_NEW-%j.out
#SBATCH --job-name=ncbi_amrfinder

set -euo pipefail

# Activate conda environment
source activate /mnt/scratch2/igfs-anaconda/conda-envs/amrfinder_v4.2.7

# Paths
LIST="../../medium_high_list_updated.txt"
FASTA_DIR="../../fasta_files_for_drep"
DB="/mnt/scratch2/igfs-databases/amrfinder/2026-05-15.1"


echo "Starting AMRFinder"
echo "Date: $(date)"
echo "Working directory: $(pwd)"
echo "Database: $DB"

while IFS= read -r i; do

    # Skip empty lines
    [[ -z "$i" ]] && continue

    INPUT="${FASTA_DIR}/${i}"
    OUTPUT="${i%.*}_amrfinder.tsv"

    echo "----------------------------------------"
    echo "Processing: $i"
    echo "Input:      $INPUT"
    echo "Output:     $OUTPUT"
    echo "Started:    $(date)"

    if [[ ! -f "$INPUT" ]]; then
        echo "ERROR: Input file not found: $INPUT" >&2
        continue
    fi

    amrfinder \
        -n "$INPUT" \
        -d "$DB" \
        -o "$OUTPUT"

    echo "Finished:   $(date)"

done < "$LIST"

echo "All samples completed: $(date)"
