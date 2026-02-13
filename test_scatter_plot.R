# Quick test to verify scatter plot code works
library(tidyverse)
library(MASS)

# Generate test data using same algorithm
set.seed(20260212)
K <- 27

mu_true  <- c(-0.30, -0.45)
tau_true <- c(0.15, 0.15)
rho_true <- 0.65

R_true <- matrix(c(1, rho_true, rho_true, 1), 2, 2, byrow = TRUE)
Sigma_true <- diag(tau_true) %*% R_true %*% diag(tau_true)

theta <- MASS::mvrnorm(n = K, mu = mu_true, Sigma = Sigma_true)

se_os  <- runif(K, 0.10, 0.13)
se_pfs <- runif(K, 0.08, 0.11)
rho_within <- runif(K, 0.55, 0.75)

y <- matrix(NA_real_, nrow = K, ncol = 2)

for (k in 1:K) {
  cov_k <- rho_within[k] * se_os[k] * se_pfs[k]
  W_k <- matrix(c(se_os[k]^2, cov_k, cov_k, se_pfs[k]^2), 2, 2, byrow = TRUE)
  y[k, ] <- MASS::mvrnorm(n = 1, mu = theta[k, ], Sigma = W_k)
}

historical_data <- data.frame(
  loghr_os = y[, 1],
  loghr_pfs = y[, 2],
  type = "Historical"
)

current_trial <- data.frame(
  loghr_os = -0.35,
  loghr_pfs = -0.48,
  type = "Current"
)

plot_data <- rbind(
  historical_data[, c("loghr_pfs", "loghr_os", "type")],
  current_trial[, c("loghr_pfs", "loghr_os", "type")]
)

between_cor <- cor(historical_data$loghr_pfs, historical_data$loghr_os)

cat("Data generated successfully!\n")
cat("Number of historical trials:", nrow(historical_data), "\n")
cat("Between-trial correlation:", round(between_cor, 3), "\n")
cat("OS range:", round(range(historical_data$loghr_os), 3), "\n")
cat("PFS range:", round(range(historical_data$loghr_pfs), 3), "\n")

# Create plot
p <- ggplot(plot_data, aes(x = loghr_pfs, y = loghr_os, color = type, size = type)) +
  geom_point(alpha = 0.7) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray50", linewidth = 0.5) +
  geom_point(data = current_trial, aes(x = loghr_pfs, y = loghr_os), 
             color = "red", size = 5, shape = 18) +
  annotate("text", x = current_trial$loghr_pfs, y = current_trial$loghr_os - 0.03,
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

ggsave("scatter_plot_preview.png", p, width = 10, height = 8, dpi = 150)
cat("\nScatter plot saved to scatter_plot_preview.png\n")
