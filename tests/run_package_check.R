# Package Check Script
# Runs devtools::check() to validate the package
#
# Usage: source("tests/run_package_check.R"); run_package_check()

run_package_check <- function(verbose = TRUE, document = TRUE) {
  
  if (verbose) cat("\n=== Running Package Check ===\n\n")
  
  if (!requireNamespace("devtools", quietly = TRUE)) {
    cat("✗ devtools package not installed\n")
    cat("Install with: install.packages('devtools')\n\n")
    return(invisible(FALSE))
  }
  
  if (document) {
    if (verbose) cat("Documenting package...\n")
    doc_result <- try(devtools::document(), silent = !verbose)
    if (inherits(doc_result, "try-error")) {
      cat("✗ Error documenting package\n")
      return(invisible(FALSE))
    }
    if (verbose) cat("✓ Package documented\n\n")
  }
  
  if (verbose) cat("Running devtools::check()...\n\n")
  
  check_result <- try(
    devtools::check(document = FALSE, manual = FALSE, vignettes = FALSE),
    silent = FALSE
  )
  
  if (inherits(check_result, "try-error")) {
    cat("✗ Package check failed\n")
    return(invisible(FALSE))
  }
  
  if (verbose) {
    cat("\n==========================================\n")
    cat("Check Results:\n")
    cat("==========================================\n\n")
    
    if (length(check_result$errors) == 0 && length(check_result$warnings) == 0) {
      cat("✓ Package check passed!\n")
      cat("==========================================\n\n")
      return(invisible(TRUE))
    } else {
      cat("✗ Package check found issues\n")
      cat("==========================================\n\n")
      return(invisible(FALSE))
    }
  }
  
  invisible(length(check_result$errors) == 0 && length(check_result$warnings) == 0)
}

if (!interactive()) {
  success <- run_package_check(verbose = TRUE)
  if (!success) quit(status = 1)
}
