#!/bin/sh
#SBATCH --time=7-23:59:59
#SBATCH --partition=k2-lowpri,k2-bioinf
#SBATCH --mem=150G
#SBATCH --cpus-per-task=8
#SBATCH --mail-user=l.dillon@qub.ac.uk
#SBATCH --mail-type=END,BEGIN,FAIL
#SBATCH --error=cluster_proteins-%A-%a.err
#SBATCH --job-name=cluster_proteins

source activate /mnt/scratch2/igfs-anaconda/conda-envs/cd-hit_4.8.1

cd-hit -i dereplicated_results/bakta/ALL_protein_files/all_holor_proteins.faa -o non_redundant_holor_proteins.faa  -c 1.00 -n 5 -M 150000 -T 8
