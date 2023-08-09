#!/bin/bash
#SBATCH --time=10:00:00
#SBATCH --job-name=freq_analysis_preproc
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=10G
#SBATCH --mail-user=ludo.a.levesque@gmail.com
#SBATCH --mail-type=FAIL,END


root_dir="/home/ludoal/scratch/freq_analysis_data"
sessions=("V1")  # List of sessions
subjects=("02")  # List of subjects
template_dir="/home/ludoal/scratch/Templates"

module load StdEnv/2020  gcc/9.3.0 ants/2.4.4

for session in "${sessions[@]}"; do
  for sub in "${subjects[@]}"; do
    output_dir="${root_dir}/${session}/sub-${sub}/frequency_analysis_outputs"
    anat_dir="${root_dir}/${session}/sub-${sub}/anat"
    func_dir="${root_dir}/${session}/sub-${sub}/func"


    start_time=$(date +"%Y-%m-%d %H:%M:%S")
    echo "Started processing subject sub-${sub} in session ${session} at ${start_time}"

    # Capture the start time in seconds since the epoch
    start_seconds=$(date +%s)

    # 1- Brain extraction on T1
    T1="${anat_dir}/sub-${sub}_T1w.nii.gz"
    template_with_skull="${template_dir}/MICCAI2012-Multi-Atlas-Challenge-Data/T_template0.nii.gz"
    brain_prob_mask="${template_dir}/MICCAI2012-Multi-Atlas-Challenge-Data/T_template0_BrainCerebellumProbabilityMask.nii.gz"
    brain_extract_mask="${template_dir}/MICCAI2012-Multi-Atlas-Challenge-Data/T_template0_BrainCerebellumRegistrationMask.nii.gz"
    brain_extract_prefix="${output_dir}/BrainExtraction/sub-${sub}_T1_"

    module load StdEnv/2020  gcc/9.3.0 ants/2.4.4

    antsBrainExtraction.sh -d 3 -a "${T1}" -e "${template_with_skull}" -m "${brain_prob_mask}" -f "${brain_extract_mask}" -o "${brain_extract_prefix}"

    echo "Brain extraction of T1 completed."


    # 2- Segment the brain extracted T1 subcortical structures

    T1_brain="${brain_extract_prefix}BrainExtractionBrain.nii.gz"
    segmentation_dir="${output_dir}/Segmentation"

    if [ ! -d "${segmentation_dir}" ]; then
      mkdir -p "${segmentation_dir}"
    fi

    module load StdEnv/2020  gcc/9.3.0  cuda/11.0 fsl/6.0.4
    run_first_all -i ${T1_brain} -o "${segmentation_dir}/sub-${sub}" -b
    echo "T1 segmentation done."



    # 3- Apply Head Motion Correction on bold

    input_fmri_file="${func_dir}/sub-${sub}_task-rest_bold.nii.gz"
    bold_out_dir="${output_dir}/BOLD"
    HMC_bold="${bold_out_dir}/sub-${sub}_task-rest_bold_HMC.nii.gz"

    if [ ! -d "${bold_out_dir}" ]; then
      mkdir -p "${bold_out_dir}"
    fi

    mcflirt -in "${input_fmri_file}" -out "${HMC_bold}" -mats -plots
    echo "Head motion correction applied and saved."


    # 4- Compute the bold ref to be used in T1 to bold registration

    bold_ref_file="${bold_out_dir}/sub-${sub}_task-rest_boldref.nii.gz"
    half_vol_file="half_vol_file.nii.gz"

    # Task 1: Get the volume at 0.5
    num_volumes=$(fslinfo "${HMC_bold}" | grep '^dim4' | awk '{print $2}')
    half_index=$((num_volumes / 2))
    fslroi "${HMC_bold}" "${half_vol_file}" "${half_index}" 1

    # Task 2: Apply brain extraction on the ref volume image
    bet "$half_vol_file" "$bold_ref_file"
    echo "Brain extraction applied and bold ref saved."

    # Removing temporary files
    rm "${half_vol_file}"
    echo "BOLD reference computed."


    # 5- Register T1 to Bold

    registration_dir="${output_dir}/Registration"
    if [ ! -d "${registration_dir}" ]; then
      mkdir -p "${registration_dir}"
    fi

    module load StdEnv/2020  gcc/9.3.0 ants/2.4.4

    antsRegistrationSyNQuick.sh -d 3 -f "${bold_ref_file}" -m "${T1_brain}" -o "${registration_dir}/sub-${sub}_T1_space-BOLD_"

    echo "Registration of T1 to Bold complete."


    # 6- Register the segmentation to BOLD space

    segmentation_file="${segmentation_dir}/sub-${sub}_all_fast_firstseg.nii.gz"
    seg_in_bold_space="${segmentation_dir}/sub-${sub}_ROIs_space-BOLD.nii.gz"

    antsApplyTransforms -d 3 \
    -i "${segmentation_file}" \
    -r "${bold_ref_file}" \
    -o "${seg_in_bold_space}" \
    -t "${registration_dir}/sub-${sub}_T1_space-BOLD_0GenericAffine.mat" \
    -t "${registration_dir}/sub-${sub}_T1_space-BOLD_1Warp.nii.gz" \
    -n GenericLabel

    echo "Transformation of ROI file complete."

    end_seconds=$(date +%s)
    elapsed_time=$((end_seconds - start_seconds))
    end_time=$(date +"%Y-%m-%d %H:%M:%S")
    echo "Finished processing subject sub-${sub} in session ${session} at ${end_time}"
    echo "Elapsed time: $(($elapsed_time / 3600))h $((($elapsed_time % 3600) / 60))m $(($elapsed_time % 60))s"

  done
done
