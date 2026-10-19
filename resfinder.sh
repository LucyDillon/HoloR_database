#!/bin/bash
#SBATCH --time=7-23:59:59
#SBATCH --partition=k2-lowpri,k2-bioinf
#SBATCH --mail-user=l.dillon@qub.ac.uk
#SBATCH --mem=10G
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --error=resfinder-%j.err
#SBATCH --output=resfinder-%j.out
#SBATCH --job-name=resfinder

set -euo pipefail

# Activate conda environment
source activate /mnt/scratch2/igfs-anaconda/conda-envs/resfinder_4.7.2

# Paths
LIST="../../medium_high_list_updated.txt"
FASTA_DIR="../../fasta_files_for_drep"
DB="/mnt/scratch2/igfs-databases/AMR/resfinder_db-2_4_0"


echo "Date: $(date)"
echo "Working directory: $(pwd)"
echo "Database: $DB"

while IFS= read -r i; do

    # Skip empty lines
    [[ -z "$i" ]] && continue

    INPUT="${FASTA_DIR}/${i}"
    OUTPUT="resfinder/${i%%.fasta}/"

    echo "----------------------------------------"
    echo "Processing: $i"
    echo "Input:      $INPUT"
    echo "Output:     $OUTPUT"
    echo "Started:    $(date)"

    if [[ ! -f "$INPUT" ]]; then
        echo "ERROR: Input file not found: $INPUT" >&2
        continue
    fi

    python -m resfinder \
        -ifa "$INPUT" \
        -acq \
        -db_res "$DB" \
        -o "$OUTPUT"

    echo "Finished:   $(date)"

done < "$LIST"

echo "All samples completed: $(date)"
