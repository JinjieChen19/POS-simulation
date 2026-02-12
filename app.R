# ============================================================================
# COMPREHENSIVE R SHINY APP FOR BAYESIAN PoS SIMULATION
# ============================================================================
# Interactive interface for running full Bayesian PoS model for OS
# Based on bayesian_pos_fixed current rho
# ============================================================================

library(shiny)
library(shinythemes)
library(tidyverse)
library(rstan)
library(bayesplot)
library(DT)
library(gridExtra)

# Set rstan options for better performance
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)

# ===========================================================================
# HELPER FUNCTIONS
# ===========================================================================

# Data preparation functions
prepare_historical_loghr_data <- function() {
  set.seed(20260211)
  
  # Generate realistic data with moderate between-trial correlation
  # Target: between-trial cor ~ 0.65, matching typical within-trial correlations
  
  n_trials <- 27
  
  # Use Cholesky decomposition for precise correlation control
  # Define population parameters
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
  
  # Cholesky decomposition
  L <- chol(cov_matrix)
  
  # Generate independent standard normal variates
  Z <- matrix(rnorm(2 * n_trials), nrow = 2, ncol = n_trials)
  
  # Transform to correlated variates
  Y <- t(L) %*% Z
  
  # Add means - Y[1,] is OS, Y[2,] is PFS (matching covariance matrix order)
  loghr_os <- mu_os + Y[1, ]
  loghr_pfs <- mu_pfs + Y[2, ]
  
  # Ensure reasonable ranges (gentle clipping to maintain realistic values)
  loghr_pfs <- pmax(pmin(loghr_pfs, -0.15), -0.75)
  loghr_os <- pmax(pmin(loghr_os, -0.05), -0.55)
  
  tibble(
    trial_id = paste0("ICB-HIST-", sprintf("%02d", 1:27)),
    cancer_type = rep(c("Melanoma", "NSCLC", "Renal", "HCC", "Bladder", "Gastric"), length.out = 27),
    n_patients = sample(95:200, 27, replace = TRUE),
    loghr_pfs = loghr_pfs,
    se_loghr_pfs = runif(27, 0.12, 0.18),  # Within-trial SE (measurement uncertainty)
    loghr_os = loghr_os,
    se_loghr_os = runif(27, 0.16, 0.22),   # Within-trial SE (measurement uncertainty)
    corr_pfs_os = runif(27, 0.60, 0.75)    # Within-trial correlations
  ) %>%
    mutate(cov_pfs_os = corr_pfs_os * se_loghr_pfs * se_loghr_os)
}

