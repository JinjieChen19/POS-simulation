// ============================================================================
// UNIVERSAL STAN MODEL FOR BAYESIAN POS SIMULATION
// ============================================================================
// This model accepts ALL priors as data parameters
// No need to recompile when changing priors!
// Designed for local RStudio Server with team access
// ============================================================================

data {
  // Historical trials
  int<lower=1> K;                    // Number of historical trials
  vector[2] y_hist[K];               // Observed log(HR) for each trial: [OS, PFS]
  matrix[2,2] W_hist[K];             // Within-trial covariance matrices
  
  // Current trial
  vector[2] y_curr;                  // Current trial observed log(HR): [OS, PFS]
  matrix[2,2] W_curr;                // Current trial covariance
  
  // ===========================================================================
  // PRIOR PARAMETERS (passed as data - no recompilation needed!)
  // ===========================================================================
  
  // Priors for mu (population means)
  real prior_mu_os_mean;
  real<lower=0> prior_mu_os_sd;
  real prior_mu_pfs_mean;
  real<lower=0> prior_mu_pfs_sd;
  
  // Priors for tau (between-trial standard deviations)
  int<lower=1,upper=3> prior_tau_type;  // 1=exponential, 2=half_normal, 3=uniform
  real<lower=0> prior_tau_param_os;
  real<lower=0> prior_tau_param_pfs;
  real<lower=0> prior_tau_param2_os;   // For uniform: upper bound
  real<lower=0> prior_tau_param2_pfs;
  
  // Priors for rho (between-trial correlation)
  int<lower=1,upper=5> prior_rho_type;  // 1=fisher_z, 2=uniform, 3=uniform_pos, 4=beta, 5=lkj
  real prior_rho_param;   // Mean for fisher_z, alpha for beta, eta for lkj
  real<lower=0> prior_rho_param2;  // SD for fisher_z, beta for beta
  real prior_rho_lower;   // Lower bound for uniform
  real prior_rho_upper;   // Upper bound for uniform
}

transformed data {
  int<lower=1> N = K + 1;            // Total trials (historical + current)
  vector[2] y[N];                    // All observed log(HR)
  matrix[2,2] W[N];                  // All covariance matrices
  
  // Combine historical and current data
  for (k in 1:K) {
    y[k] = y_hist[k];
    W[k] = W_hist[k];
  }
  y[N] = y_curr;
  W[N] = W_curr;
}

parameters {
  vector[2] mu;                      // Population means [OS, PFS]
  vector<lower=0>[2] tau;            // Between-trial SDs
  
  // Correlation parameter (depends on prior_rho_type)
  real z_rho;                        // For fisher_z parameterization
  real<lower=-1,upper=1> rho_raw;    // For direct parameterization
  
  vector[2] theta[N];                // Trial-specific effects
}

transformed parameters {
  real<lower=-1,upper=1> rho;        // Actual correlation parameter
  matrix[2,2] Sigma;                 // Between-trial covariance matrix
  matrix[2,2] L_Sigma;               // Cholesky factor of Sigma
  
  // Convert to correlation based on prior type
  if (prior_rho_type == 1) {
    // Fisher-z transformation
    rho = tanh(z_rho);
  } else if (prior_rho_type == 4) {
    // Beta prior (mapped to [-1,1] but we use [0,1] portion)
    rho = rho_raw;  // Will be constrained by prior
  } else {
    // Direct parameterization (uniform, LKJ, etc.)
    rho = rho_raw;
  }
  
  // Build covariance matrix
  Sigma[1,1] = tau[1]^2;
  Sigma[2,2] = tau[2]^2;
  Sigma[1,2] = rho * tau[1] * tau[2];
  Sigma[2,1] = Sigma[1,2];
  
  // Cholesky decomposition for efficiency
  L_Sigma = cholesky_decompose(Sigma);
}

model {
  // ===========================================================================
  // PRIORS (all parameters passed as data)
  // ===========================================================================
  
  // Priors for mu
  mu[1] ~ normal(prior_mu_os_mean, prior_mu_os_sd);
  mu[2] ~ normal(prior_mu_pfs_mean, prior_mu_pfs_sd);
  
  // Priors for tau (based on prior_tau_type)
  if (prior_tau_type == 1) {
    // Exponential
    tau[1] ~ exponential(prior_tau_param_os);
    tau[2] ~ exponential(prior_tau_param_pfs);
  } else if (prior_tau_type == 2) {
    // Half-normal
    tau[1] ~ normal(0, prior_tau_param_os);
    tau[2] ~ normal(0, prior_tau_param_pfs);
  } else if (prior_tau_type == 3) {
    // Uniform (implicit with bounds in parameters)
    tau[1] ~ uniform(0, prior_tau_param2_os);
    tau[2] ~ uniform(0, prior_tau_param2_pfs);
  }
  
  // Priors for rho (based on prior_rho_type)
  if (prior_rho_type == 1) {
    // Fisher-z transformation
    z_rho ~ normal(prior_rho_param, prior_rho_param2);
  } else if (prior_rho_type == 2 || prior_rho_type == 3) {
    // Uniform (direct or positive)
    rho_raw ~ uniform(prior_rho_lower, prior_rho_upper);
  } else if (prior_rho_type == 4) {
    // Beta (for positive correlation)
    // Note: Beta is on [0,1], we map to correlation
    target += beta_lpdf((rho_raw + 1) / 2 | prior_rho_param, prior_rho_param2);
  } else if (prior_rho_type == 5) {
    // LKJ prior for correlation matrix
    matrix[2,2] R;
    R[1,1] = 1.0;
    R[2,2] = 1.0;
    R[1,2] = rho_raw;
    R[2,1] = rho_raw;
    target += lkj_corr_lpdf(R | prior_rho_param);
  }
  
  // Hierarchical model for trial effects
  for (n in 1:N) {
    theta[n] ~ multi_normal_cholesky(mu, L_Sigma);
  }
  
  // Likelihood: observed data given trial effects
  for (n in 1:N) {
    y[n] ~ multi_normal(theta[n], W[n]);
  }
}

generated quantities {
  // Output for easy access
  real rho_out = rho;                // Correlation parameter
  real theta_os_post = theta[N][1];  // Posterior mean for current trial OS
  real theta_pfs_post = theta[N][2]; // Posterior mean for current trial PFS
  real tau_os = tau[1];
  real tau_pfs = tau[2];
  
  // Probability of success calculations
  real<lower=0,upper=1> pos_os = theta_os_post < 0 ? 1 : 0;  // PoS for OS (HR < 1)
  real<lower=0,upper=1> pos_pfs = theta_pfs_post < 0 ? 1 : 0; // PoS for PFS (HR < 1)
}
