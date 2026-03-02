#!/bin/sh
#SBATCH --time=13-23:59:59
#SBATCH --partition=k2-lowpri
#SBATCH --mem=150GB
#SBATCH --ntasks=20
#SBATCH --job-name=gtdbtk
#SBATCH --error=gtdbtk-%A-%a.err

module load apps/anaconda3/2024.10/bin
source activate /mnt/scratch2/igfs-anaconda/conda-envs/gtdbtk-2.1.1

gtdbtk classify_wf --genome_dir bins/ --out_dir gtdbtk_results/ --extension fa --cpus 20  --skip_ani_screen
