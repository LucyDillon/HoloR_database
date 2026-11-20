#!/bin/bash
#SBATCH --time=7-23:59:59
#SBATCH --partition=k2-lowpri,k2-bioinf
#SBATCH --mail-user=l.dillon@qub.ac.uk
#SBATCH --mem=50G
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --error=sourmash_sig-%A-%a.err
#SBATCH --job-name=sourmash_sig

source activate /mnt/scratch2/igfs-anaconda/conda-envs/sourmash_v4.9.4

while read -r genome; do
    base=$(basename "$genome")
    base="${base%.*}"

    if [[ -f "./${base}.sig" ]]; then
        echo "Skipping $genome"
        continue
    fi

    sourmash sketch dna "$genome" --output-dir ./
done < ../../skder_output_100/Dereplicated_Representative_Genomes/genomes_skder_final.txt