# Stan model builder with flexible priors
build_stan_model_improved <- function(prior_mu_os_mean = -0.35, prior_mu_os_sd = 1.0,
                                      prior_mu_pfs_mean = -0.45, prior_mu_pfs_sd = 1.0,
                                      prior_tau_type = "exponential", prior_tau_param_os = 1, prior_tau_param_pfs = 1,
                                      prior_rho_type = "uniform", prior_rho_param = 2, prior_rho_param2 = 1) {
  
  # Build tau priors based on selected distribution
  if (prior_tau_type == "exponential") {
    tau_prior_os <- paste0("tau_os ~ exponential(", prior_tau_param_os, ");")
    tau_prior_pfs <- paste0("tau_pfs ~ exponential(", prior_tau_param_pfs, ");")
  } else if (prior_tau_type == "half_normal") {
    tau_prior_os <- paste0("tau_os ~ normal(0, ", prior_tau_param_os, ");")
    tau_prior_pfs <- paste0("tau_pfs ~ normal(0, ", prior_tau_param_pfs, ");")
  }
  
  # Build rho prior based on selected distribution
  if (prior_rho_type == "uniform") {
    rho_declaration <- "real<lower=-0.95, upper=0.95> rho;"
    rho_prior <- "rho ~ uniform(-0.95, 0.95);"
  } else if (prior_rho_type == "uniform_positive") {
    # Informative prior assuming positive correlation
    rho_declaration <- "real<lower=0, upper=0.95> rho;"
    rho_prior <- "rho ~ uniform(0, 0.95);"
  } else if (prior_rho_type == "beta") {
    # Beta prior on (0, 1) for positive correlation
    # prior_rho_param is alpha, second param (beta_param) is beta
    rho_declaration <- "real<lower=0, upper=1> rho;"
    rho_prior <- paste0("rho ~ beta(", prior_rho_param, ", ", prior_rho_param2, ");")
  } else if (prior_rho_type == "lkj") {
    # For LKJ, we need to work with correlation matrix
    rho_declaration <- "real<lower=-1, upper=1> rho;"
    # LKJ approximation for bivariate case - we'll use a transformed beta distribution
    # This is a simplification; full LKJ would require matrix operations
    rho_prior <- paste0("// LKJ-inspired prior on correlation\n  ",
                       "target += (", prior_rho_param, " - 1) * log(1 - rho^2);")
  }
  
  stan_code <- paste0("
data {
  int<lower=1> K;                           // Number of historical trials
  vector[2] y_hist[K];                      // Observed log(HR) pairs
  matrix[2, 2] W_hist[K];                   // Within-trial covariance
  vector[2] y_curr;                         // Current trial data
  matrix[2, 2] W_curr;                      // Current trial covariance
  real loghr_os_target;                     // Target for success
}

parameters {
  // Population means
  real mu_os;
  real mu_pfs;
  
  // Between-trial heterogeneity (with lower bounds for stability)
  real<lower=0.001> tau_os;
  real<lower=0.001> tau_pfs;
  
  // Correlation
  ", rho_declaration, "
  
  // Non-centered parameterization for random effects
  vector[2] z_hist[K];                      // Standardized random effects
  vector[2] z_curr;                         // Standardized current trial effect
}

transformed parameters {
  // Between-trial covariance matrix
  matrix[2, 2] Sigma;
  Sigma[1, 1] = tau_os^2;
  Sigma[1, 2] = rho * tau_os * tau_pfs;
  Sigma[2, 1] = rho * tau_os * tau_pfs;
  Sigma[2, 2] = tau_pfs^2;
  
  // Cholesky decomposition (more numerically stable)
  matrix[2, 2] L_Sigma = cholesky_decompose(Sigma);
  
  // Population mean
  vector[2] mu = [mu_os, mu_pfs]';
  
  // Transform non-centered parameters to actual trial effects
  vector[2] theta_hist[K];
  for (k in 1:K) {
    theta_hist[k] = mu + L_Sigma * z_hist[k];
  }
  vector[2] theta_curr = mu + L_Sigma * z_curr;
}

model {
  // ========== PRIORS ==========
  
  // Population means: user-specified
  mu_os ~ normal(", prior_mu_os_mean, ", ", prior_mu_os_sd, ");
  mu_pfs ~ normal(", prior_mu_pfs_mean, ", ", prior_mu_pfs_sd, ");
  
  // Between-trial heterogeneity: user-specified
  ", tau_prior_os, "
  ", tau_prior_pfs, "
  
  // Correlation: user-specified
  ", rho_prior, "
  
  // Non-centered parameters: standard normal
  for (k in 1:K) {
    z_hist[k] ~ std_normal();
  }
  z_curr ~ std_normal();
  
  // ========== LIKELIHOOD ==========
  
  // Historical trials
  for (k in 1:K) {
    y_hist[k] ~ multi_normal(theta_hist[k], W_hist[k]);
  }
  
  // Current trial
  y_curr ~ multi_normal(theta_curr, W_curr);
}

generated quantities {
  // Posterior for current trial
  real theta_os_post = theta_curr[1];
  real theta_pfs_post = theta_curr[2];
  
  // HR scale
  real hr_os_pred = exp(theta_curr[1]);
  real hr_pfs_pred = exp(theta_curr[2]);
  
  // Probability of Success indicator
  int pos_indicator = (theta_os_post < loghr_os_target) ? 1 : 0;
}
")
  return(stan_code)
}

# Prepare Stan data
prepare_stan_data <- function(historical_trials, loghr_os_interim, se_loghr_os_interim,
                              loghr_pfs_interim, se_loghr_pfs_interim, loghr_os_target) {
  K <- nrow(historical_trials)
  
  y_hist <- list()
  W_hist <- list()
  
  for (i in 1:K) {
    y_hist[[i]] <- c(historical_trials$loghr_os[i], historical_trials$loghr_pfs[i])
    
    W_hist[[i]] <- matrix(c(
      historical_trials$se_loghr_os[i]^2,
      historical_trials$cov_pfs_os[i],
      historical_trials$cov_pfs_os[i],
      historical_trials$se_loghr_pfs[i]^2
    ), nrow = 2, ncol = 2)
  }
  
  y_curr <- c(loghr_os_interim, loghr_pfs_interim)
  
  corr_curr <- 0.60
  cov_curr <- corr_curr * se_loghr_os_interim * se_loghr_pfs_interim
  
  W_curr <- matrix(c(
    se_loghr_os_interim^2,
    cov_curr,
    cov_curr,
    se_loghr_pfs_interim^2
  ), nrow = 2, ncol = 2)
  
  list(
    K = K,
    y_hist = y_hist,
    W_hist = W_hist,
    y_curr = y_curr,
    W_curr = W_curr,
    loghr_os_target = loghr_os_target
  )
}

# ===========================================================================
# UI
# ===========================================================================

ui <- navbarPage(
  title = "Bayesian PoS Simulation - Overall Survival",
  theme = shinytheme("flatly"),
  
  # Tab 1: Model Description
  tabPanel("Model Description",
           fluidRow(
             column(12,
                    h2("Statistical Model Formulation"),
                    hr(),
                    h3("Hierarchical Bayesian Model for OS and PFS"),
                    p("This application implements a full Bayesian model for Probability of Success (PoS) assessment 
                      using log-transformed hazard ratios (log HR) for Overall Survival (OS) and Progression-Free Survival (PFS)."),
                    
                    h4("Model Structure"),
                    withMathJax(),
                    helpText("$$y_{k,j} \\sim N(\\theta_{k,j}, W_{k,j})$$"),
                    helpText("where \\(j = 1\\) represents OS and \\(j = 2\\) represents PFS"),
                    helpText("$$\\theta_k \\sim N(\\mu, \\Sigma)$$"),
                    
                    h4("Default Prior Specifications (Customizable)"),
                    p("The following priors can be adjusted in the 'Run Model' tab:"),
                    tags$ul(
                      tags$li(HTML("<strong>Population means:</strong>")),
                      tags$ul(
                        tags$li(HTML("μ<sub>OS</sub> ~ N(-0.35, 1.0) [Mean and SD adjustable]")),
                        tags$li(HTML("μ<sub>PFS</sub> ~ N(-0.45, 1.0) [Mean and SD adjustable]"))
                      ),
                      tags$li(HTML("<strong>Between-trial heterogeneity:</strong>")),
                      tags$ul(
                        tags$li(HTML("τ<sub>OS</sub> ~ Exp(2) or Half-Normal(0, σ) [Distribution and parameter adjustable]")),
                        tags$li(HTML("τ<sub>PFS</sub> ~ Exp(2) or Half-Normal(0, σ) [Distribution and parameter adjustable]"))
                      ),
                      tags$li(HTML("<strong>Correlation:</strong>")),
                      tags$ul(
                        tags$li(HTML("ρ ~ Uniform(-0.95, 0.95), Uniform(0, 0.95), Beta(α, β), or LKJ(η) [Distribution and parameter adjustable]")),
                        tags$li(HTML("<em>Informative option:</em> For oncology trials where positive correlation is expected, use Uniform(0, 0.95) or Beta priors"))
                      )
                    ),
                    
                    h4("Between-Trial Covariance Matrix"),
                    helpText("$$\\Sigma = \\begin{bmatrix} \\tau_{OS}^2 & \\rho \\tau_{OS} \\tau_{PFS} \\\\ \\rho \\tau_{OS} \\tau_{PFS} & \\tau_{PFS}^2 \\end{bmatrix}$$"),
                    
                    h4("Non-Centered Parameterization"),
                    p("To improve MCMC convergence and reduce divergent transitions, the model uses non-centered parameterization:"),
                    helpText("$$\\theta_k = \\mu + L_{\\Sigma} z_k$$"),
                    helpText("where \\(z_k \\sim N(0, I)\\) and \\(L_{\\Sigma}\\) is the Cholesky decomposition of \\(\\Sigma\\)"),
                    
                    h4("Likelihood Structure"),
                    tags$ul(
                      tags$li(HTML("<strong>Historical trials:</strong> Data from K completed trials inform the population parameters (default K=27)")),
                      tags$li(HTML("<strong>Current trial:</strong> Interim data from the ongoing trial, combined with historical information via Bayesian shrinkage"))
                    ),
                    
                    h4("How is ρ (Between-Trial Correlation) Estimated?"),
                    div(style="background-color: #f0f8ff; padding: 15px; border-left: 4px solid #4682b4; margin: 10px 0;",
                      p(strong("Key Question:"), "How can we estimate ρ from historical trials alone, without the current trial?"),
                      p(strong("Answer:"), "Each historical trial provides a ", strong("bivariate observation"), 
                        " (log HR for OS, log HR for PFS). With K=27 trials, we have 27 pairs of (OS, PFS) values."),
                      p("The model learns:"),
                      tags$ol(
                        tags$li("Population means (μ_OS, μ_PFS) from the average of all trials"),
                        tags$li("Each trial's deviation from these means"),
                        tags$li(HTML("<strong>The correlation of these deviations = ρ</strong>"))
                      ),
                      p(strong("Example pattern:")),
                      tags$ul(
                        tags$li("Trial with better-than-average OS also has better-than-average PFS → Positive ρ"),
                        tags$li("Trial with better OS has worse PFS → Negative ρ"),
                        tags$li("OS and PFS deviations unrelated → ρ ≈ 0")
                      ),
                      p(strong("Impact of current trial:"), "With 27 historical trials, the current trial adds only 1/28 = 3.6% of information about ρ."),
                      p(HTML("📖 <strong>Detailed explanation:</strong> See <a href='https://github.com/JinjieChen19/POS-simulation/blob/main/HOW_RHO_IS_ESTIMATED.md' target='_blank'>HOW_RHO_IS_ESTIMATED.md</a> for complete technical details."))
                    ),
                    
                    h4("Probability of Success (PoS)"),
                    p("The PoS is calculated as:"),
                    helpText("$$PoS = P(\\theta_{OS,current} < \\text{target} | \\text{data})$$"),
                    p("This represents the posterior probability that the current trial's OS log(HR) will meet the success criterion."),
                    
                    h4("Customizable Features"),
                    p(strong("New in this version:")),
                    tags$ul(
                      tags$li("Adjustable MCMC parameters (adapt_delta, max_treedepth)"),
                      tags$li("27 historical trials for more robust estimation"),
                      tags$li("Flexible prior distributions for all model parameters"),
                      tags$li("Choice of Exponential or Half-Normal priors for heterogeneity"),
                      tags$li("Choice of Uniform, Uniform(positive), Beta, or LKJ priors for correlation"),
                      tags$li("Informative positive priors for ρ when expecting positive correlation (typical in oncology)")
                    )
             )
           )
  ),
  
  # Tab 2: Interactive Model Execution
  tabPanel("Run Model",
           sidebarLayout(
             sidebarPanel(
               h3("MCMC Settings"),
               numericInput("n_iter", "MCMC Iterations:", value = 4000, min = 1000, max = 10000, step = 500),
               numericInput("n_chains", "Number of Chains:", value = 4, min = 1, max = 8),
               numericInput("adapt_delta", "Adapt Delta:", value = 0.99, min = 0.8, max = 0.9999, step = 0.01),
               numericInput("max_treedepth", "Max Tree Depth:", value = 12, min = 10, max = 15, step = 1),
               hr(),
               h3("Prior Settings"),
               h4("Population Means"),
               numericInput("prior_mu_os_mean", "μ_OS Prior Mean:", value = -0.35, step = 0.05),
               numericInput("prior_mu_os_sd", "μ_OS Prior SD:", value = 1.0, min = 0.1, step = 0.1),
               numericInput("prior_mu_pfs_mean", "μ_PFS Prior Mean:", value = -0.45, step = 0.05),
               numericInput("prior_mu_pfs_sd", "μ_PFS Prior SD:", value = 1.0, min = 0.1, step = 0.1),
               h4("Between-Trial Heterogeneity"),
               selectInput("prior_tau_type", "Distribution:",
                          choices = c("Exponential" = "exponential", "Half-Normal" = "half_normal"),
                          selected = "exponential"),
               numericInput("prior_tau_param_os", "τ_OS Parameter:", value = 1, min = 0.1, step = 0.1),
               numericInput("prior_tau_param_pfs", "τ_PFS Parameter:", value = 1, min = 0.1, step = 0.1),
               helpText("For Exponential(rate): mean = 1/rate. RECOMMENDED: rate=1 (mean=1.0) to avoid over-shrinkage. For Half-Normal(SD): use SD >= 1.0."),
               h4("Correlation"),
               selectInput("prior_rho_type", "Distribution:",
                          choices = c("Uniform(-0.95, 0.95)" = "uniform", 
                                    "Uniform(0, 0.95) - Positive Only" = "uniform_positive",
                                    "Beta(α, β) - Positive Only" = "beta",
                                    "LKJ" = "lkj"),
                          selected = "uniform"),
               conditionalPanel(
                 condition = "input.prior_rho_type == 'beta'",
                 numericInput("prior_rho_param", "Beta α Parameter:", value = 2, min = 0.5, step = 0.5),
                 numericInput("prior_rho_param2", "Beta β Parameter:", value = 1, min = 0.5, step = 0.5),
                 helpText("Beta(2,1): weakly favors high positive correlation. Beta(5,1): strongly favors high positive correlation. Beta(2,2): favors moderate positive correlation around 0.5.")
               ),
               conditionalPanel(
                 condition = "input.prior_rho_type == 'lkj'",
                 numericInput("prior_rho_param", "LKJ η Parameter:", value = 2, min = 1, step = 0.5)
               ),
               helpText("For informative priors assuming positive correlation (typical in oncology), use Uniform(0, 0.95) or Beta priors."),
               hr(),
               h3("Current Trial Parameters"),
               div(style = "background-color: #e8f4f8; padding: 10px; border-radius: 5px; margin-bottom: 15px;",
                   p(style = "margin: 0;", 
                     strong("ℹ️ Note:"), 
                     "Both OS and PFS interim data are used, even if OS is immature. ",
                     "Large SE for immature OS appropriately reduces its weight in the Bayesian model.")
               ),
               numericInput("loghr_os_interim", "Interim log(HR) for OS:", value = -0.35, step = 0.01),
               helpText("OS can be immature - increase SE to reflect uncertainty from fewer events"),
               numericInput("se_loghr_os_interim", "SE of log(HR) for OS:", value = 0.25, min = 0.01, step = 0.01),
               numericInput("loghr_pfs_interim", "Interim log(HR) for PFS:", value = -0.48, step = 0.01),
               numericInput("se_loghr_pfs_interim", "SE of log(HR) for PFS:", value = 0.12, min = 0.01, step = 0.01),
               numericInput("loghr_os_target", "Target log(HR) for Success:", value = -0.30, step = 0.01),
               hr(),
               actionButton("run_model", "Run Stan Model", class = "btn-primary btn-lg", icon = icon("play")),
               hr(),
               p("Note: Model execution may take several minutes depending on the number of iterations and chains.")
             ),
             mainPanel(
               h3("Model Execution"),
               verbatimTextOutput("model_output"),
               hr(),
               h3("MCMC Diagnostics"),
               verbatimTextOutput("diagnostics_output")
             )
           )
  ),
  
  # Tab 3: Results Visualization
  tabPanel("Results",
           fluidRow(
             column(12,
                    h3("Posterior Results"),
                    hr()
             )
           ),
           fluidRow(
             column(6,
                    h4("Posterior Distribution: OS log(HR)"),
                    plotOutput("plot_loghr_posterior", height = "400px")
             ),
             column(6,
                    h4("Posterior Distribution: HR (Natural Scale)"),
                    plotOutput("plot_hr_posterior", height = "400px")
             )
           ),
           fluidRow(
             column(6,
                    h4("Probability of Success"),
                    plotOutput("plot_pos", height = "400px")
             ),
             column(6,
                    h4("Population Parameters"),
                    plotOutput("plot_population_params", height = "400px")
             )
           ),
           fluidRow(
             column(12,
                    h4("Summary Statistics"),
                    verbatimTextOutput("summary_stats")
             )
           ),
           fluidRow(
             column(12,
                    h4("MCMC Trace Plots"),
                    plotOutput("trace_plots", height = "600px")
             )
           )
  ),
  
  # Tab 4: Data Management
  tabPanel("Data",
           fluidRow(
             column(12,
                    h3("Historical Trials Data"),
                    p("The model uses data from 27 historical immunotherapy trials:"),
                    DTOutput("historical_data_table"),
                    hr(),
                    h3("Summary Statistics"),
                    verbatimTextOutput("data_summary")
             )
           )
  ),
  
  # Tab 5: Help
  tabPanel("Help",
           fluidRow(
             column(12,
                    h2("User Guide"),
                    hr(),
                    h3("Getting Started"),
                    p("This Shiny application provides an interactive interface for running Bayesian Probability of Success (PoS) 
                      analysis for clinical trials using Overall Survival (OS) and Progression-Free Survival (PFS) data."),
                    
                    h3("How to Use"),
                    tags$ol(
                      tags$li(HTML("<strong>Review the Model:</strong> Start with the 'Model Description' tab to understand the statistical framework")),
                      tags$li(HTML("<strong>View Historical Data:</strong> Check the 'Data' tab to see the historical trials used for informing the model")),
                      tags$li(HTML("<strong>Set Parameters:</strong> Go to 'Run Model' and adjust the current trial parameters and MCMC settings")),
                      tags$li(HTML("<strong>Execute Model:</strong> Click 'Run Stan Model' to perform the Bayesian analysis")),
                      tags$li(HTML("<strong>Review Results:</strong> Navigate to 'Results' to see posterior distributions, PoS assessment, and diagnostics"))
                    ),
                    
                    h3("Key Features"),
                    tags$ul(
                      tags$li(HTML("<strong>Non-centered parameterization:</strong> Improves MCMC convergence and reduces divergent transitions")),
                      tags$li(HTML("<strong>Adaptive MCMC:</strong> Uses adapt_delta = 0.99 and max_treedepth = 12 for robust sampling")),
                      tags$li(HTML("<strong>Parallel processing:</strong> Automatically detects and uses available CPU cores")),
                      tags$li(HTML("<strong>Real-time diagnostics:</strong> Monitors convergence with R-hat and effective sample size"))
                    ),
                    
                    h3("Interpreting Results"),
                    tags$ul(
                      tags$li(HTML("<strong>PoS ≥ 0.90:</strong> VERY HIGH - Trial very likely to succeed")),
                      tags$li(HTML("<strong>PoS ≥ 0.70:</strong> HIGH - Trial likely to succeed")),
                      tags$li(HTML("<strong>PoS ≥ 0.50:</strong> MODERATE - Trial may succeed")),
                      tags$li(HTML("<strong>PoS < 0.50:</strong> LOW - Trial unlikely to succeed"))
                    ),
                    
                    h3("Understanding Between-Trial Correlation (ρ)"),
                    p(HTML("<strong>Important:</strong> The model estimates a between-trial correlation parameter (ρ) 
                          that is different from within-trial correlation!")),
                    
                    h4("How is ρ estimated from historical trials?"),
                    div(style="background-color: #fffacd; padding: 10px; border-left: 3px solid #ffa500; margin: 10px 0;",
                      p(strong("Key insight:"), "ρ is estimated from the pattern of trial-level co-variation in historical data alone."),
                      p("Each historical trial provides a ", strong("bivariate observation"), " (log HR for OS, log HR for PFS). 
                        With 27 historical trials, we have 27 pairs."),
                      p(strong("The model learns:")),
                      tags$ol(
                        tags$li("Population means (μ_OS, μ_PFS)"),
                        tags$li("Each trial's deviation from these means"),
                        tags$li("The correlation of these deviations = ρ")
                      ),
                      p(strong("Current trial impact:"), "Only 1/28 = 3.6% of information about ρ. Historical data provides 96.4%."),
                      p(HTML("📖 <strong>Full details:</strong> <a href='https://github.com/JinjieChen19/POS-simulation/blob/main/HOW_RHO_IS_ESTIMATED.md' target='_blank'>HOW_RHO_IS_ESTIMATED.md</a>"))
                    ),
                    
                    h4("What is ρ?"),
                    p("Between-trial correlation (ρ) measures how trial-level effects correlate across endpoints. 
                      For example, do trials with better-than-average PFS also tend to have better-than-average OS?"),
                    
                    h4("Why might ρ be low?"),
                    tags$ul(
                      tags$li("Different patient populations across trials"),
                      tags$li("Varying post-progression treatments"),
                      tags$li("Different biological mechanisms for PFS vs OS benefit"),
                      tags$li("This is often realistic and data-driven!")
                    ),
                    
                    h4("What information is still borrowed with low ρ?"),
                    p(HTML("<strong>Even with ρ = 0, historical data provides substantial value:</strong>")),
                    tags$ul(
                      tags$li(HTML("<strong>Population means (μ):</strong> Average treatment effects across trials")),
                      tags$li(HTML("<strong>Heterogeneity (τ):</strong> How much trials vary, calibrating uncertainty")),
                      tags$li(HTML("<strong>Hierarchical shrinkage:</strong> Prevents overfitting, reduces noise")),
                      tags$li(HTML("<strong>Better uncertainty:</strong> More realistic credible intervals"))
                    ),
                    
                    p(HTML("<strong>Only affected by low ρ:</strong>")),
                    tags$ul(
                      tags$li(HTML("<strong>Cross-endpoint borrowing:</strong> Cannot use PFS to predict OS when ρ ≈ 0")),
                      tags$li(HTML("PoS relies mainly on OS data itself, not PFS"))
                    ),
                    
                    p(HTML("📖 <strong>For detailed explanation:</strong> See 
                          <a href='https://github.com/JinjieChen19/POS-simulation/blob/main/UNDERSTANDING_CORRELATION.md' target='_blank'>UNDERSTANDING_CORRELATION.md</a> 
                          in the repository.")),
                    
                    h3("🔍 FAQ: Does the Model Use Immature OS?"),
                    div(style="background-color: #e8f4f8; padding: 15px; border-left: 4px solid #0066cc; margin: 15px 0;",
                      h4(style="margin-top: 0;", "Q: Do we incorporate current trial's OS (even if not mature)?"),
                      p(HTML("<strong style='color: #0066cc;'>YES!</strong> The model DOES use the current trial's OS, even if immature.")),
                      
                      p(strong("How it works:")),
                      tags$ul(
                        tags$li(HTML("Model uses <strong>BOTH</strong> OS and PFS from current trial")),
                        tags$li(HTML("Immature OS has <strong>larger SE</strong> (fewer events = more uncertainty)")),
                        tags$li(HTML("Bayesian inference automatically <strong>down-weights</strong> imprecise data (via SE)")),
                        tags$li(HTML("Even with few OS events, data still contributes (weight ∝ 1/SE²)"))
                      ),
                      
                      p(strong("Example:")),
                      tags$ul(
                        tags$li(HTML("50 OS events → SE ≈ 0.30 → contributes ~15% of posterior")),
                        tags$li(HTML("100 OS events → SE ≈ 0.20 → contributes ~30% of posterior")),
                        tags$li(HTML("200 OS events → SE ≈ 0.15 → contributes ~45% of posterior"))
                      ),
                      
                      p(strong("Why include immature OS?")),
                      tags$ul(
                        tags$li("Prevents over-reliance on PFS alone"),
                        tags$li("Provides reality check on PFS-OS relationship"),
                        tags$li("Even weak signal better than ignoring OS completely"),
                        tags$li("Bayesian optimality: use ALL data, weighted by precision")
                      ),
                      
                      p(HTML("📖 <strong>Complete answer with examples:</strong> 
                            <a href='https://github.com/JinjieChen19/POS-simulation/blob/main/FAQ_CURRENT_TRIAL_OS.md' target='_blank'>FAQ_CURRENT_TRIAL_OS.md</a>"))
                    ),
                    
                    h3("Technical Notes"),
                    tags$ul(
                      tags$li("The model uses rstan for Bayesian inference with Hamiltonian Monte Carlo (HMC)"),
                      tags$li("Default settings: 4000 iterations (2000 warmup + 2000 sampling) × 4 chains"),
                      tags$li("R-hat values should be < 1.01 for convergence"),
                      tags$li("Effective sample size (ESS) should be > 100 per chain")
                    )
             )
           )
  )
)

# ===========================================================================
# SERVER
# ===========================================================================

server <- function(input, output, session) {
  
  # Load historical data
  historical_data <- prepare_historical_loghr_data()
  
  # Reactive values to store results
  results <- reactiveValues(
    fit = NULL,
    posterior_samples = NULL,
    summary = NULL
  )
  
  # Display historical data
  output$historical_data_table <- renderDT({
    historical_data %>%
      select(trial_id, cancer_type, n_patients, loghr_os, se_loghr_os, loghr_pfs, se_loghr_pfs, corr_pfs_os) %>%
      mutate(across(starts_with("loghr"), ~round(., 3)),
             across(starts_with("se_"), ~round(., 3)),
             across(starts_with("corr"), ~round(., 3))) %>%
      datatable(options = list(pageLength = 10, scrollX = TRUE))
  })
  
  # Data summary
  output$data_summary <- renderPrint({
    cat("Historical Trials Summary\n")
    cat(strrep("=", 60), "\n\n")
    cat("Number of trials: ", nrow(historical_data), "\n")
    cat("Cancer types: ", paste(unique(historical_data$cancer_type), collapse = ", "), "\n\n")
    cat("OS log(HR) - Mean:", round(mean(historical_data$loghr_os), 3), 
        "SD:", round(sd(historical_data$loghr_os), 3), "\n")
    cat("PFS log(HR) - Mean:", round(mean(historical_data$loghr_pfs), 3), 
        "SD:", round(sd(historical_data$loghr_pfs), 3), "\n\n")
    
    # Calculate and display between-trial correlation
    between_trial_cor <- cor(historical_data$loghr_pfs, historical_data$loghr_os)
    cat("CORRELATIONS:\n")
    cat("  Between-trial cor(PFS, OS): ", round(between_trial_cor, 3), 
        " <- This is what the model learns as rho\n")
    cat("  Within-trial cor (average): ", round(mean(historical_data$corr_pfs_os), 3), 
        " <- Patient-level correlation within trials\n")
  })
  
  # Run model
  observeEvent(input$run_model, {
    
    # Prepare Stan data
    stan_data <- prepare_stan_data(
      historical_data,
      input$loghr_os_interim,
      input$se_loghr_os_interim,
      input$loghr_pfs_interim,
      input$se_loghr_pfs_interim,
      input$loghr_os_target
    )
    
    # Show progress
    output$model_output <- renderPrint({
      cat("Compiling Stan model...\n")
      cat("This may take a moment on first run.\n\n")
    })
    
    # Compile and run model
    withProgress(message = 'Running Stan model...', value = 0, {
      
      incProgress(0.1, detail = "Compiling model")
      
      # Build Stan model with user-specified priors
      stan_code <- build_stan_model_improved(
        prior_mu_os_mean = input$prior_mu_os_mean,
        prior_mu_os_sd = input$prior_mu_os_sd,
        prior_mu_pfs_mean = input$prior_mu_pfs_mean,
        prior_mu_pfs_sd = input$prior_mu_pfs_sd,
        prior_tau_type = input$prior_tau_type,
        prior_tau_param_os = input$prior_tau_param_os,
        prior_tau_param_pfs = input$prior_tau_param_pfs,
        prior_rho_type = input$prior_rho_type,
        prior_rho_param = ifelse(input$prior_rho_type %in% c("lkj", "beta"), input$prior_rho_param, 2),
        prior_rho_param2 = ifelse(input$prior_rho_type == "beta", input$prior_rho_param2, 1)
      )
      
      incProgress(0.2, detail = "Starting MCMC sampling")
      
      output$model_output <- renderPrint({
        cat(strrep("=", 80), "\n")
        cat("BAYESIAN PoS MODEL FOR OS USING LOG(HR)\n")
        cat("rstan with Non-Centered Parameterization\n")
        cat(strrep("=", 80), "\n\n")
        cat("Model settings:\n")
        cat("  Iterations per chain:", input$n_iter, "\n")
        cat("  Warmup:", input$n_iter/2, "\n")
        cat("  Sampling:", input$n_iter/2, "\n")
        cat("  Chains:", input$n_chains, "\n")
        cat("  Adapt delta:", input$adapt_delta, "\n")
        cat("  Max treedepth:", input$max_treedepth, "\n\n")
        cat("Prior settings:\n")
        cat("  μ_OS ~ N(", input$prior_mu_os_mean, ", ", input$prior_mu_os_sd, ")\n", sep="")
        cat("  μ_PFS ~ N(", input$prior_mu_pfs_mean, ", ", input$prior_mu_pfs_sd, ")\n", sep="")
        if (input$prior_tau_type == "exponential") {
          cat("  τ_OS ~ Exp(", input$prior_tau_param_os, ")\n", sep="")
          cat("  τ_PFS ~ Exp(", input$prior_tau_param_pfs, ")\n", sep="")
        } else {
          cat("  τ_OS ~ Half-N(0, ", input$prior_tau_param_os, ")\n", sep="")
          cat("  τ_PFS ~ Half-N(0, ", input$prior_tau_param_pfs, ")\n", sep="")
        }
        if (input$prior_rho_type == "uniform") {
          cat("  ρ ~ Uniform(-0.95, 0.95)\n")
        } else if (input$prior_rho_type == "uniform_positive") {
          cat("  ρ ~ Uniform(0, 0.95) [positive only]\n")
        } else if (input$prior_rho_type == "beta") {
          cat("  ρ ~ Beta(", input$prior_rho_param, ", ", input$prior_rho_param2, ") [positive only]\n", sep="")
        } else {
          cat("  ρ ~ LKJ-inspired(η=", input$prior_rho_param, ")\n", sep="")
        }
        cat("\nCurrent trial parameters:\n")
        cat("  OS log(HR):", input$loghr_os_interim, "± SE:", input$se_loghr_os_interim, "\n")
        cat("  PFS log(HR):", input$loghr_pfs_interim, "± SE:", input$se_loghr_pfs_interim, "\n")
        cat("  Target log(HR):", input$loghr_os_target, "\n\n")
        cat("Running MCMC sampling...\n")
        cat("This may take several minutes. Please wait.\n\n")
      })
      
      # Fit model with user-specified MCMC controls
      fit <- stan(
        model_code = stan_code,
        data = stan_data,
        iter = input$n_iter,
        warmup = input$n_iter / 2,
        chains = input$n_chains,
        cores = min(input$n_chains, parallel::detectCores()),
        seed = 2026,
        verbose = FALSE,
        refresh = 0,
        control = list(
          adapt_delta = input$adapt_delta,
          max_treedepth = input$max_treedepth
        )
      )
      
      incProgress(0.7, detail = "Extracting results")
      
      # Extract posterior samples
      posterior_samples <- rstan::extract(fit)
      
      # Store results
      results$fit <- fit
      results$posterior_samples <- posterior_samples
      
      # Calculate summary
      mu_os <- mean(posterior_samples$mu_os)
      mu_pfs <- mean(posterior_samples$mu_pfs)
      tau_os <- mean(posterior_samples$tau_os)
      tau_pfs <- mean(posterior_samples$tau_pfs)
      rho <- mean(posterior_samples$rho)
      theta_os <- posterior_samples$theta_os_post
      pos_prob <- mean(posterior_samples$pos_indicator)
      
      results$summary <- list(
        mu_os = mu_os, mu_pfs = mu_pfs,
        tau_os = tau_os, tau_pfs = tau_pfs,
        rho = rho, theta_os = theta_os,
        pos_probability = pos_prob,
        target = input$loghr_os_target
      )
      
      incProgress(1.0, detail = "Complete!")
      
      # Update output
      output$model_output <- renderPrint({
        cat(strrep("=", 80), "\n")
        cat("MODEL EXECUTION COMPLETE\n")
        cat(strrep("=", 80), "\n\n")
        cat("Model ran successfully!\n")
        cat("Total posterior samples:", length(theta_os), "\n\n")
        cat("Navigate to the 'Results' tab to view detailed outputs.\n")
      })
      
      # Show diagnostics
      output$diagnostics_output <- renderPrint({
        cat(strrep("=", 80), "\n")
        cat("MCMC DIAGNOSTICS\n")
        cat(strrep("=", 80), "\n\n")
        print(fit, probs = c(0.025, 0.5, 0.975),
              pars = c("mu_os", "mu_pfs", "tau_os", "tau_pfs", "rho", "theta_os_post"))
      })
    })
  })
  
  # Plot: Posterior log(HR)
  output$plot_loghr_posterior <- renderPlot({
    req(results$posterior_samples)
    
    theta_os_samples <- results$posterior_samples$theta_os_post
    
    tibble(theta_os = theta_os_samples) %>%
      ggplot(aes(x = theta_os)) +
      geom_histogram(bins = 50, fill = "#4682B4", alpha = 0.7, aes(y = after_stat(density))) +
      geom_density(color = "#00008B", linewidth = 1) +
      geom_vline(aes(xintercept = mean(theta_os)), color = "#00008B", linetype = "dashed", linewidth = 1) +
      geom_vline(aes(xintercept = results$summary$target), color = "red", linetype = "dashed", linewidth = 1) +
      labs(title = "Posterior: OS log(HR) - Current Trial",
           subtitle = "Dashed blue = Posterior mean, Dashed red = Target",
           x = "log(HR)", y = "Density") +
      theme_minimal(base_size = 14)
  })
  
  # Plot: Posterior HR
  output$plot_hr_posterior <- renderPlot({
    req(results$posterior_samples)
    
    theta_os_samples <- results$posterior_samples$theta_os_post
    
    tibble(hr_os = exp(theta_os_samples)) %>%
      ggplot(aes(x = hr_os)) +
      geom_histogram(bins = 50, fill = "#3CB371", alpha = 0.7, aes(y = after_stat(density))) +
      geom_density(color = "#228B22", linewidth = 1) +
      geom_vline(aes(xintercept = 1), color = "black", linetype = "dotted", linewidth = 1) +
      geom_vline(aes(xintercept = exp(results$summary$target)), color = "red", linetype = "dashed", linewidth = 1) +
      labs(title = "Posterior: OS Hazard Ratio",
           subtitle = "Dotted black = No effect (HR=1), Dashed red = Target",
           x = "HR", y = "Density") +
      theme_minimal(base_size = 14)
  })
  
  # Plot: PoS
  output$plot_pos <- renderPlot({
    req(results$summary)
    
    pos_prob <- results$summary$pos_probability
    
    # Determine color based on PoS level
    pos_color <- if (pos_prob >= 0.90) "#00AA00" 
    else if (pos_prob >= 0.70) "#88CC00"
    else if (pos_prob >= 0.50) "#FFAA00"
    else "#FF4444"
    
    tibble(
      Metric = c("PoS", "Reference: Moderate (50%)", "Reference: High (70%)", "Reference: Very High (90%)"),
      Probability = c(pos_prob, 0.50, 0.70, 0.90),
      Type = c("Current", "Reference", "Reference", "Reference")
    ) %>%
      ggplot(aes(x = reorder(Metric, Probability), y = Probability, fill = Type)) +
      geom_col(alpha = 0.8) +
      geom_text(aes(label = sprintf("%.1f%%", Probability * 100)), 
                hjust = -0.2, size = 5, fontface = "bold") +
      coord_flip() +
      scale_fill_manual(values = c("Current" = pos_color, "Reference" = "#CCCCCC")) +
      ylim(0, 1) +
      labs(title = "Probability of Success Assessment",
           x = "", y = "Probability") +
      theme_minimal(base_size = 14) +
      theme(legend.position = "none")
  })
  
  # Plot: Population parameters
  output$plot_population_params <- renderPlot({
    req(results$summary)
    
    tibble(
      Parameter = c("μ_OS", "μ_PFS", "τ_OS", "τ_PFS", "ρ"),
      Value = c(results$summary$mu_os, results$summary$mu_pfs,
                results$summary$tau_os, results$summary$tau_pfs,
                results$summary$rho),
      Type = c("Mean", "Mean", "Heterogeneity", "Heterogeneity", "Correlation")
    ) %>%
      ggplot(aes(x = reorder(Parameter, Value), y = Value, fill = Type)) +
      geom_col(alpha = 0.7) +
      geom_text(aes(label = round(Value, 3)), hjust = -0.2, size = 5) +
      coord_flip() +
      scale_fill_brewer(palette = "Set2") +
      labs(title = "Population Parameter Estimates",
           x = "", y = "Posterior Mean") +
      theme_minimal(base_size = 14) +
      theme(legend.position = "bottom")
  })
  
  # Summary statistics
  output$summary_stats <- renderPrint({
    req(results$summary)
    
    theta_os <- results$summary$theta_os
    pos_prob <- results$summary$pos_probability
    
    cat(strrep("=", 80), "\n")
    cat("POSTERIOR SUMMARY\n")
    cat(strrep("=", 80), "\n\n")
    
    cat("POPULATION PARAMETERS:\n")
    cat("  μ_OS (mean log HR for OS):      ", round(results$summary$mu_os, 4), "\n")
    cat("  μ_PFS (mean log HR for PFS):    ", round(results$summary$mu_pfs, 4), "\n")
    cat("  τ_OS (between-trial SD):        ", round(results$summary$tau_os, 4), "\n")
    cat("  τ_PFS (between-trial SD):       ", round(results$summary$tau_pfs, 4), "\n")
    cat("  ρ (OS-PFS correlation):         ", round(results$summary$rho, 4), "\n\n")
    
    cat("CURRENT TRIAL POSTERIOR:\n")
    cat("  E[θ_OS | data]:                 ", round(mean(theta_os), 4), "\n")
    cat("  95% Credible Interval:          [", round(quantile(theta_os, 0.025), 4), ", ",
        round(quantile(theta_os, 0.975), 4), "]\n")
    cat("  Median (log HR):                ", round(median(theta_os), 4), "\n")
    cat("  HR scale - Mean:                ", round(exp(mean(theta_os)), 3), "\n")
    cat("  HR scale - Median:              ", round(exp(median(theta_os)), 3), "\n\n")
    
    cat("PROBABILITY OF SUCCESS:\n")
    cat("  Target log(HR):                 ", round(results$summary$target, 4), "\n")
    cat("  Equivalent HR:                  ", round(exp(results$summary$target), 3), "\n")
    cat("  P(log(HR_OS) < target | data):  ", round(pos_prob, 4), " (", round(pos_prob * 100, 1), "%)\n\n")
    
    if (pos_prob >= 0.90) {
      cat("  PoS Assessment: ★★★ VERY HIGH - Trial very likely to succeed\n\n")
    } else if (pos_prob >= 0.70) {
      cat("  PoS Assessment: ★★ HIGH - Trial likely to succeed\n\n")
    } else if (pos_prob >= 0.50) {
      cat("  PoS Assessment: ★ MODERATE - Trial may succeed\n\n")
    } else {
      cat("  PoS Assessment: ✗ LOW - Trial unlikely to succeed\n\n")
    }
    
    cat(strrep("=", 80), "\n")
  })
  
  # Trace plots
  output$trace_plots <- renderPlot({
    req(results$fit)
    
    # Create trace plots for key parameters
    mcmc_trace(results$fit, pars = c("mu_os", "mu_pfs", "tau_os", "tau_pfs", "rho", "theta_os_post")) +
      labs(title = "MCMC Trace Plots - Convergence Diagnostics") +
      theme_minimal(base_size = 12)
  })
}

# ===========================================================================
# RUN APP
# ===========================================================================

shinyApp(ui = ui, server = server)
