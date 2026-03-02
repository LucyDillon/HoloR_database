bakta:
#!/bin/bash
#SBATCH --time=7-23:59:59
#SBATCH --partition=k2-lowpri
#SBATCH --mem=100G
#SBATCH --ntasks=16
#SBATCH --nodes=1
#SBATCH --error=Bakta_Dasy-%A-%a.err
#SBATCH --job-name=Bakta_Dasy
#SBATCH --array=1-100%1000
echo $SLURM_ARRAY_TASK_ID
source activate /mnt/scratch2/igfs-anaconda/conda-envs/bakta_1.8.2 # this is the version of bakta

for i in `cat MAG_list.txt | sed -n $(expr $(expr ${SLURM_ARRAY_TASK_ID} \* 100) - 99),$(expr ${SLURM_ARRAY_TASK_ID} \* 100)p`; 
	do bakta --db /mnt/scratch2/igfs-databases/Bakta/bakta_1.8.1/db --output Bakta_results $i --force --threads 16; 
done
