#!/bin/bash
#SBATCH --time=7-23:59:59
#SBATCH --partition=k2-lowpri,k2-bioinf
#SBATCH --mail-user=ldillon05@qub.ac.uk
#SBATCH --mem=50G
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --error=barrnap_mising-%A-%a.err
#SBATCH --job-name=barrnap_missing

source activate /mnt/scratch2/igfs-anaconda/conda-envs/barrnap_0.9


for i in $(cat genomes_skder_final_without_extension.txt); do
    bac_out="dereplicated_results/barrnap/${i}.16S.fa"
    arc_out="dereplicated_results/barrnap/${i}.arc.16S.fa"
    if [ ! -s "$bac_out" ]; then

        barrnap --kingdom bac --outseq "$bac_out" fasta_files_for_drep/${i}.fasta

    fi

    if [ ! -s "$arc_out" ]; then

        barrnap --kingdom arc --outseq "$arc_out" fasta_files_for_drep/${i}.fasta

    fi

done
