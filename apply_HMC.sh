#!/bin/bash

input_fmri_file="/mnt/d/NeuroImaging/V1_BIDS/sub-02/func/sub-02_task-rest_bold.nii.gz"
output_fmri_file="/mnt/d/NeuroImaging/frequency_analysis/sub-02/sub-02_task-rest_bold_HMC.nii.gz"


# Apply head motion correction to fMRI 4D image
mcflirt -in "$input_fmri_file" -out "$output_fmri_file" -mats -plots
echo "Head motion correction applied and saved."

