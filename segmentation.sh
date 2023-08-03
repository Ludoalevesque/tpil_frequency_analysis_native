#!/bin/bash

sub='02'
root_dir="/mnt/d/NeuroImaging"
output_dir="${root_dir}/frequency_analysis/sub-${sub}"
T1_brain="${output_dir}/sub-02_T1_brainBrainExtractionBrain.nii.gz"
ROI_path="${output_dir}/fsl_first_outputs"

if [ ! -d "$ROI_path" ]; then
  mkdir -p "$ROI_path"
fi


run_first_all -i $T1_brain -o "${ROI_path}/sub-${sub}" -b
