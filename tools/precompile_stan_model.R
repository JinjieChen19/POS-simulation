#!/usr/bin/env Rscript
# ============================================================================
# PRECOMPILE STAN MODEL
# ============================================================================
# This script precompiles the Stan model and saves it as an .rds file
# Run this script when:
# 1. The Stan model code changes
# 2. Building/updating the package
# 3. First-time setup
#
# The precompiled model eliminates 1-2 minute compilation wait for users!
# ============================================================================

cat("=== Precompiling Stan Model ===\n\n")

# Load required library
if (!require("rstan", quietly = TRUE)) {
  stop("rstan package not installed. Please install it first:\n  install.packages('rstan')")
}

# Set working directory to package root
# (Assuming script is run from tools/ directory)
if (basename(getwd()) == "tools") {
  setwd("..")
}

cat("Working directory:", getwd(), "\n\n")

# Define paths
stan_file <- "inst/stan/stan_universal_model_optimized.stan"
output_file <- "inst/stan/stan_model_compiled.rds"

# Check if Stan file exists
if (!file.exists(stan_file)) {
  stop("Stan model file not found: ", stan_file, "\n",
       "Please ensure you're in the package root directory.")
}

cat("Stan model file:", stan_file, "\n")
cat("Output file:    ", output_file, "\n\n")

# Compile the model
cat("Compiling Stan model (this may take 1-2 minutes)...\n")
compile_start <- Sys.time()

tryCatch({
  model_compiled <- rstan::stan_model(
    file = stan_file,
    model_name = "bayesian_pos_universal_optimized",
    verbose = TRUE
  )
  
  compile_end <- Sys.time()
  compile_time <- as.numeric(difftime(compile_end, compile_start, units = "secs"))
  
  cat("\n✓ Compilation successful!\n")
  cat(sprintf("  Time: %.1f seconds\n\n", compile_time))
  
  # Save compiled model
  cat("Saving compiled model to:", output_file, "\n")
  saveRDS(model_compiled, output_file, compress = "xz")
  
  # Verify saved file
  file_size <- file.info(output_file)$size / 1024 / 1024  # MB
  cat(sprintf("✓ Saved successfully! (%.2f MB)\n\n", file_size))
  
  # Test loading
  cat("Testing reload...\n")
  model_test <- readRDS(output_file)
  cat("✓ Model loads correctly!\n\n")
  
  cat("=== Precompilation Complete ===\n")
  cat("The precompiled model is ready to use.\n")
  cat("Users will experience instant app startup with no compilation wait!\n\n")
  
}, error = function(e) {
  cat("\n✗ ERROR during compilation:\n")
  cat(e$message, "\n\n")
  cat("Please check:\n")
  cat("  1. Stan model syntax in", stan_file, "\n")
  cat("  2. rstan package is properly installed\n")
  cat("  3. C++ toolchain is available\n\n")
  stop("Precompilation failed")
})
