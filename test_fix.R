library(tidyverse)
library(MASS)

# Test the prepare_historical_loghr_data function
prepare_historical_loghr_data <- function() {
  set.seed(20260212)
  K <- 27
  mu_true  <- c(-0.30, -0.45)
  tau_true <- c(0.15, 0.15)
  rho_true <- 0.65
  
  R_true <- matrix(c(1, rho_true, rho_true, 1), 2, 2, byrow = TRUE)
  Sigma_true <- diag(tau_true) %*% R_true %*% diag(tau_true)
  
  theta <- MASS::mvrnorm(n = K, mu = mu_true, Sigma = Sigma_true)
  se_os  <- runif(K, 0.10, 0.13)
  se_pfs <- runif(K, 0.08, 0.11)
  rho_within <- runif(K, 0.55, 0.75)
  
  y <- matrix(NA_real_, nrow = K, ncol = 2)
  
  for (k in 1:K) {
    cov_k <- rho_within[k] * se_os[k] * se_pfs[k]
    W_k <- matrix(c(se_os[k]^2, cov_k, cov_k, se_pfs[k]^2), 2, 2, byrow = TRUE)
    y[k, ] <- MASS::mvrnorm(n = 1, mu = theta[k, ], Sigma = W_k)
  }
  
  tibble(
    trial_id = paste0("ICB-HIST-", sprintf("%02d", 1:K)),
    cancer_type = rep(c("Melanoma", "NSCLC", "Renal", "HCC", "Bladder", "Gastric"), length.out = K),
    n_patients = sample(95:200, K, replace = TRUE),
    loghr_os = y[, 1],
    se_loghr_os = se_os,
    loghr_pfs = y[, 2],
    se_loghr_pfs = se_pfs,
    corr_pfs_os = rho_within
  ) %>%
    mutate(cov_pfs_os = corr_pfs_os * se_loghr_pfs * se_loghr_os)
}

# Test 1: Check column names
historical_data <- prepare_historical_loghr_data()
cat("Column names in historical_data:\n")
print(names(historical_data))

# Test 2: Try the select statement from line 677
cat("\nTest select for data tab:\n")
tryCatch({
  result <- historical_data %>%
    select(trial_id, cancer_type, n_patients, loghr_os, se_loghr_os, loghr_pfs, se_loghr_pfs, corr_pfs_os)
  cat("SUCCESS - select worked\n")
  print(names(result))
}, error = function(e) {
  cat("ERROR:", e$message, "\n")
})

# Test 3: Try the scatter plot select
cat("\nTest select for scatter plot:\n")
tryCatch({
  plot_data <- historical_data %>% mutate(type = "Historical")
  cat("After mutate, columns:", paste(names(plot_data), collapse=", "), "\n")
  
  result <- plot_data %>% select(loghr_pfs, loghr_os, type)
  cat("SUCCESS - select worked\n")
  print(names(result))
}, error = function(e) {
  cat("ERROR:", e$message, "\n")
})
