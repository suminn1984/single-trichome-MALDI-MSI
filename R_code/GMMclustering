# This script performs Gaussian mixture model (GMM) clustering
# using raw DS and K ion abundances.
# Install and load the mclust package for GMM clustering
if (!requireNamespace("mclust", quietly = TRUE)) install.packages("mclust")
library(mclust)

# select columns for metabolites of interest
ds_col   <- "mz_377.0865"
k_col    <- "mz_285.0410"
krha_col <- "mz_431.0985"
krr_col  <- "mz_577.1555"

stopifnot(all(c(ds_col,k_col,krha_col,krr_col) %in% names(df_all)))

# Build the clustering matrix using RAW DS and K values
X0 <- df_all[, c(ds_col, k_col)]
ok <- complete.cases(X0)
X  <- as.matrix(X0[ok, ])

# GMM clustering (3 states) on RAW
set.seed(1)
mc <- Mclust(X, G = 3)
cat("GMM model:", mc$modelName, "\n")

# Fix cluster labels based on mean DS abundance
# The original GMM cluster labels are arbitrary.
# Therefore, clusters are relabeled according to their mean DS abundance:
#  State 1 = lowest DS mean
#  State 2 = 
#  State 3 = highest DS mean
lab <- mc$classification
ds_mean_by_lab <- tapply(X[,1], lab, mean)   # Calculate mean DS abundance for each original GMM cluster
ord <- order(ds_mean_by_lab)                 
map <- setNames(1:3, ord)                    
lab_fixed <- as.integer(map[as.character(lab)])

df_all$cluster_gmm <- NA_integer_
df_all$cluster_gmm[ok] <- lab_fixed

cat("Cluster sizes (fixed labels):\n")
print(table(df_all$cluster_gmm, useNA="ifany"))
cat("DS mean by state:\n")
print(tapply(df_all[[ds_col]], df_all$cluster_gmm, mean, na.rm=TRUE))

## 5) plot DS vs K colored by cluster
cols_state <- c("orange","cyan","magenta")  # state1,2,3

plot(df_all[[ds_col]], df_all[[k_col]],
     pch = 16,
     col = cols_state[df_all$cluster_gmm],
     xlab = "DS (mz 377.0865)",
     ylab = "K (mz 285.0410)",
     main = "DS vs K (GMM 3-state, RAW)")

legend("topright", legend=paste0("State ",1:3),
       col=cols_state, pch=16, bty="n")

# Calculate state-level summary statistics
# For each GMM state, calculate mean, standard deviation, and sample number for DS, K, K-Rha, and K-Rha-Rha.
# These values can be used to compare metabolite abundance patterns among the three metabolic states.
summ_fun <- function(d){
  data.frame(
    state = unique(d$cluster_gmm),
    
    DS_mean = mean(d[[ds_col]], na.rm=TRUE),
    DS_sd   = sd(d[[ds_col]],   na.rm=TRUE),
    DS_n    = sum(!is.na(d[[ds_col]])),
    
    K_mean  = mean(d[[k_col]],  na.rm=TRUE),
    K_sd    = sd(d[[k_col]],    na.rm=TRUE),
    K_n     = sum(!is.na(d[[k_col]])),
    
    KRha_mean = mean(d[[krha_col]], na.rm=TRUE),
    KRha_sd   = sd(d[[krha_col]],   na.rm=TRUE),
    KRha_n    = sum(!is.na(d[[krha_col]])),
    
    KRhaRha_mean = mean(d[[krr_col]], na.rm=TRUE),
    KRhaRha_sd   = sd(d[[krr_col]],   na.rm=TRUE),
    KRhaRha_n    = sum(!is.na(d[[krr_col]]))
  )
}
# Apply the summary function to each GMM state
res <- do.call(rbind, lapply(split(df_all, df_all$cluster_gmm), summ_fun))
res <- res[order(res$state), ]
print(res)


write.csv(res,    "state_summary_mean_sd_RAW.csv", row.names = FALSE)
write.csv(df_all, "df_all_with_cluster_gmm_RAW.csv", row.names = FALSE)
