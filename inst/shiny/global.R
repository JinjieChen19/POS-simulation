# ============================================================================
# GLOBAL.R - Shared code for Bayesian PoS Simulation App (Enhanced for Deployment)
# ============================================================================
# This file contains code that runs once when the app starts up
# - rstan configuration with smart core detection
# - Model caching (.rds) to avoid re-compilation
# - Helper functions
# - Default values
# ============================================================================
#
# NOTE: When running as part of POSsimulation package, all dependencies are
# already loaded via NAMESPACE. Library calls are removed to prevent conflicts.
# ============================================================================

# ===========================================================================
# SMART MC.CORES CONFIGURATION
# ===========================================================================
# Detect available cores but respect VM limits
# For Fly.io and similar platforms: typically 1 vCPU
# For local development: use multiple cores
# ===========================================================================

# Function to safely detect and set mc.cores
safe_set_mc_cores <- function() {
  # Detect total cores
  total_cores <- parallel::detectCores()
  
  # Check if we're in a constrained environment (Fly.io, Docker, etc.)
  # Heuristic: if total_cores is 1 or if we detect container environment
  is_container <- file.exists("/.dockerenv") || 
                  Sys.getenv("FLY_APP_NAME") != "" ||
                  Sys.getenv("DYNO") != ""  # Also check for Heroku
  
  if (is_container || total_cores == 1) {
    # Force single-core in containers
    mc_cores <- 1
    message("Container environment detected. Using single-core mode (mc.cores = 1)")
  } else {
    # For local/development: use all cores but cap at reasonable limit
    # Leave 1 core free for system
    mc_cores <- max(1, min(total_cores - 1, 4))  # Cap at 4 cores
    message(sprintf("Local environment detected. Using %d cores (out of %d available)", mc_cores, total_cores))
  }
  
  # Set the option
  options(mc.cores = mc_cores)
  
  # Also set environment variables for Stan
  Sys.setenv(STAN_NUM_THREADS = as.character(mc_cores))
  Sys.setenv(OMP_NUM_THREADS = as.character(mc_cores))
  
  return(mc_cores)
}

# Execute smart core detection
current_mc_cores <- safe_set_mc_cores()

# Disable auto_write (required for shinyapps.io and Fly.io)
rstan::rstan_options(auto_write = FALSE)

# ===========================================================================
# STAN MODEL CACHING SYSTEM
# ===========================================================================
# Pre-compiled models are saved as .rds files to avoid re-compilation
# This significantly speeds up app startup on subsequent runs
# ===========================================================================

# Cache directory for compiled models
CACHE_DIR <- file.path(getwd(), "cache")
if (!dir.exists(CACHE_DIR)) {
  dir.create(CACHE_DIR, recursive = TRUE, showWarnings = FALSE)
}

# Function to get cache file path for a model
get_cache_path <- function(model_hash) {
  file.path(CACHE_DIR, paste0("stan_model_", model_hash, ".rds"))
}

# Function to compute hash for model code
compute_model_hash <- function(stan_code) {
  # Create a deterministic hash from the model code
  digest::digest(stan_code, algo = "md5")
}

# Function to get or compile Stan model with caching
get_stan_model_cached <- function(stan_code, verbose = FALSE) {
  # Check if digest package is available (for hashing)
  if (!requireNamespace("digest", quietly = TRUE)) {
    warning("Package 'digest' not installed. Model caching disabled.")
    # Fall back to direct compilation
    return(stan_model(model_code = stan_code, verbose = verbose))
  }
  
  # Compute hash of model code
  model_hash <- compute_model_hash(stan_code)
  cache_path <- get_cache_path(model_hash)
  
  # Check if cached model exists
  if (file.exists(cache_path)) {
    if (verbose) {
      message(sprintf("Loading pre-compiled Stan model from cache: %s", basename(cache_path)))
    }
    tryCatch({
      compiled_model <- readRDS(cache_path)
      if (verbose) {
        message("✓ Successfully loaded cached model")
      }
      return(compiled_model)
    }, error = function(e) {
      warning(sprintf("Failed to load cached model: %s. Re-compiling...", e$message))
      # Fall through to compilation
    })
  }
  
  # Model not in cache or failed to load - compile it
  if (verbose) {
    message("Compiling Stan model (this may take 1-2 minutes)...")
  }
  
  compiled_model <- stan_model(model_code = stan_code, verbose = verbose)
  
  # Save to cache
  tryCatch({
    saveRDS(compiled_model, cache_path)
    if (verbose) {
      message(sprintf("✓ Model cached to: %s", basename(cache_path)))
    }
  }, error = function(e) {
    warning(sprintf("Failed to cache model: %s", e$message))
  })
  
  return(compiled_model)
}

# ===========================================================================
# FISHER-Z PRIOR DEFAULTS
# ===========================================================================
# Target: rho 95% interval ~ [0.35, 0.80]
# Based on informative prior for oncology trials
# ===========================================================================
rho_L <- 0.35
rho_U <- 0.80
mu_z_default <- (atanh(rho_L) + atanh(rho_U)) / 2  # 0.5365
sd_z_default <- (atanh(rho_U) - atanh(rho_L)) / (2 * 1.96)  # 0.2173

