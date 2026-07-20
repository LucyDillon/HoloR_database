#!/bin/sh
#SBATCH --time=2:59:00
#SBATCH --partition=k2-hipri,k2-bioinf
#SBATCH --mem=50G
#SBATCH --mail-user=l.dillon@qub.ac.uk
#SBATCH --mail-type=END,BEGIN,FAIL
#SBATCH --error=blast_db-%A-%a.err
#SBATCH --job-name=blast_db

module load apps/ncbiblast/2.15.0/gcc-14.1.0

makeblastdb \
    -in all_for_70th-build.fas \
    -dbtype nucl \
    -out all_for_70th-build_db \
    -parse_seqids
