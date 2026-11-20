#!/bin/bash
#SBATCH --time=00:19:59
#SBATCH --partition=k2-sandbox,k2-bioinf
#SBATCH --job-name=dbCAN_holor
#SBATCH --mem=20G
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
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

sed -n "${START},${END}p" missing_eggnog.txt | while read -r i; do

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
