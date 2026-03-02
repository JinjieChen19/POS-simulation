# ============================================================================
# UI.R - User Interface for Bayesian PoS Simulation App
# ============================================================================
# Defines the user interface with 5 tabs:
# 1. Run Model - Controls for MCMC settings, data generation, priors
# 2. Results - MCMC diagnostics, posterior plots, PoS calculation
# 3. Scatter Plot - Visualization of 27+1 trials
# 4. Data - Historical trials table
# 5. Model Description - Stan model, assumptions, priors, references
# ============================================================================

navbarPage(
  title = "Bayesian PoS Simulation - Local Server (Team Access)",
  theme = shinytheme("flatly"),
  
  tabPanel("Run Model",
           sidebarLayout(
             sidebarPanel(
               h3("MCMC Settings"),
               numericInput("n_iter", "MCMC Iterations:", value = 2000, min = 1000, max = 10000, step = 500),
              helpText("Note: Lower values (2000-3000) recommended for shinyapps.io to avoid timeouts."),
               numericInput("n_chains", "Number of Chains:", value = 1, min = 1, max = 8),
              helpText("Note: Use 1 chain for shinyapps.io to avoid 'invalid connection' errors."),
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
                 helpText("Range for within-trial correlation between OS and PFS")
               ),
               hr(),
               
               h3("Prior Settings"),
               h4("μ Priors (Population Means)"),
               fluidRow(
                 column(6, numericInput("prior_mu_os_mean", "OS Mean:", value = -0.35)),
                 column(6, numericInput("prior_mu_os_sd", "OS SD:", value = 1.0, min = 0.01))
               ),
               fluidRow(
                 column(6, numericInput("prior_mu_pfs_mean", "PFS Mean:", value = -0.45)),
                 column(6, numericInput("prior_mu_pfs_sd", "PFS SD:", value = 1.0, min = 0.01))
               ),
               
               h4("τ Priors (Between-Trial SDs)"),
               selectInput("prior_tau_type", "Distribution:",
                           choices = c("Exponential" = "exponential", "Half-Normal" = "half_normal"),
                           selected = "exponential"),
               fluidRow(
                 column(6, numericInput("prior_tau_param_os", "OS Parameter:", value = 1, min = 0.01, step = 0.1)),
                 column(6, numericInput("prior_tau_param_pfs", "PFS Parameter:", value = 1, min = 0.01, step = 0.1))
               ),
               helpText("Exponential: rate parameter (mean=1/rate). Half-Normal: SD parameter"),
               
               h4("ρ Prior (Between-Trial Correlation)"),
               selectInput("prior_rho_type", "Distribution:",
                           choices = c("Fisher z-transform (RECOMMENDED)" = "fisher_z",
                                       "Uniform(-0.95, 0.95)" = "uniform",
                                       "Uniform(0, 0.95) - Positive Only" = "uniform_positive",
                                       "Beta(α,β) - Positive Only" = "beta",
                                       "LKJ(η)" = "lkj"),
                           selected = "fisher_z"),
               
               conditionalPanel(
                 condition = "input.prior_rho_type == 'fisher_z'",
                 numericInput("prior_rho_param", "z Prior Mean (μ_z):", value = mu_z_default, step = 0.1),
                 numericInput("prior_rho_param2", "z Prior SD (σ_z):", value = sd_z_default, min = 0.01, step = 0.01),
                 helpText(paste0("Default values give ρ 95% ~ [0.35, 0.80]. ",
                                 "For weakly informative: μ_z=0, σ_z=1.5. ",
                                 "For high positive: μ_z=", round(atanh(0.7), 2), ", σ_z=0.5"))
               ),
               conditionalPanel(
                 condition = "input.prior_rho_type == 'beta'",
                 numericInput("prior_rho_param", "α (alpha):", value = 2, min = 0.1, step = 0.1),
                 numericInput("prior_rho_param2", "β (beta):", value = 1, min = 0.1, step = 0.1),
                 helpText("Beta(2,1): weakly favors high positive. Beta(5,1): strongly favors high positive. Beta(2,2): favors moderate around 0.5")
               ),
               conditionalPanel(
                 condition = "input.prior_rho_type == 'lkj'",
                 numericInput("prior_rho_param", "η (eta):", value = 1, min = 0.1, step = 0.1),
                 helpText("LKJ(1): uniform over correlation matrices. η>1: favor smaller correlations. η<1: favor extreme correlations")
               ),
               
               hr(),
               
               h3("Current Trial"),
               numericInput("loghr_os_interim", "Interim log(HR) for OS:", value = -0.30, step = 0.05),
               numericInput("se_loghr_os_interim", "SE of log(HR) for OS:", value = 0.20, min = 0.01, step = 0.01),
               numericInput("loghr_pfs_interim", "Interim log(HR) for PFS:", value = -0.45, step = 0.05),
               numericInput("se_loghr_pfs_interim", "SE of log(HR) for PFS:", value = 0.15, min = 0.01, step = 0.01),
               
               hr(),
               
               h3("PoS Target Threshold"),
               helpText("Define success criterion for OS Probability of Success"),
               numericInput("target_os", "OS Target log(HR):", value = -0.30, step = 0.05),
               helpText("PoS = Pr(log HR_OS < target). Example: -0.30 means HR < 0.74 (26% reduction)"),
               helpText("Note: PFS data is already observed when predicting OS success."),
               
               hr(),
               actionButton("run_model", "Run Stan Model", class = "btn-primary btn-lg", icon = icon("play"))
             ),
             
             mainPanel(
               h3("Model Status"),
                verbatimTextOutput("model_status")
           )
              )
  ),
  
  tabPanel("Results",
           fluidPage(
             h2("MCMC Diagnostics"),
             plotOutput("trace_plot", height = "400px"),
             hr(),
             
             h2("Posterior Distributions"),
             plotOutput("posterior_plot", height = "600px"),
             hr(),
             
             h2("Probability of Success (PoS)"),
             wellPanel(
               style = "background-color: #f0f8ff;",
               h3("PoS Calculation"),
               p("PoS is the posterior probability that the true log(HR) for OS is less than 0 (i.e., treatment benefit)."),
               verbatimTextOutput("pos_output")
             )
           )
  ),
  
  tabPanel("Scatter Plot",
           fluidPage(
             h2("Scatter Plot of Historical Trials + Current Trial"),
             p("Blue points: 27 historical trials. Red diamond: Current trial."),
             plotOutput("scatter_plot", height = "600px"),
             hr(),
             h3("Interpretation"),
             p("This plot shows the relationship between PFS and OS log(HR) values across all trials."),
             p("The diagonal reference line (y=x) helps visualize where PFS and OS effects are equal."),
             p("The between-trial correlation is displayed and represents the association at the trial level.")
           )
  ),
  
  tabPanel("Data",
           fluidPage(
             h2("Historical Trials Summary"),
             p("Showing the 27 historical trials used for the Bayesian model."),
             p(strong("Note:"), " n_events_os and n_events_pfs represent the number of ", strong("events"), 
               " (D), not total sample size. For survival analysis with log hazard ratios, ",
               "precision depends on event counts. Typical Phase 3 oncology trials have ~500 total patients ",
               "(two arms) with OS events ~260-300 and PFS events ~350+."),
             DT::dataTableOutput("data_table"),
             hr(),
             h3("Data Summary"),
             verbatimTextOutput("data_summary")
           )
  ),
  
  tabPanel("Model Description",
           fluidPage(
             h2("Bayesian Hierarchical Model for PoS Calculation"),
             
             wellPanel(
               style = "background-color: #f8f9fa;",
               h3("Model Overview"),
               p("This application implements a Bayesian hierarchical model to estimate the Probability of Success (PoS) ",
                 "for an ongoing clinical trial based on historical trial data and interim results."),
               
               h4("Key Features"),
               tags$ul(
                 tags$li(strong("Hierarchical structure:"), " Borrows strength across historical trials while accounting for between-trial heterogeneity"),
                 tags$li(strong("Bivariate endpoints:"), " Jointly models Overall Survival (OS) and Progression-Free Survival (PFS) with correlation"),
                 tags$li(strong("Flexible priors:"), " All prior parameters passed as data - no recompilation needed for prior changes"),
                 tags$li(strong("Non-centered parameterization:"), " Improves MCMC sampling efficiency and convergence"),
                 tags$li(strong("Target-based PoS:"), " Calculates probability relative to user-specified success thresholds")
               )
             ),
             
             wellPanel(
               h3("Hierarchical Model Structure (Visual)"),
               p("The diagram below illustrates the three-level hierarchical structure of the model:"),
               
               # Hierarchical model diagram using HTML/CSS
               tags$div(
                 style = "background: white; padding: 20px; border: 1px solid #ddd; border-radius: 5px; margin: 20px 0;",
                 
                 # Level 3: Population (Hyperpriors)
                 tags$div(
                   style = "background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%); color: white; padding: 15px; border-radius: 8px; margin-bottom: 15px; text-align: center;",
                   tags$h4(style = "margin: 5px 0; color: white;", "Level 3: Population Parameters (Hyperpriors)"),
                   HTML("<div style='font-size: 16px; margin-top: 10px;'>"),
                   HTML("μ = (μ<sub>OS</sub>, μ<sub>PFS</sub>) ~ Normal(prior means, prior SDs)"),
                   tags$br(),
                   HTML("Σ = f(τ<sub>OS</sub>, τ<sub>PFS</sub>, ρ) with priors on τ and ρ"),
                   HTML("</div>")
                 ),
                 
                 # Arrow down
                 tags$div(
                   style = "text-align: center; font-size: 30px; color: #2c3e50; margin: 10px 0;",
                   "↓"
                 ),
                 
                 # Level 2: Trial-specific parameters
                 tags$div(
                   style = "background: linear-gradient(135deg, #16a085 0%, #1abc9c 100%); color: white; padding: 15px; border-radius: 8px; margin-bottom: 15px; text-align: center;",
                   tags$h4(style = "margin: 5px 0; color: white;", "Level 2: Trial-Specific Effects"),
                   HTML("<div style='font-size: 16px; margin-top: 10px;'>"),
                   HTML("θ<sub>k</sub> = (θ<sub>k,OS</sub>, θ<sub>k,PFS</sub>) ~ MVN(μ, Σ)"),
                   tags$br(),
                   HTML("for k = 1, ..., K (historical trials) + current trial"),
                   HTML("</div>")
                 ),
                 
                 # Arrow down
                 tags$div(
                   style = "text-align: center; font-size: 30px; color: #16a085; margin: 10px 0;",
                   "↓"
                 ),
                 
                 # Level 1: Observed data
                 tags$div(
                   style = "background: linear-gradient(135deg, #3498db 0%, #5dade2 100%); color: white; padding: 15px; border-radius: 8px; text-align: center;",
                   tags$h4(style = "margin: 5px 0; color: white;", "Level 1: Observed Data (Likelihood)"),
                   HTML("<div style='font-size: 16px; margin-top: 10px;'>"),
                   HTML("y<sub>k</sub> = (y<sub>k,OS</sub>, y<sub>k,PFS</sub>) ~ MVN(θ<sub>k</sub>, W<sub>k</sub>)"),
                   tags$br(),
                   HTML("W<sub>k</sub> = within-trial covariance (known from observed SEs)"),
                   HTML("</div>")
                 ),
                 
                 # Legend
                 tags$div(
                   style = "margin-top: 20px; padding: 15px; background: #f8f9fa; border-radius: 5px; border-left: 4px solid #2c3e50;",
                   tags$strong("Information Flow:"),
                   tags$ul(
                     style = "margin-top: 10px;",
                     tags$li("Population parameters (μ, Σ) govern the distribution of trial-specific effects"),
                     tags$li("Trial-specific effects (θ", tags$sub("k"), ") represent the true treatment effects in each trial"),
                     tags$li("Observed data (y", tags$sub("k"), ") provide noisy measurements of the true effects"),
                     tags$li("The model 'borrows strength' across trials while accounting for heterogeneity")
                   )
                 )
               )
             ),
             
             wellPanel(
               h3("Stan Model Structure"),
               
               h4("1. Data Level"),
               p("For each historical trial ", em("k"), " = 1, ..., K and current trial:"),
               tags$ul(
                 tags$li(HTML("<b>Observed log hazard ratios:</b> y<sub>k</sub> = (y<sub>k,OS</sub>, y<sub>k,PFS</sub>)")),
                 tags$li(HTML("<b>Within-trial covariance:</b> W<sub>k</sub> (accounts for estimation uncertainty and within-trial correlation)"))
               ),
               
               h4("2. Trial-Specific Parameters"),
               p(HTML("Each trial has true treatment effects θ<sub>k</sub> = (θ<sub>k,OS</sub>, θ<sub>k,PFS</sub>)")),
               p(HTML("Observational model: y<sub>k</sub> ~ MVN(θ<sub>k</sub>, W<sub>k</sub>)")),
               
               h4("3. Population-Level Parameters"),
               p(HTML("Trial-specific effects follow a bivariate normal distribution: θ<sub>k</sub> ~ MVN(μ, Σ)")),
               tags$ul(
                 tags$li(HTML("<b>μ</b> = (μ<sub>OS</sub>, μ<sub>PFS</sub>): Population mean log hazard ratios")),
                 tags$li(HTML("<b>Σ</b>: Between-trial covariance matrix with standard deviations τ<sub>OS</sub>, τ<sub>PFS</sub> and correlation ρ"))
               ),
               
               h4("4. Non-Centered Parameterization"),
               p("For improved MCMC efficiency:"),
               tags$ul(
                 tags$li(HTML("θ<sub>raw,k</sub> ~ Normal(0, 1) [standard normal]")),
                 tags$li(HTML("θ<sub>k</sub> = μ + L × θ<sub>raw,k</sub> [where L is Cholesky factor of Σ]"))
               ),
               p("This separates the hierarchical structure from the centering, dramatically improving sampling.")
             ),
             
             wellPanel(
               h3("Prior Specifications"),
               
               h4("Population Means (μ)"),
               p(HTML("μ<sub>OS</sub> ~ Normal(prior_mu_os_mean, prior_mu_os_sd)")),
               p(HTML("μ<sub>PFS</sub> ~ Normal(prior_mu_pfs_mean, prior_mu_pfs_sd)")),
               p("Default: Weakly informative priors centered at expected effect sizes with large standard deviations."),
               
               h4("Between-Trial Standard Deviations (τ)"),
               p("Options available:"),
               tags$ul(
                 tags$li(strong("Exponential:"), " τ ~ Exp(λ), mean = 1/λ"),
                 tags$li(strong("Half-Normal:"), " τ ~ HalfNormal(0, σ)")
               ),
               p("Default: Exponential(1) for both OS and PFS, allowing substantial heterogeneity."),
               
               h4("Between-Trial Correlation (ρ)"),
               p("Options available:"),
               tags$ol(
                 tags$li(strong("Fisher z-transform (RECOMMENDED):"), " Transforms ρ to unbounded scale for better sampling"),
                 tags$li(strong("Uniform:"), " Direct uniform prior on [-0.95, 0.95]"),
                 tags$li(strong("Uniform positive:"), " Constrained to [0, 0.95]"),
                 tags$li(strong("Beta:"), " For positive correlations only"),
                 tags$li(strong("LKJ:"), " Symmetric prior for correlation matrices")
               ),
               p("Default: Fisher z-transform with z ~ Normal(μ_z, σ_z), where μ_z and σ_z are chosen ",
                 "to give ρ with 95% credible interval approximately [0.35, 0.80].")
             ),
             
             wellPanel(
               h3("PoS Calculation"),
               
               p("The Probability of Success (PoS) is calculated as:"),
               p(HTML("<b>PoS<sub>OS</sub></b> = Pr(θ<sub>current,OS</sub> < target<sub>OS</sub> | data)")),
               
               p("Where:"),
               tags$ul(
                 tags$li(HTML("θ<sub>current,OS</sub> is the true treatment effect for the current trial")),
                 tags$li(HTML("target<sub>OS</sub> is the user-specified success threshold (e.g., log(0.74) ≈ -0.30 for 26% reduction)")),
                 tags$li("Calculated from posterior samples: proportion of samples where condition is met")
               ),
               
               p(strong("Interpretation Example:")),
               p("If target_OS = -0.30 (HR < 0.74) and PoS = 0.67, there is a 67% probability that ",
                 "the final trial will demonstrate at least a 26% risk reduction in OS.")
             ),
             
             wellPanel(
               h3("Simulation Settings"),
               
               h4("Historical Data Generation"),
               p("27 historical trials are simulated with:"),
               tags$ul(
                 tags$li(HTML("<b>Event counts:</b> OS events (D<sub>OS</sub>): 180-300, PFS events (D<sub>PFS</sub>): 250-380")),
                 tags$li(strong("True population parameters:"), " User-specified μ, τ, and ρ"),
                 tags$li(strong("Standard errors:"), " Realistic ranges based on event counts (SE ∝ 1/√D)"),
                 tags$li(strong("Within-trial correlation:"), " Varies by trial (typically 0.55-0.75)")
               ),
               
               h4("Current Trial Specification"),
               p("Users specify:"),
               tags$ul(
                 tags$li("Interim log hazard ratios for OS and PFS"),
                 tags$li("Standard errors (reflecting interim analysis timing)"),
                 tags$li("Success threshold for OS")
               )
             ),
             
             wellPanel(
               h3("Key Assumptions"),
               
               tags$ol(
                 tags$li(strong("Exchangeability:"), " Historical trials are assumed exchangeable (similar enough to pool)"),
                 tags$li(strong("Normal approximation:"), " Log hazard ratios are approximately normally distributed (valid for moderate to large event counts)"),
                 tags$li(strong("Known standard errors:"), " Estimation uncertainty in SEs is ignored (reasonable for well-powered trials)"),
                 tags$li(strong("Independence:"), " Trials are independent (no overlapping populations or systematic biases)"),
                 tags$li(strong("Bivariate normal structure:"), " The joint distribution of OS and PFS treatment effects is adequately captured by bivariate normal"),
                 tags$li(strong("Linear correlation:"), " The relationship between OS and PFS is characterized by Pearson correlation")
               ),
               
               p(strong("Important:"), " These assumptions should be critically evaluated for each application. ",
                 "Sensitivity analyses with different prior specifications are recommended.")
             ),
             
             wellPanel(
               h3("Prior Selection Considerations"),
               
               h4("Choosing μ Priors"),
               tags$ul(
                 tags$li("Center at clinically plausible effect sizes based on mechanism of action"),
                 tags$li("Use wide SDs (e.g., 1.0) to remain weakly informative"),
                 tags$li("Consider therapeutic class and historical effect sizes")
               ),
               
               h4("Choosing τ Priors"),
               tags$ul(
                 tags$li("τ represents between-trial heterogeneity (how much trials vary)"),
                 tags$li("Exponential(1) allows substantial heterogeneity while regularizing extreme values"),
                 tags$li("Consider disease heterogeneity, trial design differences, and patient populations")
               ),
               
               h4("Choosing ρ Priors"),
               tags$ul(
                 tags$li("ρ captures correlation between OS and PFS treatment effects across trials"),
                 tags$li("Fisher z-transform provides better sampling than direct parameterization"),
                 tags$li("Default centers on moderate positive correlation (ρ ~ 0.55) with wide uncertainty"),
                 tags$li("Strong positive correlation (ρ > 0.7) may be expected for diseases where PFS strongly predicts OS")
               ),
               
               h4("Sensitivity Analysis"),
               p("It is crucial to:"),
               tags$ul(
                 tags$li("Run the model with different prior specifications"),
                 tags$li("Examine how PoS estimates change"),
                 tags$li("Check that conclusions are robust to reasonable prior choices"),
                 tags$li("Report sensitivity analyses in any decision documents")
               )
             ),
             
             wellPanel(
               h3("Computational Details"),
               
               tags$ul(
                 tags$li(strong("Algorithm:"), " Hamiltonian Monte Carlo (HMC) via Stan"),
                 tags$li(strong("Default settings:"), " 2000 iterations, 1000 warmup, 4 chains"),
                 tags$li(strong("Convergence diagnostics:"), " Rhat < 1.01, ESS > 400 (check trace plots)"),
                 tags$li(strong("Adapt delta:"), " 0.99 (high value reduces divergences in challenging posteriors)"),
                 tags$li(strong("Compilation:"), " Model precompiled for instant startup (<1 second vs 60-120 seconds)")
               )
             ),
             
             wellPanel(
               h3("References and Further Reading"),
               
               tags$ul(
                 tags$li("Spiegelhalter DJ, Abrams KR, Myles JP (2004). ", em("Bayesian Approaches to Clinical Trials and Health-Care Evaluation.")),
                 tags$li("Gelman A, et al. (2013). ", em("Bayesian Data Analysis"), ", 3rd ed."),
                 tags$li("Stan Development Team (2023). ", em("Stan Modeling Language Users Guide and Reference Manual.")),
                 tags$li("Betancourt M (2017). ", em("A Conceptual Introduction to Hamiltonian Monte Carlo.")),
                 tags$li("Papanikos T, et al. (2020). ", em("Bayesian hierarchical models for multiple outcomes.")),
                 tags$li("FDA Guidance: ", em("Adaptive Designs for Clinical Trials of Drugs and Biologics"), " (2019)")
               )
             ),
             
             p(HTML("<hr><small><i>Model implementation: Stan version ", 
                    "with non-centered parameterization and flexible priors. ",
                    "For technical questions or to report issues, contact the development team.</i></small>"))
           )
  )
)
