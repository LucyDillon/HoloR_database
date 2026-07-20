#!/bin/sh
#SBATCH --time=6-23:59:59
#SBATCH --partition=k2-lowpri,k2-bioinf
#SBATCH --mem=200GB
#SBATCH --ntasks=20
#SBATCH --job-name=CM
#SBATCH --mail-user=l.dillon@qub.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --error=CM-%A-%a.err

source activate /mnt/scratch2/igfs-anaconda/conda-envs/checkm2_1.1.0

checkm2 predict -t 20 -x fasta --database_path /mnt/scratch2/igfs-databases/CheckM2_database/uniref100.KO.1.dmnd --input skder_output_100/Dereplicated_Representative_Genomes/ --output-directory  dereplicated_results/checkm-results/ > checkm.log --force
