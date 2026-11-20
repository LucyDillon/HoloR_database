#!/bin/bash
#SBATCH --time=6-23:59:59
#SBATCH --partition=k2-lowpri
#SBATCH --job-name=eggnog
#SBATCH	--mem=150G
#SBATCH --ntasks=32
#SBATCH --error=eggnog-%A-%a.err
#SBATCH --array=1-100%1000

source activate /mnt/scratch2/igfs-anaconda/conda-envs/eggnog/
module add diamond/0.9

echo $SLURM_ARRAY_TASK_ID
echo $SLURM_JOB_ID

for file_list in `ls faa_file_p1/*.faa | sed -n $(expr $(expr ${SLURM_ARRAY_TASK_ID} \* 100) - 99),$(expr ${SLURM_ARRAY_TASK_ID} \* 100)p`;
do emapper.py --data_dir /mnt/scratch2/igfs-anaconda/conda-envs/eggnog/lib/python3.9/site-packages/data -i $file_list --output ${file_list::-4}_eggnog -m diamond --cpu 32 --dbmem --dmnd_iterate no;
done
