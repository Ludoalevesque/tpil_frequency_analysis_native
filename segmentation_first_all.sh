#!/bin/bash

# Help message function
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -h, --help           Show this help message and exit"
    echo "  -d, --root-dir DIR   Root directory (required)"
    echo "  -s, --session NAME   Session name (required)"
    echo "  -sub, --subject ID   Subject ID (required)"
    echo "  -t, --template-dir DIR Template directory (required)"
    exit 1
}

# Initialize variables
root_dir=""
session=""
sub=""
template_dir=""

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
        -t|--template-dir)
            template_dir="$2"
            shift 2
            ;;
        *)
            echo "Invalid option: $1"
            usage
            ;;
    esac
done

# Check for required arguments
if [ -z "$root_dir" ] || [ -z "$session" ] || [ -z "$sub" ] || [ -z "$template_dir" ]; then
    echo "Error: Missing required arguments."
    usage
fi

# Assigning main variables
output_dir="${root_dir}/${session}/sub-${sub}/frequency_analysis_outputs"
anat_dir="${root_dir}/${session}/sub-${sub}/anat"
func_dir="${root_dir}/${session}/sub-${sub}/func"


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
segmentation_dir="${output_dir}/Segmentation/first_all/"

if [ ! -d "${segmentation_dir}" ]; then
  mkdir -p "${segmentation_dir}"
fi

module load StdEnv/2020  gcc/9.3.0  cuda/11.0 fsl/6.0.4
run_first_all -i ${T1_brain} -o "${segmentation_dir}/sub-${sub}" -b
echo "T1 segmentation done."
