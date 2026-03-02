# Package Validation Script
# Comprehensive pre-flight checks to catch issues before users encounter them
# 
# This script validates:
# - Package structure
# - DESCRIPTION and NAMESPACE files
# - R syntax in all files
# - No library() calls in inst/ (prevents namespace conflicts)
# - File existence
# - Common anti-patterns
#
# Usage: source("tests/validate_package.R"); validate_package()

validate_package <- function(verbose = TRUE) {
  
  results <- list()
  all_passed <- TRUE
  
  if (verbose) cat("\n=== Package Validation ===\n\n")
  
  # 1. Check package structure
  if (verbose) cat("Checking package structure...\n")
  required_dirs <- c("R", "inst", "man")
  required_files <- c("DESCRIPTION", "NAMESPACE")
  
  for (dir in required_dirs) {
    if (!dir.exists(dir)) {
      results[[paste0("dir_", dir)]] <- paste("FAIL: Missing directory:", dir)
      all_passed <- FALSE
      if (verbose) cat("  ✗ Missing directory:", dir, "\n")
    } else {
      results[[paste0("dir_", dir)]] <- "PASS"
      if (verbose) cat("  ✓ Directory", dir, "exists\n")
    }
  }
  
  for (file in required_files) {
    if (!file.exists(file)) {
      results[[paste0("file_", file)]] <- paste("FAIL: Missing file:", file)
      all_passed <- FALSE
      if (verbose) cat("  ✗ Missing file:", file, "\n")
    } else {
      results[[paste0("file_", file)]] <- "PASS"
      if (verbose) cat("  ✓ File", file, "exists\n")
    }
  }
  
  # 2. Validate DESCRIPTION file
  if (verbose) cat("\nValidating DESCRIPTION file...\n")
  if (file.exists("DESCRIPTION")) {
    desc <- try(read.dcf("DESCRIPTION"), silent = TRUE)
    if (inherits(desc, "try-error")) {
      results$description_valid <- "FAIL: DESCRIPTION file is malformed"
      all_passed <- FALSE
      if (verbose) cat("  ✗ DESCRIPTION file is malformed\n")
    } else {
      required_fields <- c("Package", "Version", "Title", "Description")
      missing_fields <- setdiff(required_fields, colnames(desc))
      if (length(missing_fields) > 0) {
        results$description_fields <- paste("FAIL: Missing fields:", paste(missing_fields, collapse = ", "))
        all_passed <- FALSE
        if (verbose) cat("  ✗ Missing fields:", paste(missing_fields, collapse = ", "), "\n")
      } else {
        results$description_valid <- "PASS"
        if (verbose) cat("  ✓ DESCRIPTION file is valid\n")
      }
    }
  }
  
  # 3. Check for library() calls in inst/ files (causes namespace conflicts)
  if (verbose) cat("\nChecking for library() calls in inst/ files...\n")
  inst_files <- list.files("inst", pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
  library_calls_found <- c()
  
  for (file in inst_files) {
    content <- readLines(file, warn = FALSE)
    # Look for library() or require() calls that aren't commented out
    library_lines <- grep("^[^#]*\\b(library|require)\\(", content, value = TRUE)
    if (length(library_lines) > 0) {
      library_calls_found <- c(library_calls_found, paste(file, ":", length(library_lines), "calls"))
      all_passed <- FALSE
    }
  }
  
  if (length(library_calls_found) > 0) {
    results$no_library_in_inst <- paste("FAIL: Found library() calls in:", paste(library_calls_found, collapse = "; "))
    if (verbose) {
      cat("  ✗ Found library() calls in inst/ files:\n")
      for (item in library_calls_found) {
        cat("    -", item, "\n")
      }
    }
  } else {
    results$no_library_in_inst <- "PASS"
    if (verbose) cat("  ✓ No library() calls in inst/ files\n")
  }
  
  # 4. Validate R syntax in all R files
  if (verbose) cat("\nValidating R syntax in all .R files...\n")
  r_files <- c(
    list.files("R", pattern = "\\.R$", full.names = TRUE, recursive = TRUE),
    list.files("inst", pattern = "\\.R$", full.names = TRUE, recursive = TRUE)
  )
  
  syntax_errors <- c()
  for (file in r_files) {
    result <- try(parse(file, keep.source = FALSE), silent = TRUE)
    if (inherits(result, "try-error")) {
      syntax_errors <- c(syntax_errors, file)
      all_passed <- FALSE
    }
  }
  
  if (length(syntax_errors) > 0) {
    results$syntax_valid <- paste("FAIL: Syntax errors in:", paste(syntax_errors, collapse = ", "))
    if (verbose) {
      cat("  ✗ Syntax errors found in:\n")
      for (file in syntax_errors) {
        cat("    -", file, "\n")
      }
    }
  } else {
    results$syntax_valid <- "PASS"
    if (verbose) cat("  ✓ All R files have valid syntax\n")
  }
  
  # 5. Check for Stan model files
  if (verbose) cat("\nChecking for Stan model files...\n")
  stan_files <- list.files("inst/stan", pattern = "\\.stan$", full.names = TRUE)
  if (length(stan_files) == 0) {
    results$stan_files <- "WARN: No Stan model files found in inst/stan/"
    if (verbose) cat("  ⚠ No Stan model files found\n")
  } else {
    results$stan_files <- "PASS"
    if (verbose) cat("  ✓ Found", length(stan_files), "Stan model file(s)\n")
  }
  
  # Final summary
  if (verbose) {
    cat("\n")
    cat("==========================================\n")
    if (all_passed) {
      cat("All checks passed! ✓\n")
      cat("Package is ready for distribution.\n")
    } else {
      cat("Some checks failed! ✗\n")
      cat("Please fix the issues above before sharing.\n")
    }
    cat("==========================================\n\n")
  }
  
  invisible(list(
    all_passed = all_passed,
    results = results
  ))
}

# Run validation if executed directly
if (!interactive()) {
  result <- validate_package(verbose = TRUE)
  if (!result$all_passed) {
    quit(status = 1)
  }
}
