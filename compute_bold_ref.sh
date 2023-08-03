#!/bin/bash

input_fmri_file="/mnt/d/NeuroImaging/V1_BIDS/sub-02/func/sub-02_task-rest_bold.nii.gz"
output_fmri_file="/mnt/d/NeuroImaging/frequency_analysis/sub-02/sub-02_task-rest_bold_HMC.nii.gz"
output_bold_ref_file="/mnt/d/NeuroImaging/frequency_analysis/sub-02/sub-02_task-rest_boldref.nii.gz"
half_vol_file="half_vol_file.nii.gz"

# Task 1: Apply head motion correction to fMRI 4D image
mcflirt -in "$input_fmri_file" -out "$output_fmri_file" -mats -plots
echo "Head motion correction applied and saved."

# Task 2: Get the volume at 0.5
num_volumes=$(fslinfo "$output_fmri_file" | grep '^dim4' | awk '{print $2}')
half_index=$((num_volumes / 2))
fslroi "$output_fmri_file" "$half_vol_file" "$half_index" 1

# Task 3: Apply brain extraction on the ref volume image
bet "$half_vol_file" "$output_bold_ref_file"
echo "Brain extraction applied and bold ref saved."

# Removing temporary files
rm "$half_vol_file"
