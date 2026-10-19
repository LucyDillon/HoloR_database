#!/bin/bash
#SBATCH --time=1-23:59:00
#SBATCH --partition=k2-himem
#SBATCH --mem=1200G
#SBATCH --cpus-per-task=16
#SBATCH --mail-user=l.dillon@qub.ac.uk
#SBATCH --mail-type=END,FAIL
#SBATCH --error=kraken-%j.err
#SBATCH --job-name=kraken

set -euo pipefail

# Activate Kraken2 environment
source activate /mnt/scratch2/igfs-anaconda/conda-envs/kraken2

# Input/output directories
READ_DIR="mapping_reads"
OUT_DIR="kraken_results"

# Kraken2 database
DB="/mnt/scratch2/igfs-databases/kraken2_RefSeqV205_Complete_db"

# Check that a sample name was provided
if [[ $# -ne 1 ]]; then
    echo "Usage: sbatch run_kraken2.sh SAMPLE_NAME"
    echo "Example: sbatch run_kraken2.sh sample123"
    exit 1
fi

name="$1"

# Define input files
r1="$READ_DIR/${name}_clean_1.fastq.gz"
r2="$READ_DIR/${name}_clean_2.fastq.gz"

# Make sure output directory exists
mkdir -p "$OUT_DIR"

# Check input directory
if [[ ! -d "$READ_DIR" ]]; then
    echo "ERROR: Input directory does not exist:"
    echo "       $READ_DIR"
    exit 1
fi

# Check Kraken2 database
if [[ ! -d "$DB" ]]; then
    echo "ERROR: Kraken2 database does not exist:"
    echo "       $DB"
    exit 1
fi

# Check R1
if [[ ! -f "$r1" ]]; then
    echo "ERROR: R1 file does not exist:"
    echo "       $r1"
    exit 1
fi

# Check R2
if [[ ! -f "$r2" ]]; then
    echo "ERROR: R2 file does not exist:"
    echo "       $r2"
    exit 1
fi

echo "========================================"
echo "Kraken2 job"
echo "Sample:   $name"
echo "R1:       $r1"
echo "R2:       $r2"
echo "Database: $DB"
echo "CPUs:     $SLURM_CPUS_PER_TASK"
echo "========================================"

kraken2 \
    --db "$DB" \
    --paired "$r1" "$r2" \
    --confidence 0.1 \
    --classified-out "$OUT_DIR/classified-${name}.R#.fq" \
    --unclassified-out "$OUT_DIR/unclassified-${name}.R#.fq" \
    --output "$OUT_DIR/kraken_output_${name}.txt" \
    --report "$OUT_DIR/kreport_${name}.txt" \
    --threads "$SLURM_CPUS_PER_TASK"

echo "========================================"
echo "Finished: $name"
echo "========================================"
