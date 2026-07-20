#!/bin/bash
#SBATCH --time=14-23:59:59
#SBATCH --partition=k2-lowpri
#SBATCH --mail-user=ldillon05@qub.ac.uk
#SBATCH --mem=100G
#SBATCH --ntasks=24
#SBATCH --nodes=1
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --error=Bakta_holor-%A-%a.err
#SBATCH --job-name=Bakta_holor
#SBATCH --array=1-999%60
echo $SLURM_ARRAY_TASK_ID
source activate /mnt/scratch2/igfs-anaconda/conda-envs/bakta_1.11.0

for i in $(sed -n "$((SLURM_ARRAY_TASK_ID * 100 - 99)),$((SLURM_ARRAY_TASK_ID * 100))p" genomes_skder_final.txt); do

    base=$(basename "$i")
    base=${base%.*}   # remove file extension

    if [ -d "dereplicated_results/bakta/$base" ]; then
        echo "Skipping $i (output already exists)"
        continue
    fi

    bakta \
        --db /mnt/scratch2/igfs-databases/Bakta/bakta_1.11.0_db_6.0/db \
        --output "dereplicated_results/bakta/$base" \
        "fasta_files_for_drep/$i" \
        --force \
        --threads 24

done
