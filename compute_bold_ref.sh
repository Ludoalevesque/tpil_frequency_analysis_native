#!/bin/bash

HMC_fmri_file="/mnt/d/NeuroImaging/frequency_analysis/sub-02/sub-02_task-rest_bold_HMC.nii.gz"
output_bold_ref_file="/mnt/d/NeuroImaging/frequency_analysis/sub-02/sub-02_task-rest_boldref.nii.gz"
half_vol_file="half_vol_file.nii.gz"


# Task 1: Get the volume at 0.5
num_volumes=$(fslinfo "$HMC_fmri_file" | grep '^dim4' | awk '{print $2}')
half_index=$((num_volumes / 2))
fslroi "$HMC_fmri_file" "$half_vol_file" "$half_index" 1

# Task 2: Apply brain extraction on the ref volume image
bet "$half_vol_file" "$output_bold_ref_file"
echo "Brain extraction applied and bold ref saved."

# Removing temporary files
rm "$half_vol_file"
