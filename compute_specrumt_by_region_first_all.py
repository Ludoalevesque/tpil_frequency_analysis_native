# -*- coding: utf-8 -*-
"""
Created on Fri Aug 4 12:11:36 2023

This script computes the power spectrum of time series data extracted from specific brain regions
extracted using fsl run_firsl_all. It utilizes the Welch method to calculate the power spectrum and 
can optionally plot and save the results.

Requirements:
- Python 3.x
- Required Python packages: numpy, nibabel, nilearn, matplotlib, scipy, pandas

Usage:
python compute_specrumt_by_region_first_all.py [options]

Options:
    --seg_file <path>: Path to the segmentation file (e.g., sub-02_ROIs_space-BOLD.nii.gz).
    --bold_file <path>: Path to the bold file (e.g., sub-02_task-rest_bold_HMC.nii.gz).
    --output_prefix <path>: Prefix for the output file names (default: "./").
    --plot: Include this flag to enable plotting of power spectra (default: disabled).
    --save: Include this flag to enable saving results to a CSV file (default: enabled).

Example:
python compute_specrumt_by_region_first_all.py --seg_file path/to/seg_file.nii.gz --bold_file path/to/bold_file.nii.gz --plot

"""

import argparse
import numpy as np
import nibabel as nib
from nilearn.maskers import NiftiMasker
import matplotlib.pyplot as plt
from scipy.signal import welch
import pandas as pd

def compute_power_spectrum(signal_array, fs, nperseg=None,window='hann', noverlap=None, **kwargs):
    """
    Compute the power spectrum of a signal using the Welch method.

    Parameters:
        signal_array (numpy.ndarray): The input signal array.
        fs (float, optional): The sampling frequency of the signal (inverse of the time interval). Default is 1.0.
        nperseg (int, optional): The length of each segment. Default is None (auto-detected).
        noverlap (int, optional): The number of points to overlap between segments. Default is None (auto-detected).
        nfft (int, optional): The number of points to compute the Fast Fourier Transform (FFT). Default is None (auto-detected).
        **kwargs: Additional arguments to be passed to `scipy.signal.welch`.

    Returns:
        frequencies (numpy.ndarray): The frequencies corresponding to the power spectrum.
        power_spectrum (numpy.ndarray): The power spectrum of the input signal array.
    """

    # Compute the power spectrum using the Welch method
    frequencies, power_spectrum = welch(signal_array, fs=fs, nperseg=nperseg, noverlap=noverlap, **kwargs)

    return frequencies, power_spectrum

def main(args):

    labels=['Left-Thalamus-Proper',
        'Left-Caudate',
        'Left-Putamen',
        'Left-Pallidum',
        'Brain-Stem',
        'Left-Hippocampus',
        'Left-Amygdala',
        'Left-Accumbens-area',
        'Right-Thalamus-Proper',
        'Right-Caudate',
        'Right-Putamen',
        'Right-Pallidum',
        'Right-Hippocampus',
        'Right-Amygdala',
        'Right-Accumbens-area']
    labels_short=['L_Thal',
              'L_Caud',
              'L_Puta',
              'L_Pall',
              'BrStem',
              'L_Hipp',
              'L_Amyg',
              'L_Accu',
              'R_Thal',
              'R_Caud',
              'R_Puta',
              'R_Pall',
              'R_Hipp',
              'R_Amyg',
              'R_Accu']
    labels_values=[10,11,12,13,16,17,18,26,49,50,51,52,53,54,58]
    
    seg_file = args.seg_file
    bold_file = args.bold_file
    output_prefix = args.output_prefix
    plot = args.plot
    save = not args.no_save  # Reverse the no_save flag for the save option
    
    TR = nib.load(bold_file).header['pixdim'][4]
    sampling_rate = 1 / TR
    
    power_spectra_data = {"Frequencies (Hz)": []}
    
    for region_index in range(len(labels)):
        
        label_val = labels_values[region_index]
        
        # Load parcellation image (output of run_first)
        parcellation_img = nib.load(seg_file)
        
        # Create a binary mask of the region
        mask_data = (parcellation_img.get_fdata() == label_val).astype('uint8')
        num_vox = np.count_nonzero(mask_data)
          
        if num_vox == 0 :
            print(labels_short[region_index], 'has no voxel')
            power_spectra_data[labels_short[region_index]] = []
            continue
        
        mask_img = nib.Nifti1Image(mask_data, affine=parcellation_img.affine, dtype='uint8')
        masker = NiftiMasker(mask_img=mask_img)
        
        # Extract the signals for voxels within the region
        time_series = masker.fit_transform(bold_file)
        
        # compute the spectrum for each voxels then average them together
        positive_frequencies, power_mtx = compute_power_spectrum(time_series.T, sampling_rate)
        mean_spectrum = np.mean(power_mtx, axis=0)
        
    
        
        # Store the mean_spectrum in the dictionary
        power_spectra_data[labels_short[region_index]] = mean_spectrum
        
            
        if plot:
            # Plot the power spectrum with log scale y-axis
            plt.figure(figsize=(10, 6))
            plt.semilogy(positive_frequencies, mean_spectrum, linewidth=2)
            plt.xlabel("Frequency (Hz)")
            plt.ylabel("Power")
            plt.title(f"Power Spectrum of {labels[region_index]}")
            plt.grid(True)
            plt.show()
    
            
    if save:
        
        import pandas as pd
        
        # create frequencies colum and fill empty regions with NaN
        power_spectra_data['Frequencies (Hz)'] = positive_frequencies
        
        for key, value in power_spectra_data.items():
            if type(value) == list:
                power_spectra_data[key] = np.full(len(positive_frequencies),np.nan)
            
        
        # Create a DataFrame from the power_spectra_data dictionary
        power_spectra_df = pd.DataFrame(power_spectra_data)
        
        # Save the DataFrame to a CSV file
        csv_filename = f"{output_prefix}_power_spectras.csv"
        power_spectra_df.to_csv(csv_filename, index=False)
        print(f"Power spectra data saved to '{csv_filename}'")

    

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Compute power spectra from brain regions.")
    
    parser.add_argument('--seg_file', type=str, required=True, help="Path to the segmentation file.")
    parser.add_argument('--bold_file', type=str, required=True, help="Path to the bold file.")
    parser.add_argument('--output_prefix', type=str, default="./", help="Output file prefix.")
    parser.add_argument('--plot', action='store_true', help="Enable plotting of power spectra.")
    parser.add_argument('--no_save', action='store_true', help="Disable saving results to CSV file.")
    
    args = parser.parse_args()
    main(args)
