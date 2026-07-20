#!/bin/sh
#SBATCH --time=23-23:59:59
#SBATCH --partition=k2-lowpri,k2-bioinf
#SBATCH --mem=100GB
#SBATCH --ntasks=20
#SBATCH --job-name=gtdbtk_all
#SBATCH --mail-user=l.dillon@qub.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --error=gtdbtk_all-%A-%a.err


source activate /mnt/scratch2/igfs-anaconda/conda-envs/gtdbtk-2.1.1

gtdbtk classify_wf --genome_dir skder_output_100/Dereplicated_Representative_Genomes --out_dir dereplicated_results/gtdbtk_results/ --extension fasta --cpus 20  --skip_ani_screen

