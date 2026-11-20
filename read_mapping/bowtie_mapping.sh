#!/bin/bash
#SBATCH --job-name=align_rumen
#SBATCH --partition=k2-medpri,k2-lowpri,k2-himem
#SBATCH --time=23:00:00
#SBATCH --cpus-per-task=24
#SBATCH --mem=350G
#SBATCH --output=align_rumen_%j.log
#SBATCH --error=align_rumen_%j.log
#SBATCH --mail-user=l.dillon@qub.ac.uk
#SBATCH --mail-type=BEGIN,FAIL,END

source activate /mnt/scratch2/igfs-anaconda/conda-envs/bowtie2_v2.5.5

sample=$1
r1=$2
r2=$3

echo "Sample: $sample"
echo "R1: $r1"
echo "R2: $r2"

index="/mnt/scratch2/igfs-databases/HoloR_DB_bowtie_index/rumen_index"
reads="/mnt/scratch2/users/40309916/Holoruminant/Bowtie2/mapping_reads"
out="/mnt/scratch2/users/40309916/Holoruminant/Bowtie2/results"
tmp="/mnt/scratch2/users/40309916/Holoruminant/Bowtie2/tmp"

mkdir -p "$out" "$tmp" logs

bowtie2 -x "$index" \
    -1 "$reads/$r1" \
    -2 "$reads/$r2" \
    --threads "${SLURM_CPUS_PER_TASK:-16}" \
    --very-sensitive \
    --local \
    2> "$out/${sample}_local_summary.txt" \
    | samtools sort \
        -@ 4 \
        -m 4G \
        -T "$tmp/${sample}_sort" \
        -o "$out/${sample}_local.sorted.bam" -

samtools index "$out/${sample}_local.sorted.bam"

echo "Finished: $sample"
