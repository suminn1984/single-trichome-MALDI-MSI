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

The scripts in the `code/` folder should be executed sequentially in numerical order.  
Each script performs one stage of the workflow, and the output from one step is used as the input for the next step.

`1. mROI_selection.m`  
   Selects trichome ROIs from the pre-MALDI optical image using either manual polygon selection or automatic selection of mROI => saved csv file => region1

`2. affine_transform_pre_to_post.m`  
   Performs affine transformation to register the pre-MALDI optical image to the post-MALDI optical image using 5 landmark points. => saved scv file => region2

`3. overlay_transformed_mROI_on_post_image.m`  
   Displays the transformed mROI coordinates overlaid on the post-MALDI optical image for visual inspection of the registration result. => saved scv file => region3

`4. register_laser_marks_and_mROI.m`  
   Uses laser-ablation marks in post-MALDI optical image and transformed mROI coordinates to define and refine the acquisition region for downstream alignment. => saved scv file and optical image => region4 and R4 image file. 

`5. setup_imzML_java_parser.m`  
   Adds and initializes the Java-based imzML parser required for reading imzML files in MATLAB.

`6. generate_MS_image_from_imzML.m`  
   Generates MALDI-MS ion images from imzML data for selected m/z values.

`7. align_optical_to_MS_image.m`  
   Aligns the optical image to the MALDI-MS image and projects mROI coordinates into the MS image space for final pixel-level extraction.

   
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
The workflow was developed and tested in MATLAB R2024b on Windows 11.  
Reading imzML files in MATLAB requires a Java-based imzML parser 
(e.g., `jimzMLConverter-2.1.1` or a compatible version).

## Usage
The scripts in the `code/` folder should be executed sequentially in numerical order. The output from one step is used as the input for the next step.
1. Load the pre-MALDI optical image
2. Detect trichomes automatically or define ROIs manually
3. Load the post-MALDI optical image
4. Select corresponding landmarks and perform affine transformation
5. Project trichome ROIs onto the post-MALDI optical image
6. Define the MS acquisition area using laser-ablation marks
7. Align the optical image with the MALDI-MS ion image
8. Extract trichome-associated pixels and ion intensities
9. Generate ion images and downstream analysis outputs
