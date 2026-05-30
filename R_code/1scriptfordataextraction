library(Cardinal)
library(readxl)
## Load the imzML file into Cardinal.
## This file contains the MSI spectra and pixel coordinate information.
msi_data <- readMSIData("D:/2025/Jan/Combined/combind1.imzML")
## Performed TIC normalization and frequency-based peak filtering.
msi_data2 <- msi_data |>
  normalize(method="tic")|>
  peakProcess(filterFreq = 0.01)
## Loaded ROI pixel coordinates and extracted matching trichome pixels.
file_path <- "C:/Users/nasum/Documents/MATLAB/2025/Feburary/Combined1/New Selection/classified_R6_pixel.xlsx"
Positionfile <- read_excel(file_path)
## Visualized the extracted trichome pixels using m/z 431.0988.
Trichomes <- subsetPixels(msi_data2, coord = list(Positionfile$X, Positionfile$Y))
image(Trichomes, mz=431.0988)
## Extract ROI-matched trichome pixels and visualize a representative ion image.
cardinal_coords <- as.data.frame(coord(msi_data2))
mROI_filtered <- Positionfile[Positionfile$X %in% cardinal_coords$x & Positionfile$Y %in% cardinal_coords$y, ]
## we matched ROI coordinates to Cardinal scan IDs and assigned each pixel to its corresponding Region.
trichomes_coords <- as.data.frame(coord(Trichomes))
trichomes_coords$scan <- rownames(trichomes_coords) 
colnames(trichomes_coords) <- c("X", "Y", "scan")  
mROI_filtered_df <- as.data.frame(mROI_filtered)
mROI_filtered_df$scan <- trichomes_coords$scan[match(paste(mROI_filtered_df$X, mROI_filtered_df$Y),
                                                     paste(trichomes_coords$X, trichomes_coords$Y))]
pData(Trichomes)$run <- as.factor(mROI_filtered_df$Region[match(rownames(pData(Trichomes)), mROI_filtered_df$scan)])
table(pData(Trichomes)$run)
image(Trichomes, "run")
## Summed ion intensities for each m/z feature within each Region/trichome
## and generated a Region-level ion abundance matrix.
common_mz <- featureData(Trichomes)$mz
all_runs_df <- data.frame(mz = common_mz)
for (run_id in unique(pData(Trichomes)$run)) {
  run_subset <- subsetPixels(Trichomes, pData(Trichomes)$run == run_id)
  run_sum <- summarizeFeatures(run_subset, stat = "sum")
  run_sum_matrix <- as.matrix(intensity(run_sum))
  run_sum_df <- data.frame(mz = featureData(run_sum)$mz, 
                           intensity = rowSums(run_sum_matrix))
  all_runs_df[[paste0("run_", run_id)]] <- run_sum_df$intensity
}
write.csv(all_runs_df, "C:/Users/nasum/Documents/MATLAB/2025/Feburary/Combined1/all_runs_summed.csv", 
          row.names=FALSE)

print(head(all_runs_df, 10)) 



