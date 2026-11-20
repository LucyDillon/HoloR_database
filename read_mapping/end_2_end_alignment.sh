#!/bin/bash
#SBATCH --job-name=align_rumen_
#SBATCH --partition=k2-bioinf,k2-medpri,k2-lowpri
#SBATCH --time=6:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=350G
#SBATCH --output=align_rumen_%j.log
#SBATCH --error=align_rumen_%j.log
#SBATCH --mail-user=jbarnard02@qub.ac.uk
#SBATCH --mail-type=BEGIN,FAIL,END


set -euo pipefail

#this conda env has samtools installed aswell ##
module load apps/anaconda3/2024.10/bin
source activate bowtie2

sample= ###replace with sample name###
index="$PROJECTFOLDER/custom_reference/rumen_index/rumen_index"
reads="$PROJECTFOLDER/results/preprocess/bowtie2/nonmaize"
out="$PROJECTFOLDER/results/align_rumen"
mkdir -p "$out" "$PROJECTFOLDER/tmp"

bowtie2 -x "$index" \
    -1 "$reads/${sample}.lib1_1.fq.gz" \
    -2 "$reads/${sample}.lib1_2.fq.gz" \
    --threads "${SLURM_CPUS_PER_TASK:-16}" \
    2> "$out/${sample}_alignment_summary.txt" \
    | samtools sort -@ 4 -m 4G -T "$PROJECTFOLDER/tmp/${sample}_sort" -o "$out/${sample}.sorted.bam" -

samtools index "$out/${sample}.sorted.bam"


