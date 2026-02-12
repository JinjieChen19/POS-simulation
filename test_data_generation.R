# ============================================================================
# TEST SCRIPT: Verify Historical Data Generation
# ============================================================================
# This script tests the exact data generation code from app.R
# to verify the between-trial correlation is correct.
# ============================================================================

# Exact code from app.R prepare_historical_loghr_data()
set.seed(20260211)

n_trials <- 27

# Use Cholesky decomposition for precise correlation control
mu_os <- -0.30   # Population mean for OS
mu_pfs <- -0.45  # Population mean for PFS
sd_os <- 0.15    # Between-trial SD for OS (increased for better identifiability)
sd_pfs <- 0.15   # Between-trial SD for PFS (increased for better identifiability)
target_cor <- 0.65  # Target between-trial correlation

# Create covariance matrix IN [OS, PFS] ORDER to match Stan model
# This is CRITICAL - order must match how data is passed to Stan
cov_matrix <- matrix(c(
  sd_os^2, target_cor * sd_os * sd_pfs,
  target_cor * sd_os * sd_pfs, sd_pfs^2
), nrow = 2, byrow = TRUE)

cat("Covariance matrix:\n")
print(cov_matrix)

# Cholesky decomposition
L <- chol(cov_matrix)

cat("\nCholesky factor (upper triangular from R's chol()):\n")
print(L)

cat("\nt(L) (lower triangular):\n")
print(t(L))

# Generate independent standard normal variates
Z <- matrix(rnorm(2 * n_trials), nrow = 2, ncol = n_trials)

cat("\nFirst few columns of Z:\n")
print(Z[, 1:5])

# Transform to correlated variates
Y <- t(L) %*% Z

cat("\nFirst few columns of Y:\n")
print(Y[, 1:5])

# Add means - Y[1,] is OS, Y[2,] is PFS (matching covariance matrix order)
loghr_os <- mu_os + Y[1, ]
loghr_pfs <- mu_pfs + Y[2, ]

cat("\n=== BEFORE CLIPPING ===\n")
cat("PFS: mean=", mean(loghr_pfs), "sd=", sd(loghr_pfs), "\n")
cat("OS:  mean=", mean(loghr_os), "sd=", sd(loghr_os), "\n")
cat("Correlation:", cor(loghr_pfs, loghr_os), "\n")
cat("PFS range:", range(loghr_pfs), "\n")
cat("OS range:", range(loghr_os), "\n")

# Ensure reasonable ranges (gentle clipping to maintain realistic values)
loghr_pfs_clipped <- pmax(pmin(loghr_pfs, -0.15), -0.75)
loghr_os_clipped <- pmax(pmin(loghr_os, -0.05), -0.55)

cat("\n=== AFTER CLIPPING ===\n")
cat("PFS: mean=", mean(loghr_pfs_clipped), "sd=", sd(loghr_pfs_clipped), "\n")
cat("OS:  mean=", mean(loghr_os_clipped), "sd=", sd(loghr_os_clipped), "\n")
cat("Correlation:", cor(loghr_pfs_clipped, loghr_os_clipped), "\n")
cat("PFS range:", range(loghr_pfs_clipped), "\n")
cat("OS range:", range(loghr_os_clipped), "\n")

cat("\nNumber of values clipped:\n")
cat("PFS:", sum(loghr_pfs != loghr_pfs_clipped), "\n")
cat("OS:", sum(loghr_os != loghr_os_clipped), "\n")

cat("\n=== SUMMARY ===\n")
cat("Target correlation: 0.65\n")
cat("Achieved correlation (before clip):", cor(loghr_pfs, loghr_os), "\n")
cat("Achieved correlation (after clip):", cor(loghr_pfs_clipped, loghr_os_clipped), "\n")

# If correlation is much lower than expected, investigate
if (cor(loghr_pfs_clipped, loghr_os_clipped) < 0.3) {
  cat("\n⚠️  WARNING: Correlation is unexpectedly low!\n")
  cat("This suggests a problem with the data generation.\n")
} else if (cor(loghr_pfs_clipped, loghr_os_clipped) > 0.5) {
  cat("\n✓ Correlation looks reasonable (> 0.5)\n")
  cat("If Stan estimates ρ ≈ 0.14, the issue is elsewhere (not data generation).\n")
}

cat("\n=== DATA FOR DEBUGGING ===\n")
cat("First 5 trials:\n")
for (i in 1:5) {
  cat(sprintf("Trial %d: PFS=%.4f, OS=%.4f\n", i, loghr_pfs_clipped[i], loghr_os_clipped[i]))
}
