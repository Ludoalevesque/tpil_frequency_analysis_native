#!/bin/bash
#SBATCH --time=10:00:00
#SBATCH --job-name=ROI_to_BOLD
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
sub=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${subjectIDs_file}")
output_dir="${root_dir}/${session}/sub-${sub}/frequency_analysis_outputs"

segmentation_dir="${output_dir}/Segmentation/first_all"
segmentation_file="${segmentation_dir}/sub-${sub}_all_fast_firstseg.nii.gz"

cmd="bash ROIs_to_bold_space.sh \
    -d "${root_dir}" \
    -s "${sessions}" \
    -sub "${sub}" \
    -r "${segmentation_file}" "

echo " command : $cmd "
eval "$cmd"

#cmd="bash /home/ludoal/scratch/tpil_frequency_analysis_native/ROIs_to_bold_space.sh -d "/home/ludoal/scratch/freq_analysis_data" -s "V1" -sub "02" -r "/home/ludoal/scratch/freq_analysis_data/V1/sub-02/frequency_analysis_outputs/Segmentation/first_all/sub-02_all_fast_firstseg.nii.gz" "