# ===========================================================================
# PRE-COMPILED MODEL LOADING
# ===========================================================================
# Load pre-compiled DEFAULT Stan model if available
# This eliminates 1-2 minutes of compilation time on startup
# ===========================================================================
DEFAULT_MODEL_FILE <- "bayesian_pos_model.rds"
precompiled_model <- NULL

if (file.exists(DEFAULT_MODEL_FILE)) {
  cat("Loading pre-compiled Stan model from:", DEFAULT_MODEL_FILE, "\n")
  tryCatch({
    precompiled_model <- readRDS(DEFAULT_MODEL_FILE)
    cat("✓ Pre-compiled model loaded successfully!\n")
    cat("  This eliminates 1-2 minutes of compilation time.\n")
    cat("  Model uses default priors: fisher_z + exponential\n")
  }, error = function(e) {
    warning(sprintf("Failed to load pre-compiled model: %s", e$message))
    cat("  Will compile model on-demand when needed.\n")
    precompiled_model <<- NULL
  })
} else {
  cat("Note: Pre-compiled model not found.\n")
  cat("  To pre-compile the DEFAULT model for faster startup:\n")
  cat("  Run: R -e \"source('precompile_model.R')\"\n")
  cat("  Models will be compiled on-demand (slower first run).\n")
}

# ===========================================================================
# DATA GENERATION FUNCTION
# ===========================================================================
# Generates historical trial data using hierarchical model
# Now accepts parameters for customization
# ===========================================================================
prepare_historical_loghr_data <- function(seed = 20260212,
                                          mu_os = -0.30, mu_pfs = -0.45,
                                          tau_os = 0.15, tau_pfs = 0.15,
                                          rho_true = 0.65,
                                          se_os_min = 0.10, se_os_max = 0.13,
                                          se_pfs_min = 0.08, se_pfs_max = 0.11,
                                          rho_within_min = 0.55, rho_within_max = 0.75) {
  set.seed(seed)
  
  K <- 27  # Number of historical trials
  
  # True population parameters (logHR scale)
  mu_true  <- c(mu_os, mu_pfs)   # (OS, PFS)
  tau_true <- c(tau_os, tau_pfs)     # between-trial SDs
  
  R_true <- matrix(c(1, rho_true, rho_true, 1), 2, 2, byrow = TRUE)
  Sigma_true <- diag(tau_true) %*% R_true %*% diag(tau_true)
  
  # Trial-level true effects theta_k ~ MVN(mu_true, Sigma_true)
  theta <- MASS::mvrnorm(n = K, mu = mu_true, Sigma = Sigma_true)  # K x 2
  
  # Realistic SEs
  se_os  <- runif(K, se_os_min, se_os_max)  # OS ~ Schoenfeld-like magnitude
  se_pfs <- runif(K, se_pfs_min, se_pfs_max)
  
  # Within-trial correlation of estimated logHRs
  rho_within <- runif(K, rho_within_min, rho_within_max)
  
  # Observed summary estimates y_k ~ MVN(theta_k, W_k)
  y <- matrix(NA_real_, nrow = K, ncol = 2)  # columns: OS, PFS
  
  for (k in 1:K) {
    cov_k <- rho_within[k] * se_os[k] * se_pfs[k]
    W_k <- matrix(c(se_os[k]^2, cov_k,
                    cov_k,      se_pfs[k]^2),
                  2, 2, byrow = TRUE)
    y[k, ] <- MASS::mvrnorm(n = 1, mu = theta[k, ], Sigma = W_k)
  }
  
  # Return as tibble
  tibble(
    trial_id = paste0("ICB-HIST-", sprintf("%02d", 1:K)),
    cancer_type = rep(c("Melanoma", "NSCLC", "Renal", "HCC", "Bladder", "Gastric"), length.out = K),
    n_patients = sample(95:200, K, replace = TRUE),
    loghr_os = y[, 1],    # Observed OS logHR
    se_loghr_os = se_os,
    loghr_pfs = y[, 2],   # Observed PFS logHR
    se_loghr_pfs = se_pfs,
    corr_pfs_os = rho_within
  ) %>%
    mutate(cov_pfs_os = corr_pfs_os * se_loghr_pfs * se_loghr_os)
}

