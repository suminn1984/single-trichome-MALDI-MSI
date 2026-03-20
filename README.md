# Single-Trichome MALDI-MSI Registration Workflow

A MATLAB-based step-by-step workflow for spatial registration and the extraction of the pixels of isolated trichomes of Arabidopsis thaliana in MALDI-MS image. 

## Overview
This repository contains MATLAB scripts developed for spatial registration of optical image and MALDI-MS image. 
The workflow utilizes pre- and post-MALDI optical images, ROI coordinate transformation, laser-ablation-mark-based registration, and MALDI-MS ion image alignment. The scripts are organized as sequential steps and should be executed in numerical order.


## Main functions
1. Extraction of trichome coordinates from pre-MALDI optical images
2. Automatic trichome segmentation and manual point-by-point ROI selection
3. Registration of trichome ROIs from pre-MALDI to post-MALDI optical images
4. Alignment of the MS acquisition area using laser-ablation marks as fiducial markers
5. The extraction of trichome-associated pixels that are used for data processing. 


## Workflow Scripts

The scripts in the `code/` folder should be run sequentially in numerical order.  
Each script performs one stage of the workflow, and the output from one step is used as the input for the next step.

1. `1. mROI_paper.m`  
   Selects trichome ROIs from the pre-MALDI optical image using automatic segmentation or manual polygon selection, and exports ROI coordinates.

2. `2. Affine_transform.m`  
   Performs affine transformation to register pre-MALDI and post-MALDI optical images using user-defined landmarks.

3. `3. plotTransformedCoordinatesOnImage.m`  
   Plots transformed ROI coordinates on the registered optical image for visual inspection.

4. `4. Fourth_imageandmROI.m`  
   Uses laser-ablation marks and transformed ROIs to define the acquisition region and refine coordinate alignment.

5. `5. javaadding (Reading imzML files in MATLAB).m`  
   Adds the required Java-based imzML parser and prepares MATLAB for reading imzML files.

6. `6. MS_imagegen.m`  
   Generates MALDI-MS ion images from imzML data for selected m/z values.

7. `7. AligneOpticalimagetoMSimage.m`  
   Aligns the optical image to the MALDI-MS image and projects ROI coordinates into the MS image coordinate space for final pixel-level extraction.

## Contents
- `code/`  
  MATLAB scripts for ROI selection, image registration, coordinate transformation, MS image generation, 
  and optical-to-MS alignment.

- `example_data/`  
  Example input files for testing the workflow.

## Requirements
- MATLAB R2024b
- Java-based imzML parser (`jimzMLConverter-2.1.1` or compatible)
- Pre-MALDI optical image (Pre-MALDI optical image of isolated trichomes)
- Post-MALDI optical image (Laser-ablation marks used as fiducial markers)
- ROI coordinate files (`.csv`)
- imzML data file - imzML files for ion image generation


## System environment
Windows 11 Home  
a laptop equipped with an Intel® Core™ i7-14650HX CPU (2.20 GHz), 
32 GB RAM, 
NVIDIA GeForce RTX 4060 GPU.

## Usage
1. Load the pre-MALDI optical image
2. Detect trichomes automatically or define ROIs manually
3. Load the post-MALDI optical image
4. Select corresponding landmarks and perform affine transformation
5. Project trichome ROIs onto the post-MALDI optical image
6. Define the MS acquisition area using laser-ablation marks
7. Align the optical image with the MALDI-MS ion image
8. Extract trichome-associated pixels and ion intensities
9. Generate ion images and downstream analysis outputs
