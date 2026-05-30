#Extract m/z values from each scan/pixel
library(Cardinal)

imzml_path <- "D:/2025/May/May/feronia4_4.imzML"
msi <- readMSIData(imzml_path)
mz_list <- mz(msi)
nscan <- length(mz_list) # Number of scans/pixels
# we set bin width for m/z binning, and they are rounded to nearst bins
bin_width <- 0.001
to_bin <- function(v) round(v / bin_width) * bin_width
# Create an environment to store the occurrence count of each m/z bin
counts_env <- new.env(hash = TRUE, parent = emptyenv())
#Loop through each scan/pixel and count how many scans contain each m/z bin
for (i in seq_len(nscan)) {
  bins <- unique(to_bin(mz_list[[i]]))
  # If the m/z bin already exists, increase its count by 1
  for (b in bins) {
    key <- format(b, scientific = FALSE, trim = TRUE)
    if (exists(key, envir = counts_env, inherits = FALSE)) {
      counts_env[[key]] <- counts_env[[key]] + 1L
    } else {
      counts_env[[key]] <- 1L # 1L means integer
    }
  }
  
  if (i %% 5000 == 0) message("processed scans: ", i, "/", nscan) # shows the progress of the calculation
}

keys <- ls(counts_env)
counts <- as.integer(mget(keys, counts_env))
mz_bins <- as.numeric(keys)
freq <- counts / nscan # calculating the freqency using counts and nscan

# filter. we filtered m/z based on the freq. 
min_freq <- 0.01
max_freq <- 0.80

keep <- freq >= min_freq & freq <= max_freq
mz_keep <- sort(mz_bins[keep])

length(mz_keep)
# This list will be used for downstream intensity extraction and analysis
write.csv(data.frame(mz = mz_keep),
          "D:/2025/May/May/mz_keep3_541.csv",
          row.names = FALSE)
