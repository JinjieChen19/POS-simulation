# ============================================================================
# Pre-compile DEFAULT Stan model for faster app startup
# ============================================================================
# This script pre-compiles the most commonly used Stan model configuration
# (fisher_z prior for rho, exponential prior for tau) and saves it as
# bayesian_pos_model.rds
# ============================================================================

# Load required libraries
library(rstan)
source("global.R")  # Load the build_stan_model_improved function

# Build the DEFAULT Stan model with most common configuration
cat("Building DEFAULT Stan model configuration...\n")
cat("  - ρ prior: fisher_z with μ_z=0.5365, σ_z=0.2173 (informative)\n")
cat("  - τ prior: exponential(1) for both OS and PFS\n")
cat("  - μ priors: Normal(-0.35, 1.0) for OS, Normal(-0.45, 1.0) for PFS\n\n")

default_stan_code <- build_stan_model_improved(
  prior_mu_os_mean = -0.35,
  prior_mu_os_sd = 1.0,
  prior_mu_pfs_mean = -0.45,
  prior_mu_pfs_sd = 1.0,
  prior_tau_type = "exponential",
  prior_tau_param_os = 1,
  prior_tau_param_pfs = 1,
  prior_rho_type = "fisher_z",
  prior_rho_param = mu_z_default,  # 0.5365
  prior_rho_param2 = sd_z_default  # 0.2173
)

cat("Compiling Stan model (this will take 1-2 minutes)...\n")
start_time <- Sys.time()

model_compiled <- stan_model(model_code = default_stan_code, verbose = TRUE)

end_time <- Sys.time()
compile_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

cat(sprintf("\n✓ Compilation complete in %.1f seconds\n", compile_time))

# Save the compiled model
output_file <- "bayesian_pos_model.rds"
cat(sprintf("Saving pre-compiled model to: %s\n", output_file))
saveRDS(model_compiled, output_file)

cat("\n✓ Pre-compilation complete!\n")
cat(sprintf("Model saved to: %s\n", output_file))
cat(sprintf("File size: %.2f MB\n", file.info(output_file)$size / 1024^2))
cat("\nThis pre-compiled model will be automatically loaded by the app\n")
cat("when using default prior settings, eliminating the 1-2 minute\n")
cat("compilation delay on startup.\n")
