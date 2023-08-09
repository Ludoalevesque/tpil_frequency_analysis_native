#!/bin/bash
#SBATCH --time=10:00:00
#SBATCH --job-name=segmentation
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=10G
#SBATCH --mail-user=ludo.a.levesque@gmail.com
#SBATCH --mail-type=FAIL,END
#SBATCH --ntasks=47
#SBATCH --array=1-47
#SBATCH --output="outputs/slurm-%A_%a.out"


root_dir="/home/ludoal/scratch/freq_analysis_data"
sessions="V1"
subjectIDs_file="${root_dir}/${sessions}/subjectIDs.txt"
template_dir="/home/ludoal/scratch/Templates"


sub=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${subjectIDs_file}")


# Segmentation (change the segmentation script for other methods than fsl first)
cmd="bash segmentation_first_all.sh \
    -d "${root_dir}" \
    -s "${sessions}" \
    -sub "${sub}" \
    -t "${template_dir}" "

echo "$cmd"
eval "$cmd"

