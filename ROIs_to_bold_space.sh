#!/bin/bash

# this does the registration of the segmentation file to bold space 

# Help message function
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -h, --help                      Show this help message and exit"
    echo "  -d, --root-dir          DIR     Root directory (required)"
    echo "  -s, --session           NAME    Session name (required)"
    echo "  -sub, --subject         ID      Subject ID (required)"
    echo "  -r, --segmentation_file FILE    File containing the regions(required)"
    exit 1
}

# Initialize variables
root_dir=""
session=""
sub=""
segmentation_file=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -d|--root-dir)
            root_dir="$2"
            shift 2
            ;;
        -s|--session)
            session="$2"
            shift 2
            ;;
        -sub|--subject)
            sub="$2"
            shift 2
            ;;
        -r|--segmentation_file)
            segmentation_file="$2"
            shift 2
            ;;
        *)
            echo "Invalid option: $1"
            usage
            ;;
    esac
done

# Check for required arguments
if [ -z "$root_dir" ] || [ -z "$session" ] || [ -z "$sub" ] || [ -z "$segmentation_file" ]; then
    echo "Error: Missing required arguments."
    usage
fi


# Assigning main variables
output_dir="${root_dir}/${session}/sub-${sub}/frequency_analysis_outputs"
func_dir="${root_dir}/${session}/sub-${sub}/func"


# 3- Apply Head Motion Correction on bold

input_fmri_file="${func_dir}/sub-${sub}_task-rest_bold.nii.gz"
bold_out_dir="${output_dir}/BOLD"
HMC_bold="${bold_out_dir}/sub-${sub}_task-rest_bold_HMC.nii.gz"

if [ ! -d "${bold_out_dir}" ]; then
    mkdir -p "${bold_out_dir}"
fi

module load StdEnv/2020  gcc/9.3.0  cuda/11.0 fsl/6.0.4

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
T1_brain="${output_dir}/BrainExtraction/sub-${sub}_T1_BrainExtractionBrain.nii.gz"
registration_dir="${output_dir}/Registration"

if [ ! -d "${registration_dir}" ]; then
    mkdir -p "${registration_dir}"
fi

module load StdEnv/2020  gcc/9.3.0 ants/2.4.4

antsRegistrationSyNQuick.sh -d 3 -f "${bold_ref_file}" -m "${T1_brain}" -o "${registration_dir}/sub-${sub}_T1_space-BOLD_"

echo "Registration of T1 to Bold complete."


# 6- Register the segmentation to BOLD space
segmentation_dir="$(dirname "$segmentation_file")"
seg_in_bold_space="${segmentation_dir}/sub-${sub}_ROIs_space-BOLD.nii.gz"

antsApplyTransforms -d 3 \
-i "${segmentation_file}" \
-r "${bold_ref_file}" \
-o "${seg_in_bold_space}" \
-t "${registration_dir}/sub-${sub}_T1_space-BOLD_0GenericAffine.mat" \
-t "${registration_dir}/sub-${sub}_T1_space-BOLD_1Warp.nii.gz" \
-n GenericLabel

echo "Transformation of ROI file complete."


