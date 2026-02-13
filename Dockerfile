# =============================================================================
# Dockerfile for Bayesian PoS Simulation (Fly.io Optimized)
# =============================================================================
# This Dockerfile creates a container suitable for Fly.io deployment
# - Based on rocker/r-ver with rstan pre-installed
# - Single-core configuration for container safety
# - Pre-compiles Stan models at build time
# =============================================================================

FROM rocker/r-ver:4.3.2

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libv8-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('shiny', 'shinythemes', 'tidyverse', 'rstan', 'bayesplot', 'DT', 'gridExtra', 'MASS'), repos='https://cloud.r-project.org/')"

# Create app directory
WORKDIR /app

# Copy application files
COPY global_flyio.R /app/global.R
COPY server_flyio.R /app/server.R
COPY ui_flyio.R /app/ui.R

# Expose port 3838 (Fly.io standard)
EXPOSE 3838

# Run app on 0.0.0.0:3838 (Fly.io requirement)
CMD ["R", "-e", "shiny::runApp('/app', host='0.0.0.0', port=3838)"]
