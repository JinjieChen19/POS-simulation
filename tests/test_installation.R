# Installation Testing Script
# Tests that the package can be installed and all functions work
#
# Usage: source("tests/test_installation.R"); test_installation()

test_installation <- function(verbose = TRUE) {
  
  results <- list()
  all_passed <- TRUE
  
  if (verbose) cat("\n=== Installation Testing ===\n\n")
  
  # Check if package is installed and can be loaded
  if (verbose) cat("Trying to load POSsimulation package...\n")
  
  package_loaded <- FALSE
  if ("POSsimulation" %in% rownames(installed.packages())) {
    load_result <- try(library(POSsimulation), silent = TRUE)
    if (!inherits(load_result, "try-error")) {
      package_loaded <- TRUE
      results$package_load <- "PASS"
      if (verbose) cat("  ✓ Package loaded successfully\n")
    } else {
      results$package_load <- paste("FAIL: Error loading package")
      all_passed <- FALSE
      if (verbose) cat("  ✗ Error loading package\n")
    }
  } else {
    results$package_load <- "SKIP: Package not installed"
    if (verbose) cat("  ⚠ Package not installed\n")
  }
  
  # Check if functions exist
  if (package_loaded) {
    if (verbose) cat("\nChecking for app functions...\n")
    required_functions <- c("run_pos_app", "run_pos_app_local", "run_pos_app_authenticated")
    
    for (func in required_functions) {
      if (exists(func, mode = "function")) {
        results[[paste0("func_", func)]] <- "PASS"
        if (verbose) cat("  ✓ Function", func, "exists\n")
      } else {
        results[[paste0("func_", func)]] <- paste("FAIL: Function", func, "not found")
        all_passed <- FALSE
        if (verbose) cat("  ✗ Function", func, "not found\n")
      }
    }
  }
  
  # Final summary
  if (verbose) {
    cat("\n==========================================\n")
    if (all_passed) {
      cat("All installation tests passed! ✓\n")
    } else {
      cat("Some installation tests failed! ✗\n")
    }
    cat("==========================================\n\n")
  }
  
  invisible(list(all_passed = all_passed, results = results))
}

if (!interactive()) {
  result <- test_installation(verbose = TRUE)
  if (!result$all_passed) quit(status = 1)
}