# ===========================================================================
# STAN MODEL BUILDER
# ===========================================================================
# Builds Stan model code with flexible prior specifications
# ===========================================================================
build_stan_model_improved <- function(prior_mu_os_mean = -0.35, prior_mu_os_sd = 1.0,
                                      prior_mu_pfs_mean = -0.45, prior_mu_pfs_sd = 1.0,
                                      prior_tau_type = "exponential", prior_tau_param_os = 1, prior_tau_param_pfs = 1,
                                      prior_rho_type = "fisher_z", prior_rho_param = 0, prior_rho_param2 = 1.5) {
  
  # Build tau priors based on selected distribution
  if (prior_tau_type == "exponential") {
    tau_prior_os <- paste0("tau_os ~ exponential(", prior_tau_param_os, ");")
    tau_prior_pfs <- paste0("tau_pfs ~ exponential(", prior_tau_param_pfs, ");")
  } else if (prior_tau_type == "half_normal") {
    tau_prior_os <- paste0("tau_os ~ normal(0, ", prior_tau_param_os, ") T[0,];")
    tau_prior_pfs <- paste0("tau_pfs ~ normal(0, ", prior_tau_param_pfs, ") T[0,];")
  }
  
  # Build rho prior based on selected distribution
  if (prior_rho_type == "uniform") {
    rho_decl <- "real<lower=-0.95, upper=0.95> rho;"
    rho_prior <- paste0("rho ~ uniform(-0.95, 0.95);")
  } else if (prior_rho_type == "uniform_positive") {
    rho_decl <- "real<lower=0, upper=0.95> rho;"
    rho_prior <- paste0("rho ~ uniform(0, 0.95);")
  } else if (prior_rho_type == "beta") {
    rho_decl <- "real<lower=0, upper=1> rho;"
    rho_prior <- paste0("rho ~ beta(", prior_rho_param, ", ", prior_rho_param2, ");")
  } else if (prior_rho_type == "lkj") {
    rho_decl <- "corr_matrix[2] Omega;"
    rho_prior <- paste0("Omega ~ lkj_corr(", prior_rho_param, ");")
  } else if (prior_rho_type == "fisher_z") {
    rho_decl <- "real z_rho;"
    rho_prior <- paste0("z_rho ~ normal(", prior_rho_param, ", ", prior_rho_param2, ");")
  }
  
  # Build Stan model code
  stan_code <- paste0("
data {
  int<lower=1> K;               // number of historical trials
  vector[2] y_hist[K];          // (OS, PFS) for each trial
  cov_matrix[2] W_hist[K];      // within-trial covariance
  vector[2] y_curr;             // current trial
  cov_matrix[2] W_curr;         // current trial covariance
}

parameters {
  vector[2] mu;                 // population means [mu_os, mu_pfs]
  real<lower=0> tau_os;         // between-trial SD (OS)
  real<lower=0> tau_pfs;        // between-trial SD (PFS)
  ", rho_decl, "
  vector[2] z_hist[K];          // standardized trial effects
  vector[2] z_curr;             // standardized current trial effect
}

transformed parameters {
  vector[2] theta_hist[K];
  vector[2] theta_curr;
  matrix[2, 2] Sigma;
  matrix[2, 2] L_Sigma;
  ", if(prior_rho_type == "fisher_z") "real rho = tanh(z_rho);" else "", "
  
  // Build correlation matrix
  ", if(prior_rho_type == "lkj") {
    "Sigma[1, 1] = tau_os^2;
  Sigma[2, 2] = tau_pfs^2;
  Sigma[1, 2] = tau_os * tau_pfs * Omega[1, 2];
  Sigma[2, 1] = Sigma[1, 2];"
  } else {
    "Sigma[1, 1] = tau_os^2;
  Sigma[2, 2] = tau_pfs^2;
  Sigma[1, 2] = rho * tau_os * tau_pfs;
  Sigma[2, 1] = Sigma[1, 2];"
  }, "
  
  L_Sigma = cholesky_decompose(Sigma);
  
  // Historical trial effects (non-centered parameterization)
  for (k in 1:K) {
    theta_hist[k] = mu + L_Sigma * z_hist[k];
  }
  
  // Current trial effect
  theta_curr = mu + L_Sigma * z_curr;
}

model {
  // Priors
  mu[1] ~ normal(", prior_mu_os_mean, ", ", prior_mu_os_sd, ");
  mu[2] ~ normal(", prior_mu_pfs_mean, ", ", prior_mu_pfs_sd, ");
  ", tau_prior_os, "
  ", tau_prior_pfs, "
  ", rho_prior, "
  
  // Standard normal priors for non-centered parameterization
  for (k in 1:K) {
    z_hist[k] ~ std_normal();
  }
  z_curr ~ std_normal();
  
  // Likelihood
  for (k in 1:K) {
    y_hist[k] ~ multi_normal(theta_hist[k], W_hist[k]);
  }
  y_curr ~ multi_normal(theta_curr, W_curr);
}

generated quantities {
  real theta_os_post = theta_curr[1];
  real theta_pfs_post = theta_curr[2];
  real rho_out = ", if(prior_rho_type == "fisher_z") "tanh(z_rho)" else if(prior_rho_type == "lkj") "Omega[1,2]" else "rho", ";
}
")
  
  return(stan_code)
}

# ===========================================================================
# STARTUP MESSAGE
# ===========================================================================
message("=== Bayesian PoS Simulation - Enhanced Global Configuration ===")
message(sprintf("✓ mc.cores set to: %d", current_mc_cores))
message(sprintf("✓ Model caching enabled in: %s", CACHE_DIR))
message("✓ Smart core detection active")
message("================================================================")
