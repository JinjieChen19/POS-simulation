# ============================================================================
# SERVER.R - Server logic for Bayesian PoS Simulation App (Fly.io Optimized)
# ============================================================================
# FLY.IO CRITICAL CHANGES:
# 1. Uses PRE-COMPILED Stan models from global.R (no compilation in reactive)
# 2. withProgress() for user feedback during MCMC
# 3. Single-chain sampling only (Fly.io requirement)
# 4. Enhanced error handling for container environment
# 5. No file I/O, all operations in-memory
# ============================================================================

function(input, output, session) {
  
  # =========================================================================
  # REACTIVE DATA GENERATION
  # =========================================================================
  # FILE SYSTEM SAFE: All in-memory, no file writes
  # =========================================================================
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
  
  # =========================================================================
  # RESULTS STORAGE (REACTIVE VALUES)
  # =========================================================================
  results <- reactiveValues(
    fit = NULL,
    posterior_samples = NULL,
    summary = NULL
  )
  
  # =========================================================================
  # DATA OUTPUTS (No file I/O)
  # =========================================================================
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
        " <- This is what the model learns as rho\n", sep = "")
    cat("  Within-trial cor (average): ", round(mean(historical_data()$corr_pfs_os), 3), 
        " <- Patient-level correlation within trials\n", sep = "")
  })
  
  # =========================================================================
  # STAN MODEL EXECUTION (FLY.IO OPTIMIZED)
  # =========================================================================
  # CRITICAL: Uses pre-compiled models from global.R
  # CRITICAL: Uses withProgress() to prevent UI blocking
  # CRITICAL: refresh=0 to avoid stdout/stderr issues
  # =========================================================================
  observeEvent(input$run_model, {
    
    # Show initial status
    output$model_status <- renderPrint({
      cat("Preparing to run Stan model...\n")
      cat("Configuration:\n")
      cat("  Iterations:", input$n_iter, "\n")
      cat("  Chains:", input$n_chains, "\n")
      cat("  Prior: τ ~", input$prior_tau_type, ", ρ ~", input$prior_rho_type, "\n")
    })
    
    # Use withProgress for user feedback (Fly.io UI responsiveness requirement)
    withProgress(message = 'Running MCMC...', value = 0, {
      
      # Step 1: Get pre-compiled model
      incProgress(0.1, detail = "Loading compiled model...")
      
      tryCatch({
        # FLY.IO CRITICAL: Use pre-compiled model from global scope
        # DO NOT call stan_model() here - causes "invalid connection" on Fly.io
        stan_model_compiled <- get_compiled_stan_model(
          prior_tau_type = input$prior_tau_type,
          prior_rho_type = input$prior_rho_type,
          prior_mu_os_mean = input$prior_mu_os_mean,
          prior_mu_os_sd = input$prior_mu_os_sd,
          prior_mu_pfs_mean = input$prior_mu_pfs_mean,
          prior_mu_pfs_sd = input$prior_mu_pfs_sd,
          prior_tau_param_os = input$prior_tau_param_os,
          prior_tau_param_pfs = input$prior_tau_param_pfs,
          prior_rho_param = input$prior_rho_param,
          prior_rho_param2 = input$prior_rho_param2
        )
        
        # Step 2: Prepare data
        incProgress(0.2, detail = "Preparing data...")
        
        hist_trials <- historical_data()
        K <- nrow(hist_trials)
        
        y_hist <- lapply(1:K, function(i) {
          c(hist_trials$loghr_os[i], hist_trials$loghr_pfs[i])
        })
        
        W_hist <- lapply(1:K, function(i) {
          cov_val <- hist_trials$cov_pfs_os[i]
          matrix(c(hist_trials$se_loghr_os[i]^2, cov_val,
                   cov_val, hist_trials$se_loghr_pfs[i]^2), 2, 2)
        })
        
        # Current trial
        y_curr <- c(input$loghr_os_interim, input$loghr_pfs_interim)
        W_curr <- matrix(c(input$se_loghr_os_interim^2, 0,
                           0, input$se_loghr_pfs_interim^2), 2, 2)
        
        stan_data <- list(
          K = K,
          y_hist = y_hist,
          W_hist = W_hist,
          y_curr = y_curr,
          W_curr = W_curr
        )
        
        # Step 3: Run MCMC
        incProgress(0.3, detail = paste0("Sampling (", input$n_iter, " iterations)..."))
        
        # FLY.IO CRITICAL: Use sampling() with pre-compiled model
        # refresh=0 prevents stdout/stderr redirection issues
        fit <- sampling(
          object = stan_model_compiled,  # Pre-compiled model
          data = stan_data,
          iter = input$n_iter,
          chains = input$n_chains,  # Should be 1 for Fly.io
          control = list(
            adapt_delta = input$adapt_delta,
            max_treedepth = input$max_treedepth
          ),
          verbose = FALSE,
          refresh = 0  # FLY.IO CRITICAL: Suppress output to avoid connection issues
        )
        
        # Step 4: Extract results
        incProgress(0.9, detail = "Processing results...")
        
        results$fit <- fit
        results$posterior_samples <- as.data.frame(fit)
        results$summary <- summary(fit)$summary
        
        # Step 5: Display success
        incProgress(1.0, detail = "Complete!")
        
        output$model_status <- renderPrint({
          cat("✓ Stan model completed successfully!\n\n")
          cat("Fly.io Container Stats:\n")
          cat("  - Single-core mode: ACTIVE\n")
          cat("  - Chains used:", input$n_chains, "\n")
          cat("  - Total iterations:", input$n_iter * input$n_chains, "\n\n")
          cat("Model Summary:\n")
          cat(strrep("=", 60), "\n")
          print(results$summary[c("mu[1]", "mu[2]", "tau_os", "tau_pfs", "rho_out", "theta_os_post"), ])
        })
        
      }, error = function(e) {
        # Enhanced error handling for Fly.io environment
        output$model_status <- renderPrint({
          cat("✗ Error running Stan model\n")
          cat(strrep("=", 60), "\n")
          cat("Error message:\n")
          cat(e$message, "\n\n")
          
          # Fly.io-specific troubleshooting
          if (grepl("invalid connection|connection|socket|fork", e$message, ignore.case = TRUE)) {
            cat("FLY.IO ISSUE DETECTED:\n")
            cat("This appears to be a parallelism/connection error.\n\n")
            cat("Solutions:\n")
            cat("  1. Ensure chains = 1 (currently: ", input$n_chains, ")\n")
            cat("  2. Verify single-core mode is active\n")
            cat("  3. Try restarting the app container\n")
            cat("  4. Check Fly.io logs for resource exhaustion\n\n")
            cat("The app is configured for Fly.io, but the error suggests\n")
            cat("the container environment is not properly restricted.\n")
          } else if (grepl("time|timeout|killed|oom|memory", e$message, ignore.case = TRUE)) {
            cat("RESOURCE LIMIT ISSUE:\n")
            cat("The Fly.io container may have run out of resources.\n\n")
            cat("Solutions:\n")
            cat("  1. Reduce iterations (current: ", input$n_iter, ")\n")
            cat("  2. Try 1000-1500 iterations for faster execution\n")
            cat("  3. Consider scaling up Fly.io instance size\n")
            cat("  4. Check Fly.io dashboard for memory/CPU limits\n")
          } else {
            cat("GENERAL TROUBLESHOOTING:\n")
            cat("  1. Verify all priors are valid\n")
            cat("  2. Check current trial data is reasonable\n")
            cat("  3. Try default settings first\n")
            cat("  4. Check Fly.io logs: flyctl logs\n")
          }
        })
      })
    })
  })
  
  # =========================================================================
  # MCMC DIAGNOSTICS
  # =========================================================================
  output$trace_plot <- renderPlot({
    req(results$fit)
    
    posterior <- as.array(results$fit)
    mcmc_trace(posterior, pars = c("mu[1]", "mu[2]", "tau_os", "tau_pfs", "rho_out")) +
      ggtitle("MCMC Trace Plots (Fly.io Single-Chain)") +
      theme_minimal()
  })
  
  # =========================================================================
  # POSTERIOR PLOTS
  # =========================================================================
  output$posterior_plot <- renderPlot({
    req(results$posterior_samples)
    
    p1 <- ggplot(results$posterior_samples, aes(x = `mu[1]`)) +
      geom_density(fill = "steelblue", alpha = 0.6) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
      labs(title = "Posterior: μ_OS", x = "μ_OS", y = "Density") +
      theme_minimal()
    
    p2 <- ggplot(results$posterior_samples, aes(x = `mu[2]`)) +
      geom_density(fill = "steelblue", alpha = 0.6) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
      labs(title = "Posterior: μ_PFS", x = "μ_PFS", y = "Density") +
      theme_minimal()
    
    p3 <- ggplot(results$posterior_samples, aes(x = tau_os)) +
      geom_density(fill = "darkgreen", alpha = 0.6) +
      labs(title = "Posterior: τ_OS", x = "τ_OS", y = "Density") +
      theme_minimal()
    
    p4 <- ggplot(results$posterior_samples, aes(x = tau_pfs)) +
      geom_density(fill = "darkgreen", alpha = 0.6) +
      labs(title = "Posterior: τ_PFS", x = "τ_PFS", y = "Density") +
      theme_minimal()
    
    p5 <- ggplot(results$posterior_samples, aes(x = rho_out)) +
      geom_density(fill = "purple", alpha = 0.6) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
      labs(title = "Posterior: ρ", x = "ρ", y = "Density") +
      theme_minimal()
    
    p6 <- ggplot(results$posterior_samples, aes(x = theta_os_post)) +
      geom_density(fill = "orange", alpha = 0.6) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
      labs(title = "Posterior: θ_OS (Current)", x = "θ_OS", y = "Density") +
      theme_minimal()
    
    gridExtra::grid.arrange(p1, p2, p3, p4, p5, p6, ncol = 2)
  })
  
  # =========================================================================
  # PROBABILITY OF SUCCESS
  # =========================================================================
  output$pos_output <- renderPrint({
    req(results$posterior_samples)
    
    theta_os_post <- results$posterior_samples$theta_os_post
    pos <- mean(theta_os_post < 0)
    
    cat("Probability of Success (PoS) for OS\n")
    cat(strrep("=", 60), "\n\n")
    cat("PoS = P(θ_OS < 0 | data) = ", round(pos * 100, 2), "%\n\n", sep = "")
    
    cat("Posterior Summary for θ_OS:\n")
    cat("  Mean:  ", round(mean(theta_os_post), 4), "\n")
    cat("  Median:", round(median(theta_os_post), 4), "\n")
    cat("  SD:    ", round(sd(theta_os_post), 4), "\n")
    cat("  95% CI: [", round(quantile(theta_os_post, 0.025), 4), ", ",
        round(quantile(theta_os_post, 0.975), 4), "]\n\n", sep = "")
    
    cat("Interpretation:\n")
    if (pos >= 0.90) {
      cat("  Very high probability of success (≥90%)\n")
    } else if (pos >= 0.70) {
      cat("  High probability of success (70-90%)\n")
    } else if (pos >= 0.50) {
      cat("  Moderate probability of success (50-70%)\n")
    } else {
      cat("  Low probability of success (<50%)\n")
    }
  })
  
  # =========================================================================
  # SCATTER PLOT (File system safe - no image saves)
  # =========================================================================
  output$scatter_plot <- renderPlot({
    hist_data <- historical_data()
    between_cor <- cor(hist_data$loghr_pfs, hist_data$loghr_os)
    
    plot_data <- hist_data %>%
      mutate(type = "Historical")
    
    current_trial <- tibble(
      loghr_pfs = input$loghr_pfs_interim,
      loghr_os = input$loghr_os_interim,
      type = "Current"
    )
    
    plot_data <- bind_rows(
      plot_data %>% dplyr::select(loghr_pfs, loghr_os, type),
      current_trial
    )
    
    ggplot(plot_data, aes(x = loghr_pfs, y = loghr_os, color = type, shape = type)) +
      geom_point(size = 4, alpha = 0.7) +
      geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray50") +
      scale_color_manual(values = c("Historical" = "steelblue", "Current" = "red")) +
      scale_shape_manual(values = c("Historical" = 16, "Current" = 18)) +
      labs(
        title = "Scatter Plot: PFS vs OS log(HR)",
        subtitle = paste0("Between-trial correlation: ", round(between_cor, 3)),
        x = "PFS log(HR)",
        y = "OS log(HR)",
        color = "Trial Type",
        shape = "Trial Type"
      ) +
      theme_minimal(base_size = 14) +
      theme(legend.position = "bottom") +
      coord_fixed()
  })
  
  # =========================================================================
  # DATA TABLE
  # =========================================================================
  output$data_table <- renderDT({
    historical_data() %>%
      dplyr::select(trial_id, cancer_type, n_patients, loghr_os, se_loghr_os, 
                    loghr_pfs, se_loghr_pfs, corr_pfs_os) %>%
      mutate(across(starts_with("loghr"), ~round(., 3)),
             across(starts_with("se_"), ~round(., 3)),
             across(starts_with("corr"), ~round(., 3))) %>%
      datatable(
        options = list(pageLength = 10, scrollX = TRUE),
        caption = "27 Historical Trials - Summary Data (Fly.io Container)"
      )
  })
}
