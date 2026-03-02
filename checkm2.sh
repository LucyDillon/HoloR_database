#!/bin/sh
#SBATCH --time=7-23:59:59
#SBATCH --partition=k2-lowpri
#SBATCH --mem=100GB
#SBATCH --ntasks=16
#SBATCH --job-name=CM_Hun
#SBATCH --error=CM_Hungate-%A-%a.err

source activate checkm2

checkm2 predict -t 16 -x fasta --input genomes/ --output-directory checkm-results/ > Hungate.checkm.log --force
