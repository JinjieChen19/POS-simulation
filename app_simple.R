# ============================================================================
# SIMPLIFIED R SHINY APP FOR BAYESIAN PoS SIMULATION
# ============================================================================
# Interactive interface for running Bayesian PoS model for OS
# Simplified version without Help and Model Description tabs
# Core functionality: Run Model, Results, Scatter Plot, and Data tabs
# ============================================================================

library(shiny)
library(shinythemes)
library(tidyverse)
library(rstan)
library(bayesplot)
library(DT)
library(gridExtra)
library(MASS)

# Set rstan options for better performance
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)

# ===========================================================================
# HELPER FUNCTIONS
# ===========================================================================

# ===========================================================================
# Fisher-z prior calculation for informative rho prior
# Target: rho 95% interval ~ [0.35, 0.80]
# ===========================================================================
rho_L <- 0.35
rho_U <- 0.80
mu_z_default <- (atanh(rho_L) + atanh(rho_U)) / 2
sd_z_default <- (atanh(rho_U) - atanh(rho_L)) / (2 * 1.96)

# Data preparation function - Updated to match new simulation algorithm
# Now accepts parameters for customization
prepare_historical_loghr_data <- function(seed = 20260212,
                                          mu_os = -0.30, mu_pfs = -0.45,
                                          tau_os = 0.15, tau_pfs = 0.15,
                                          rho_true = 0.65,
                                          se_os_min = 0.10, se_os_max = 0.13,
                                          se_pfs_min = 0.08, se_pfs_max = 0.11,
                                          rho_within_min = 0.55, rho_within_max = 0.75) {
  set.seed(seed)
  
  K <- 27
  
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

# Stan model builder with flexible priors
build_stan_model_improved <- function(prior_mu_os_mean = -0.35, prior_mu_os_sd = 1.0,
                                      prior_mu_pfs_mean = -0.45, prior_mu_pfs_sd = 1.0,
                                      prior_tau_type = "exponential", prior_tau_param_os = 1, prior_tau_param_pfs = 1,
                                      prior_rho_type = "fisher_z", prior_rho_param = 0, prior_rho_param2 = 1.5) {
  
  # Build tau priors based on selected distribution
  if (prior_tau_type == "exponential") {
    tau_prior_os <- paste0("tau_os ~ exponential(", prior_tau_param_os, ");")
    tau_prior_pfs <- paste0("tau_pfs ~ exponential(", prior_tau_param_pfs, ");")
  } else if (prior_tau_type == "half_normal") {
    tau_prior_os <- paste0("tau_os ~ normal(0, ", prior_tau_param_os, ");")
    tau_prior_pfs <- paste0("tau_pfs ~ normal(0, ", prior_tau_param_pfs, ");")
  }
  
  # Build rho prior based on selected distribution
  if (prior_rho_type == "fisher_z") {
    # Fisher z-transformation: z = atanh(ρ), ρ = tanh(z)
    # This provides better sampling geometry and reduces shrinkage to 0
    rho_declaration <- "real z_rho;  // Fisher z-transformed correlation"
    rho_transform <- "  real rho = tanh(z_rho);  // Back-transform to correlation"
    rho_prior <- paste0("z_rho ~ normal(", prior_rho_param, ", ", prior_rho_param2, ");  // Prior on Fisher z scale")
  } else if (prior_rho_type == "uniform") {
    rho_declaration <- "real<lower=-0.95, upper=0.95> rho;"
    rho_transform <- ""
    rho_prior <- "rho ~ uniform(-0.95, 0.95);"
  } else if (prior_rho_type == "uniform_positive") {
    # Informative prior assuming positive correlation
    rho_declaration <- "real<lower=0, upper=0.95> rho;"
    rho_transform <- ""
    rho_prior <- "rho ~ uniform(0, 0.95);"
  } else if (prior_rho_type == "beta") {
    # Beta prior on (0, 1) for positive correlation
    # prior_rho_param is alpha, second param (beta_param) is beta
    rho_declaration <- "real<lower=0, upper=1> rho;"
    rho_transform <- ""
    rho_prior <- paste0("rho ~ beta(", prior_rho_param, ", ", prior_rho_param2, ");")
  } else if (prior_rho_type == "lkj") {
    # For LKJ, we need to work with correlation matrix
    rho_declaration <- "real<lower=-1, upper=1> rho;"
    rho_transform <- ""
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
  ", rho_transform, "
  
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
  
  // Output rho for all prior types (ensures it's always extractable)
  real rho_out = ", ifelse(prior_rho_type == "fisher_z", "tanh(z_rho)", "rho"), ";
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
# UI DEFINITION - SIMPLIFIED VERSION (No Help or Model Description tabs)
# ===========================================================================

ui <- navbarPage(
  title = "Bayesian PoS Simulation - Overall Survival (Simplified)",
  theme = shinytheme("flatly"),
  
  tabPanel("Run Model",
           sidebarLayout(
             sidebarPanel(
               h3("MCMC Settings"),
               numericInput("n_iter", "MCMC Iterations:", value = 4000, min = 1000, max = 10000, step = 500),
               numericInput("n_chains", "Number of Chains:", value = 4, min = 1, max = 8),
               numericInput("adapt_delta", "Adapt Delta:", value = 0.99, min = 0.8, max = 0.9999, step = 0.01),
               numericInput("max_treedepth", "Max Tree Depth:", value = 12, min = 10, max = 15, step = 1),
               hr(),
               
               # New section for data generation parameters
               h3("Data Generation Parameters"),
               wellPanel(
                 style = "background-color: #f8f9fa;",
                 h4("Random Seed"),
                 numericInput("data_seed", "Random Seed:", value = 20260212, min = 1, step = 1),
                 helpText("Set seed for reproducible data generation"),
                 
                 h4("Population Parameters"),
                 fluidRow(
                   column(6, numericInput("data_mu_os", "μ_OS (True):", value = -0.30, step = 0.05)),
                   column(6, numericInput("data_mu_pfs", "μ_PFS (True):", value = -0.45, step = 0.05))
                 ),
                 fluidRow(
                   column(6, numericInput("data_tau_os", "τ_OS (True):", value = 0.15, min = 0.01, step = 0.01)),
                   column(6, numericInput("data_tau_pfs", "τ_PFS (True):", value = 0.15, min = 0.01, step = 0.01))
                 ),
                 numericInput("data_rho_true", "ρ (True Between-Trial Correlation):", value = 0.65, min = -0.95, max = 0.95, step = 0.05),
                 helpText("These are the TRUE population parameters used to generate the 27 historical trials"),
                 
                 h4("Standard Error Ranges"),
                 fluidRow(
                   column(6, numericInput("data_se_os_min", "SE_OS Min:", value = 0.10, min = 0.01, step = 0.01)),
                   column(6, numericInput("data_se_os_max", "SE_OS Max:", value = 0.13, min = 0.01, step = 0.01))
                 ),
                 fluidRow(
                   column(6, numericInput("data_se_pfs_min", "SE_PFS Min:", value = 0.08, min = 0.01, step = 0.01)),
                   column(6, numericInput("data_se_pfs_max", "SE_PFS Max:", value = 0.11, min = 0.01, step = 0.01))
                 ),
                 
                 h4("Within-Trial Correlation Range"),
                 fluidRow(
                   column(6, numericInput("data_rho_within_min", "ρ_within Min:", value = 0.55, min = 0, max = 1, step = 0.05)),
                   column(6, numericInput("data_rho_within_max", "ρ_within Max:", value = 0.75, min = 0, max = 1, step = 0.05))
                 ),
                 helpText("Within-trial correlation between OS and PFS measurements (patient-level)")
               ),
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
                          choices = c("Fisher z-transform (RECOMMENDED)" = "fisher_z",
                                    "Uniform(-0.95, 0.95)" = "uniform", 
                                    "Uniform(0, 0.95) - Positive Only" = "uniform_positive",
                                    "Beta(α, β) - Positive Only" = "beta",
                                    "LKJ" = "lkj"),
                          selected = "fisher_z"),
               conditionalPanel(
                 condition = "input.prior_rho_type == 'fisher_z'",
                 numericInput("prior_rho_param", "z Prior Mean (μ_z):", value = 0.5365, step = 0.01),
                 numericInput("prior_rho_param2", "z Prior SD (σ_z):", value = 0.2173, min = 0.01, step = 0.01),
                 helpText("Fisher z-transformation: z = atanh(ρ), ρ = tanh(z). This provides better sampling geometry and reduces shrinkage toward 0. Recommended: μ_z=0, σ_z=1.5 (weakly informative). For high ρ: μ_z=atanh(0.7)≈0.87, σ_z=0.5.")
               ),
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
               helpText("Fisher z-transformation (recommended) improves estimation and reduces systematic underestimation. For positive-only priors, use Uniform(0, 0.95) or Beta."),
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
  
  
  # Tab 4: NEW - Scatter Plot
  tabPanel("Scatter Plot",
           fluidPage(
             h3("OS vs PFS Log-Hazard Ratios: Historical + Current Trial"),
             hr(),
             fluidRow(
               column(12,
                      plotOutput("scatter_plot", height = "600px")
               )
             ),
             fluidRow(
               column(12,
                      h4("Interpretation"),
                      p("This scatter plot shows the relationship between PFS and OS log-hazard ratios for:"),
                      tags$ul(
                        tags$li(strong("27 historical trials"), " (blue points)"),
                        tags$li(strong("Current trial"), " (red point, highlighted and labeled)")
                      ),
                      p("The between-trial correlation (ρ) is estimated from the pattern of these 27 historical points. 
                        The diagonal reference line (y=x) helps visualize concordance between OS and PFS effects.")
                    )
             )
           )
  ),
  
  # Tab 5: Data Management
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
  
)
server <- function(input, output, session) {
  
  # Reactive historical data that regenerates when parameters change
  historical_data <- reactive({
    prepare_historical_loghr_data(
      seed = input$data_seed,
      mu_os = input$data_mu_os,
      mu_pfs = input$data_mu_pfs,
      tau_os = input$data_tau_os,
      tau_pfs = input$data_tau_pfs,
      rho_true = input$data_rho_true,
      se_os_min = input$data_se_os_min,
      se_os_max = input$data_se_os_max,
      se_pfs_min = input$data_se_pfs_min,
      se_pfs_max = input$data_se_pfs_max,
      rho_within_min = input$data_rho_within_min,
      rho_within_max = input$data_rho_within_max
    )
  })
  
  # Reactive values to store results
  results <- reactiveValues(
    fit = NULL,
    posterior_samples = NULL,
    summary = NULL
  )
  
  # Display historical data
  output$historical_data_table <- renderDT({
    historical_data() %>%
      dplyr::select(trial_id, cancer_type, n_patients, loghr_os, se_loghr_os, loghr_pfs, se_loghr_pfs, corr_pfs_os) %>%
      mutate(across(starts_with("loghr"), ~round(., 3)),
             across(starts_with("se_"), ~round(., 3)),
             across(starts_with("corr"), ~round(., 3))) %>%
      datatable(options = list(pageLength = 10, scrollX = TRUE))
  })
  
  # Data summary
  output$data_summary <- renderPrint({
    cat("Historical Trials Summary\n")
    cat(strrep("=", 60), "\n\n")
    cat("Number of trials: ", nrow(historical_data()), "\n")
    cat("Cancer types: ", paste(unique(historical_data()$cancer_type), collapse = ", "), "\n\n")
    cat("OS log(HR) - Mean:", round(mean(historical_data()$loghr_os), 3), 
        "SD:", round(sd(historical_data()$loghr_os), 3), "\n")
    cat("PFS log(HR) - Mean:", round(mean(historical_data()$loghr_pfs), 3), 
        "SD:", round(sd(historical_data()$loghr_pfs), 3), "\n\n")
    
    # Calculate and display between-trial correlation
    between_trial_cor <- cor(historical_data()$loghr_pfs, historical_data()$loghr_os)
    cat("CORRELATIONS:\n")
    cat("  Between-trial cor(PFS, OS): ", round(between_trial_cor, 3), 
        " <- This is what the model learns as rho\n")
    cat("  Within-trial cor (average): ", round(mean(historical_data()$corr_pfs_os), 3), 
        " <- Patient-level correlation within trials\n")
  })
  
  
  # NEW: Scatter plot of historical + current trial
  output$scatter_plot <- renderPlot({
    # Prepare data for plotting
    plot_data <- historical_data() %>%
      mutate(type = "Historical")
    
    # Add current trial
    current_point <- data.frame(
      loghr_pfs = input$loghr_pfs_interim,
      loghr_os = input$loghr_os_interim,
      type = "Current"
    )
    
    plot_data_combined <- bind_rows(
      plot_data %>% dplyr::select(loghr_pfs, loghr_os, type),
      current_point
    )
    
    # Calculate correlation for annotation
    between_cor <- cor(historical_data()$loghr_pfs, historical_data()$loghr_os)
    
    # Create scatter plot
    ggplot(plot_data_combined, aes(x = loghr_pfs, y = loghr_os, color = type, size = type)) +
      geom_point(alpha = 0.7) +
      geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray50", linewidth = 0.5) +
      geom_point(data = current_point, aes(x = loghr_pfs, y = loghr_os), 
                 color = "red", size = 5, shape = 18) +  # Diamond for current
      annotate("text", x = current_point$loghr_pfs, y = current_point$loghr_os - 0.03,
               label = "Current Trial", color = "red", fontface = "bold", size = 4) +
      scale_color_manual(values = c("Historical" = "steelblue", "Current" = "red")) +
      scale_size_manual(values = c("Historical" = 3, "Current" = 5)) +
      labs(
        title = "OS vs PFS Log-Hazard Ratios: Historical Trials + Current Trial",
        subtitle = paste0("Between-trial correlation: ", round(between_cor, 3), 
                         " (from 27 historical trials)"),
        x = "PFS log(HR)",
        y = "OS log(HR)",
        caption = "Diagonal line represents y=x (perfect concordance)"
      ) +
      theme_minimal(base_size = 14) +
      theme(
        legend.position = "top",
        legend.title = element_blank(),
        plot.title = element_text(face = "bold", size = 16),
        plot.subtitle = element_text(size = 12, color = "gray30")
      )
  })
  
  # Run model
  observeEvent(input$run_model, {
    
    # Prepare Stan data
    stan_data <- prepare_stan_data(
      historical_data(),
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
        prior_rho_param = input$prior_rho_param,    # Pass UI value directly
        prior_rho_param2 = input$prior_rho_param2   # Pass UI value directly
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
