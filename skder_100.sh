#!/bin/bash
#SBATCH --time=23:59:00
#SBATCH --partition=k2-medpri,k2-bioinf
#SBATCH --mem=200G
#SBATCH --cpus-per-task=16
#SBATCH --mail-user=l.dillon@qub.ac.uk
#SBATCH --mail-type=END,BEGIN,FAIL
#SBATCH --error=skder-%A-%a.err
#SBATCH --job-name=skder


source activate /mnt/scratch2/igfs-anaconda/conda-envs/skder_1.3.6

skder -g fasta_files_for_drep/ -o skder_output_100 -d greedy -l -c 16 -i 100.0
