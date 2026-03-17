# Single-Trichome MALDI-MSI Registration Workflow

MATLAB-based workflow for spatial registration of isolated Arabidopsis trichomes in single-trichome MALDI-MSI analysis.

## Overview
This repository contains MATLAB scripts developed for single-trichome MALDI-MSI data processing and spatial registration. 

## Main functions
1. Extraction of trichome coordinates from pre-MALDI optical images
2. Automatic trichome segmentation and manual point-by-point ROI selection
3. Registration of trichome ROIs from pre-MALDI to post-MALDI optical images
4. Alignment of the MS acquisition area using laser-ablation marks as fiducial markers
5. Pixel-level extraction of trichome-associated ion intensities
6. Generation of ion images and downstream analysis outputs

## Contents
- `code/`: MATLAB scripts used for spatial registration and data analysis
- `example_data/`: example input files for the registration workflow

## Requirements
- MATLAB R2024b
- imzML parser (`jimzMLConverter-2.1.1`)
- ROI coordinate files (`.csv`)
- Pre- and post-MALDI optical images
- MALDI-MS ion image data

## System environment
Windows 11 Home (64-bit; version 25H2, OS build 26200.8037) running on a laptop equipped with an Intel® Core™ i7-14650HX CPU (2.20 GHz), 32 GB RAM, and an NVIDIA GeForce RTX 4060 GPU.

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
