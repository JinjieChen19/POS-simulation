# ============================================================================
# SERVER_LOCAL.R - Server Logic for Local RStudio Server
# ============================================================================
# Features:
# - Uses pre-compiled universal Stan model
# - Shows sampling progress to users
# - No recompilation when changing priors
# - Optimized for team access on local server
# ============================================================================

function(input, output, session) {
  
  # ===========================================================================
  # REACTIVE DATA
  # ===========================================================================
  
  # Historical data that regenerates when parameters change
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
  
  # Store results
  results <- reactiveValues(
    fit = NULL,
    posterior_samples = NULL,
    summary = NULL
  )
  
  # ===========================================================================
  # DATA DISPLAY
  # ===========================================================================
  
  output$historical_data_table <- renderDT({
    historical_data() %>%
      dplyr::select(trial_id, cancer_type, n_patients, loghr_os, se_loghr_os, 
                    loghr_pfs, se_loghr_pfs, corr_pfs_os) %>%
      mutate(across(starts_with("loghr"), ~round(., 3)),
             across(starts_with("se_"), ~round(., 3)),
             across(starts_with("corr"), ~round(., 3))) %>%
      datatable(options = list(pageLength = 10, scrollX = TRUE))
  })
  
  output$data_summary <- renderPrint({
    cat("Historical Trials Summary\n")
    cat(strrep("=", 60), "\n\n")
    cat("Number of trials: ", nrow(historical_data()), "\n")
    cat("Cancer types: ", paste(unique(historical_data()$cancer_type), collapse = ", "), "\n\n")
    cat("OS log(HR) - Mean:", round(mean(historical_data()$loghr_os), 3), 
        "SD:", round(sd(historical_data()$loghr_os), 3), "\n")
    cat("PFS log(HR) - Mean:", round(mean(historical_data()$loghr_pfs), 3), 
        "SD:", round(sd(historical_data()$loghr_pfs), 3), "\n\n")
    
    between_trial_cor <- cor(historical_data()$loghr_pfs, historical_data()$loghr_os)
    
    cat("CORRELATIONS:\n")
    cat("  Between-trial cor(PFS, OS): ", round(between_trial_cor, 3), 
        " <- Model learns this as rho\n", sep = "")
    cat("  Within-trial cor (average): ", round(mean(historical_data()$corr_pfs_os), 3), 
        " <- Patient-level correlation\n", sep = "")
  })
  
  # ===========================================================================
  # RUN MODEL WITH PROGRESS DISPLAY
  # ===========================================================================
  # KEY FEATURE: Shows progress to users during sampling
  # No recompilation - just passes priors as data!
  # ===========================================================================
  
  observeEvent(input$run_model, {
    
    # Validate that universal model is available
    if (is.null(UNIVERSAL_STAN_MODEL)) {
      output$model_status <- renderPrint({
        cat("ERROR: Universal Stan model not compiled!\n")
        cat("Please restart the server to compile the model.\n")
      })
      return()
    }
    
    # Show progress indicator
    withProgress(message = 'Running Bayesian Analysis', value = 0, {
      
      incProgress(0.1, detail = "Preparing data...")
      
      # Prepare current trial data
      current_trial <- list(
        loghr_os = input$loghr_os_interim,
        loghr_pfs = input$loghr_pfs_interim,
        se_loghr_os = input$se_loghr_os_interim,
        se_loghr_pfs = input$se_loghr_pfs_interim
      )
      
      # Prepare prior specifications
      # Map UI inputs to Stan model integer codes
      tau_type_map <- c("exponential" = 1, "half_normal" = 2, "uniform" = 3)
      rho_type_map <- c("fisher_z" = 1, "uniform" = 2, "uniform_positive" = 3, 
                        "beta" = 4, "lkj" = 5)
      
      prior_specs <- list(
        # mu priors
        mu_os_mean = input$prior_mu_os_mean,
        mu_os_sd = input$prior_mu_os_sd,
        mu_pfs_mean = input$prior_mu_pfs_mean,
        mu_pfs_sd = input$prior_mu_pfs_sd,
        
        # tau priors
        tau_type = tau_type_map[input$prior_tau_type],
        tau_param_os = input$prior_tau_param_os,
        tau_param_pfs = input$prior_tau_param_pfs,
        tau_param2_os = ifelse(input$prior_tau_type == "uniform", 
                               input$prior_tau_param_os * 3, 1),  # Upper bound for uniform
        tau_param2_pfs = ifelse(input$prior_tau_type == "uniform", 
                                input$prior_tau_param_pfs * 3, 1),
        
        # rho priors
        rho_type = rho_type_map[input$prior_rho_type],
        rho_param = input$prior_rho_param,
        rho_param2 = input$prior_rho_param2,
        rho_lower = ifelse(input$prior_rho_type == "uniform", -0.95, 0),
        rho_upper = ifelse(input$prior_rho_type %in% c("uniform", "uniform_positive"), 0.95, 1)
      )
      
      incProgress(0.2, detail = "Building Stan data...")
      
      # Build Stan data (no model compilation needed!)
      stan_data <- prepare_stan_data(
        historical_data = historical_data(),
        current_trial_data = current_trial,
        prior_specs = prior_specs,
        target_os = input$target_os,      # User-specified target
        # PFS has already been read out when predicting OS success
        target_pfs = 0                     # Fixed value, not user input
      )
      
      incProgress(0.3, detail = "Starting MCMC sampling...")
      
      # Update status
      output$model_status <- renderPrint({
        cat("==========================================================\n")
        cat("⚡ RUNNING BAYESIAN ANALYSIS\n")
        cat("==========================================================\n\n")
        cat("Status:\n")
        cat("  ✓ Model compilation: DONE (loaded at startup in < 1 sec)\n")
        cat("  🔄 MCMC sampling: IN PROGRESS (takes 10-30 seconds)\n")
        cat("\n")
        cat("Configuration:\n")
        cat("  Iterations:", input$n_iter, "\n")
        cat("  Chains:", input$n_chains, "\n")
        cat("  Warmup:", input$n_iter / 2, "\n")
        cat("  Adapt delta:", input$adapt_delta, "\n\n")
        cat("==========================================================\n")
        cat("What's happening now:\n")
        cat("==========================================================\n")
        cat("  NOT compiling (that was done at startup)\n")
        cat("  ✓ Sampling from posterior distribution\n")
        cat("  ✓ Running Markov Chain Monte Carlo (MCMC)\n")
        cat("  ✓ This takes time regardless of precompilation\n")
        cat("\n")
        cat("Precompilation benefit:\n")
        cat("  - Without precompile: 60-120 sec compile + 10-30 sec sample\n")
        cat("  - With precompile: 0 sec compile + 10-30 sec sample\n")
        cat("  - Time saved: 60-120 seconds! 🚀\n")
        cat("\n")
        cat("Please wait for sampling to complete...\n")
      })
      
      # Run Stan sampling with the universal model
      tryCatch({
        
        fit <- sampling(
          UNIVERSAL_STAN_MODEL,           # Pre-compiled model (no recompilation!)
          data = stan_data,                # Priors included in data
          iter = input$n_iter,
          chains = input$n_chains,
          warmup = input$n_iter / 2,
          control = list(
            adapt_delta = input$adapt_delta,
            max_treedepth = input$max_treedepth
          ),
          verbose = FALSE,
          refresh = max(1, input$n_iter / 20),  # Show progress every 5%
          cores = input$n_chains  # Use parallel chains on local server
        )
        
        incProgress(0.9, detail = "Processing results...")
        
        # Store results
        results$fit <- fit
        results$posterior_samples <- as.data.frame(fit)
        results$summary <- summary(fit)$summary
        
        incProgress(1.0, detail = "Complete!")
        
        # Display success message
        output$model_status <- renderPrint({
          cat("✓ MCMC Sampling Complete!\n")
          cat(strrep("=", 60), "\n\n")
          
          # Check for convergence warnings
          sampler_params <- get_sampler_params(fit, inc_warmup = FALSE)
          divergences <- sum(sapply(sampler_params, function(x) sum(x[, 'divergent__'])))
          
          if (divergences > 0) {
            cat("⚠ WARNING:", divergences, "divergent transitions detected\n")
            cat("  Consider increasing adapt_delta\n\n")
          } else {
            cat("✓ No divergent transitions\n\n")
          }
          
          cat("Model Summary:\n")
          cat(strrep("-", 60), "\n")
          
          param_names <- c("mu[1]", "mu[2]", "tau_os", "tau_pfs", "rho_out", "theta_os_post")
          if (all(param_names %in% rownames(results$summary))) {
            print(results$summary[param_names, c("mean", "se_mean", "sd", "2.5%", "97.5%", "n_eff", "Rhat")])
          } else {
            print(head(results$summary, 10))
          }
        })
        
      }, error = function(e) {
        output$model_status <- renderPrint({
          cat("✗ ERROR during MCMC sampling:\n")
          cat(strrep("=", 60), "\n")
          cat(e$message, "\n\n")
          cat("Troubleshooting:\n")
          cat("1. Check that all prior parameters are valid\n")
          cat("2. Try reducing iterations if system is under load\n")
          cat("3. Check server logs for more details\n")
        })
      })
      
    }) # End withProgress
    
  }) # End observeEvent
  
  # ===========================================================================
  # MCMC DIAGNOSTICS - TRACE PLOTS
  # ===========================================================================
  
  output$trace_plot <- renderPlot({
    req(results$fit)
    
    params_to_plot <- c("mu[1]", "mu[2]", "tau_os", "tau_pfs", "rho_out")
    
    bayesplot::mcmc_trace(
      as.array(results$fit),
      pars = params_to_plot,
      facet_args = list(ncol = 2)
    ) +
      theme_minimal() +
      labs(title = "MCMC Trace Plots", subtitle = "Check for convergence and mixing")
  })
  
  # ===========================================================================
  # POSTERIOR DISTRIBUTIONS
  # ===========================================================================
  
  output$posterior_plot <- renderPlot({
    req(results$posterior_samples)
    
    p1 <- ggplot(results$posterior_samples, aes(x = `mu[1]`)) +
      geom_density(fill = "steelblue", alpha = 0.5) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
      theme_minimal() +
      labs(title = "μ_OS", x = "Population mean log(HR) for OS", y = "Density")
    
    p2 <- ggplot(results$posterior_samples, aes(x = `mu[2]`)) +
      geom_density(fill = "darkgreen", alpha = 0.5) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
      theme_minimal() +
      labs(title = "μ_PFS", x = "Population mean log(HR) for PFS", y = "Density")
    
    p3 <- ggplot(results$posterior_samples, aes(x = tau_os)) +
      geom_density(fill = "orange", alpha = 0.5) +
      theme_minimal() +
      labs(title = "τ_OS", x = "Between-trial SD for OS", y = "Density")
    
    p4 <- ggplot(results$posterior_samples, aes(x = tau_pfs)) +
      geom_density(fill = "purple", alpha = 0.5) +
      theme_minimal() +
      labs(title = "τ_PFS", x = "Between-trial SD for PFS", y = "Density")
    
    p5 <- ggplot(results$posterior_samples, aes(x = rho_out)) +
      geom_density(fill = "coral", alpha = 0.5) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
      theme_minimal() +
      labs(title = "ρ (Correlation)", x = "Between-trial correlation", y = "Density")
    
    p6 <- ggplot(results$posterior_samples, aes(x = theta_os_post)) +
      geom_density(fill = "navy", alpha = 0.5) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
      theme_minimal() +
      labs(title = "θ_OS (Current Trial)", x = "Posterior mean log(HR) for OS", y = "Density")
    
    gridExtra::grid.arrange(p1, p2, p3, p4, p5, p6, ncol = 2)
  })
  
  # ===========================================================================
  # PROBABILITY OF SUCCESS (PoS) WITH TARGET THRESHOLDS
  # ===========================================================================
  
  output$pos_output <- renderPrint({
    req(results$posterior_samples)
    req(input$target_os)
    
    # Calculate PoS using TARGET THRESHOLDS from Stan model
    # These are calculated in generated quantities
    pos_os <- mean(results$posterior_samples$pos_os_indicator)
    pos_pfs <- mean(results$posterior_samples$pos_pfs_indicator)
    pos_joint <- mean(results$posterior_samples$pos_joint_indicator)
    
    # Also calculate traditional PoS (HR < 1) for comparison
    pos_os_trad <- mean(results$posterior_samples$theta_os_post < 0)
    pos_pfs_trad <- mean(results$posterior_samples$theta_pfs_post < 0)
    
    cat("Probability of Success (PoS) with Target Threshold\n")
    cat(strrep("=", 70), "\n\n")
    cat("Based on", nrow(results$posterior_samples), "posterior samples\n\n")
    
    cat("Overall Survival (OS):\n")
    cat("  TARGET: log(HR) < ", input$target_os, " (HR < ", round(exp(input$target_os), 3), ")\n", sep = "")
    cat("  PoS = Pr(log HR_OS < target) = ", sprintf("%.1f%%", pos_os * 100), "\n")
    cat("  Traditional PoS (HR < 1) = ", sprintf("%.1f%%", pos_os_trad * 100), "\n")
    cat("  Posterior mean log(HR): ", round(mean(results$posterior_samples$theta_os_post), 3), "\n")
    cat("  95% CI: [", round(quantile(results$posterior_samples$theta_os_post, 0.025), 3),
        ",", round(quantile(results$posterior_samples$theta_os_post, 0.975), 3), "]\n\n")
    
    cat("Progression-Free Survival (PFS - Already Observed):\n")
    cat("  Posterior mean log(HR): ", round(mean(results$posterior_samples$theta_pfs_post), 3), "\n")
    cat("  95% CI: [", round(quantile(results$posterior_samples$theta_pfs_post, 0.025), 3),
        ",", round(quantile(results$posterior_samples$theta_pfs_post, 0.975), 3), "]\n")
    cat("  Note: PFS data is already observed; showing posterior for reference.\n\n")
    
    cat("Interpretation:\n")
    if (pos_os >= 0.80) {
      cat("  High PoS for OS (≥80%) - Strong evidence target will be met\n")
    } else if (pos_os >= 0.50) {
      cat("  Moderate PoS for OS (50-80%) - Some evidence target will be met\n")
    } else {
      cat("  Low PoS for OS (<50%) - Weak evidence target will be met\n")
    }
  })
  
  # ===========================================================================
  # SCATTER PLOT - 27+1 TRIALS
  # ===========================================================================
  
  output$scatter_plot <- renderPlot({
    # Create plot data
    plot_data <- historical_data() %>%
      mutate(type = "Historical") %>%
      bind_rows(
        tibble(
          loghr_pfs = input$loghr_pfs_interim,
          loghr_os = input$loghr_os_interim,
          type = "Current Trial"
        )
      )
    
    # Calculate correlation
    hist_only <- plot_data %>% filter(type == "Historical")
    corr_val <- cor(hist_only$loghr_pfs, hist_only$loghr_os)
    
    ggplot(plot_data, aes(x = loghr_pfs, y = loghr_os, color = type, shape = type)) +
      geom_point(size = 4, alpha = 0.7) +
      geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray50") +
      scale_color_manual(values = c("Historical" = "steelblue", "Current Trial" = "red")) +
      scale_shape_manual(values = c("Historical" = 16, "Current Trial" = 18)) +
      theme_minimal(base_size = 14) +
      labs(
        title = "Trial-Level Effects: PFS vs OS",
        subtitle = sprintf("Between-trial correlation: %.3f (n=27 historical trials + 1 current)", corr_val),
        x = "log(HR) for PFS",
        y = "log(HR) for OS",
        color = "Trial Type",
        shape = "Trial Type"
      ) +
      theme(legend.position = "bottom")
  })
  
} # End server function
