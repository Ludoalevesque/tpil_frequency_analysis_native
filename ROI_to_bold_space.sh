#!/bin/bash

export sesion="V1"
export sub='02'
export root_dir="/mnt/d/NeuroImaging"
export output_dir="${root_dir}/frequency_analysis/sub-${sub}"
export T1_brain="${output_dir}/sub-02_T1_brainBrainExtractionBrain.nii.gz"
export BOLD_ref="${output_dir}/sub-02_task-rest_boldref.nii.gz"
# change the path to something loopable
export ROI_file="${root_dir}/23-07-11_fsl_first/control/sub-pl002_ses-v1/Subcortex_segmentation/sub-pl002_ses-v1_all_fast_firstseg.nii.gz"


#Starting docker :
sudo service docker start


## Register T1 to BOLD

# with docker and ants container 
docker run --rm \
    -v "${root_dir}:${root_dir}" \
    antsx/ants \
    bash antsRegistrationSyNQuick.sh -d 3 -f "$BOLD_ref" -m "$T1_brain" -o "${output_dir}/sub-${sub}_T1_space-BOLD_"



# Apply the transformation to the ROI file using antsApplyTransforms
docker run --rm \
    -v "${root_dir}:${root_dir}" \
    antsx/ants \
    antsApplyTransforms -d 3 \
    -i "$ROI_file" \
    -r "$BOLD_ref" \
    -o "${output_dir}/sub-${sub}_ROIs_space-BOLD.nii.gz" \
    -t "${output_dir}/sub-${sub}_T1_space-BOLD_0GenericAffine.mat" \
    -t "${output_dir}/sub-${sub}_T1_space-BOLD_1Warp.nii.gz" \
    -n GenericLabel


echo "Transformation of ROI file complete."
