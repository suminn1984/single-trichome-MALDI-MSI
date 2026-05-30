library(Cardinal)

sample_id <- "fer_4_4"   # file name
imzml_path <- "D:/2025/May/May/feronia4_4.imzML"
roi_path   <- "D:/2025/May/May/SavingonlyPixelsinmROI_fer_4_4.csv"  # mROI path
mz_path    <- "D:/2025/May/May/mz_keep3_541.csv"   # feature list

out_dir <- "D:/2025/May/May/OUT"  # saving path
tol <- 0.001
units_mode <- "mz"  

## 

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

## Read the fixed 541 m/z feature list.
mz_list <- read.csv(mz_path, stringsAsFactors = FALSE)$mz
stopifnot(length(mz_list) == 541)

## Load the imzML MSI data.
msi <- readMSIData(imzml_path)
cat("Loaded:", sample_id, "class:", class(msi), "\n")
print(msi)

## Bin the MSI data to the fixed 541 m/z feature list using 0.001 Da tolerance.
msi_b <- bin(msi, ref = mz_list, tolerance = tol, units = units_mode, method = "sum")
cat("Binned features:", length(mz(msi_b)), "\n")

## Transposed the spectra matrix so that rows correspond to pixels and columns correspond to m/z features.
pix <- as.data.frame(pixelData(msi_b))
ab  <- as.matrix(t(spectra(msi_b)))   # dense: (Npixels x 541)
## Combined pixel metadata with the 541 m/z intensity matrix and renamed
## intensity columns using their corresponding m/z values.
msi_tbl <- cbind(pix, ab)
colnames(msi_tbl)[4:ncol(msi_tbl)] <- paste0("mz_", format(mz(msi_b), scientific = FALSE))

cat("Pixel table dim:", dim(msi_tbl), "\n")

## Assigned ROI Region labels to MSI pixels by x,y matching and retained only trichome-associated pixels.
roi <- read.csv(roi_path, stringsAsFactors = FALSE)
stopifnot(all(c("Region","X","Y") %in% names(roi)))

roi2 <- roi
names(roi2) <- c("Region","x","y")
roi2 <- unique(roi2)

msi_labeled <- merge(msi_tbl, roi2, by = c("x","y"), all.x = TRUE)

msi_trichome <- msi_labeled[!is.na(msi_labeled$Region), ]
cat("Trichome pixels:", nrow(msi_trichome), "\n")

## Exported the trichome-associated pixel table as a CSV file.
pix_out <- file.path(out_dir, paste0(sample_id, "_trichome_pixels_541mz.csv"))
write.csv(msi_trichome, pix_out, row.names = FALSE)
cat("Saved:", pix_out, "\n")

## Selected columns corresponding to the 541 m/z feature intensities.## Calculated pixel-level TIC from the 541 m/z features and normalized each m/z intensity by the corresponding pixel TIC.
feat_cols <- grep("^mz_", names(msi_trichome))
msi_trichome$TIC <- rowSums(msi_trichome[, feat_cols], na.rm = TRUE)
cat("TIC==0 pixels:", sum(msi_trichome$TIC == 0), "\n")

msi_norm <- msi_trichome
msi_norm[, feat_cols] <- msi_norm[, feat_cols] / msi_norm$TIC
msi_norm[msi_norm$TIC == 0, feat_cols] <- NA

## Averaged TIC-normalized m/z intensities within each Region/trichome and saved the Region-level abundance table.
region_mean <- aggregate(
  msi_norm[, feat_cols],
  by = list(Region = msi_norm$Region),
  FUN = function(z) mean(z, na.rm = TRUE)
)

cat("Region mean dim:", dim(region_mean), "\n")

reg_out <- file.path(out_dir, paste0(sample_id, "_region_mean_TICnorm_541mz.csv"))
write.csv(region_mean, reg_out, row.names = FALSE)
cat("Saved:", reg_out, "\n")

dev.off()
