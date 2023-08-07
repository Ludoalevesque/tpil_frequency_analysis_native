#!/bin/bash


export root_dir="/mnt/d/NeuroImaging/frequency_analysis"
export sesion="V1"
export sub='02'
export output_dir="${root_dir}/${sesion}/sub-${sub}/frequency_analysis_outputs"
export template_dir="${root_dir}/Templates"
export anat_dir="${root_dir}/${sesion}/sub-${sub}/anat"
export func_dir="${root_dir}/${sesion}/sub-${sub}/func"

# #Starting docker :
# sudo service docker start

# 1- Brain extraction on T1
export T1="${anat_dir}/sub-${sub}_T1w.nii.gz"
export template_with_skull="${template_dir}/MICCAI2012-Multi-Atlas-Challenge-Data/T_template0.nii.gz"
export brain_prob_mask="${template_dir}/MICCAI2012-Multi-Atlas-Challenge-Data/T_template0_BrainCerebellumProbabilityMask.nii.gz"
export brain_extract_mask="${template_dir}/MICCAI2012-Multi-Atlas-Challenge-Data/T_template0_BrainCerebellumRegistrationMask.nii.gz"
export brain_extract_prefix="${output_dir}/BrainExtraction/sub-${sub}_T1"

# Start the container
docker run --rm \
    -v "${root_dir}:${root_dir}" \
    antsx/ants \
    bash antsBrainExtraction.sh -d 3 -a "$T1" -e "$template_with_skull" -m "$brain_prob_mask" -f "$brain_extract_mask" -o "${brain_extract_prefix}"



# 2- Segment the brain extracted T1 subcortical structures

export T1_brain="${brain_extract_prefix}_BrainExtractionBrain.nii.gz"
export segmentation_dir="${output_dir}/Segmentation"

if [ ! -d "$segmentation_dir" ]; then
  mkdir -p "$segmentation_dir"
fi

run_first_all -i $T1_brain -o "${segmentation_dir}/sub-${sub}" -b
echo "T1 segmentation done."



# 3- Apply Head Motion Correction on bold

input_fmri_file="${func_dir}/sub-${sub}_task-rest_bold.nii.gz"
bold_out_dir="${output_dir}/BOLD"
HMC_bold="${bold_out_dir}/sub-${sub}_task-rest_bold_HMC.nii.gz"

if [ ! -d "$bold_out_dir" ]; then
  mkdir -p "$bold_out_dir"
fi

mcflirt -in "$input_fmri_file" -out "$HMC_bold" -mats -plots
echo "Head motion correction applied and saved."


# 4- Compute the bold ref to be used in T1 to bold registration

export bold_ref_file="${bold_out_dir}/sub-${sub}_task-rest_boldref.nii.gz"
half_vol_file="half_vol_file.nii.gz"

# Task 1: Get the volume at 0.5
num_volumes=$(fslinfo "$HMC_bold" | grep '^dim4' | awk '{print $2}')
half_index=$((num_volumes / 2))
fslroi "$HMC_bold" "$half_vol_file" "$half_index" 1

# Task 2: Apply brain extraction on the ref volume image
bet "$half_vol_file" "$bold_ref_file"
echo "Brain extraction applied and bold ref saved."

# Removing temporary files
rm "$half_vol_file"


# 5- Register T1 to Bold 

export registration_dir="${output_dir}/Registration"
if [ ! -d "$registration_dir" ]; then
  mkdir -p "$registration_dir"
fi


docker run --rm \
    -v "${root_dir}:${root_dir}" \
    antsx/ants \
    bash antsRegistrationSyNQuick.sh -d 3 -f "$bold_ref_file" -m "$T1_brain" -o "${registration_dir}/sub-${sub}_T1_space-BOLD_"


# 6- Register the segmentation to BOLD space

export segmentation_file="${segmentation_dir}/sub-${sub}_all_fast_firstseg.nii.gz"
export seg_in_bold_space="${segmentation_dir}/sub-${sub}_ROIs_space-BOLD.nii.gz"

docker run --rm \
    -v "${root_dir}:${root_dir}" \
    antsx/ants \
    antsApplyTransforms -d 3 \
    -i "$segmentation_file" \
    -r "$bold_ref_file" \
    -o "$seg_in_bold_space" \
    -t "${registration_dir}/sub-${sub}_T1_space-BOLD_0GenericAffine.mat" \
    -t "${registration_dir}/sub-${sub}_T1_space-BOLD_1Warp.nii.gz" \
    -n GenericLabel


echo "Transformation of ROI file complete."

