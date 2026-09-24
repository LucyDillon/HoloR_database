#!/bin/bash
#SBATCH --job-name=build_rumen_index
#SBATCH --partition=k2-himem,k2-bioinf
#SBATCH --account=default
#SBATCH --time=3-00:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=800G
#SBATCH --output=build_rumen_index_%j.log
#SBATCH --error=build_rumen_index_%j.log

set -ueo pipefail

module load apps/anaconda3/2024.10/bin
source activate bowtie2

bac="$PROJECTFOLDER/custom_reference/mags/reduced_MAGS/renamed"
arc="$PROJECTFOLDER/custom_reference/mags/archaea/renamed"
cil="$PROJECTFOLDER/custom_reference/protozoa/450_RCGs.fasta/renamed"
fun="$PROJECTFOLDER/custom_reference/fungi/tagged/renamed"
cilsup="$PROJECTFOLDER/custom_reference/protozoa_supplement/Ecaudatum_MZG1/ncbi_dataset/data/GCA_002087855.3/renamed"

output="$PROJECTFOLDER/custom_reference/rumen_index"

combine="$output/rumen_combined.fasta.gz"

index="$output/rumen_index"

#combines all zipped mags using xargs 
echo "combining"
:> "$combine"
for directory in "$bac" "$arc" "$cil" "$fun" "$cilsup"; do
    find "$directory" -type f -name "*.gz" | xargs cat >> "$combine"

done

echo "combined file size : $(du -h "$combine" | cut -f1)"


echo "bowtie2-build started"

bowtie2-build --large-index  --threads "${SLURM_CPUS_PER_TASK:-16}" "$combine" "$index"

echo "build finished"