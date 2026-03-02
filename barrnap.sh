#!/bin/bash
#SBATCH --time=7-23:59:59
#SBATCH --partition=k2-lowpri
#SBATCH --mem=50G
#SBATCH --error=barrnap-%A-%a.err
#SBATCH --job-name=barrnap

source activate barrnap

for i in *fa; do barrnap --kingdom bac --outseq ${i%.fasta}.barrnap.gff $i; done
