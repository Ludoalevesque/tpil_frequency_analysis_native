#!/bin/bash

# Set environment variables
export sub='02'
export root_dir="/mnt/d/NeuroImaging"
export T1="${root_dir}/V1_BIDS/sub-${sub}/anat/sub-${sub}_T1w.nii.gz"
export template_with_skull="${root_dir}/Templates/MICCAI2012-Multi-Atlas-Challenge-Data/T_template0.nii.gz"
export brain_prob_mask="${root_dir}/Templates/MICCAI2012-Multi-Atlas-Challenge-Data/T_template0_BrainCerebellumProbabilityMask.nii.gz"
export brain_extract_mask="${root_dir}/Templates/MICCAI2012-Multi-Atlas-Challenge-Data/T_template0_BrainCerebellumRegistrationMask.nii.gz"
export output_dir="${root_dir}/frequency_analysis/sub-${sub}"

# Start the container without passing variables individually
container_id=$(docker run --rm \
    -v "${root_dir}:${root_dir}" \
    antsx/ants \
    bash antsBrainExtraction.sh -d 3 -a "$T1" -e "$template_with_skull" -m "$brain_prob_mask" -f "$brain_extract_mask" -o "${output_dir}/sub-${sub}_T1_brain")



# Stop and remove the container (optional)
docker container stop $container_id
