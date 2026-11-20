#!/bin/sh
#SBATCH --time=23:59:00
#SBATCH --partition=k2-medpri,k2-bioinf
#SBATCH --mem=100G
#SBATCH --mail-user=l.dillon@qub.ac.uk
#SBATCH --mail-type=END,BEGIN,FAIL
#SBATCH --error=blast_db-%A-%a.err
#SBATCH --job-name=blast_db

module load apps/ncbiblast/2.15.0/gcc-14.1.0

makeblastdb \
    -in non_redundant_holor_proteins.faa \
    -dbtype prot \
    -out holoR_nonredundant_db \
    -title "holoR_nonredundant_db"
