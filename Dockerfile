# =============================================================================
# Dockerfile for Bayesian PoS Simulation (Fly.io Deployment)
# =============================================================================
# Based on requirements from Chinese deployment guide:
# - Use rocker/shiny-verse:latest as base
# - Install system deps: libv8-dev, libnode-dev, clang
# - Install R packages via remotes::install_cran
# - Optimize Stan compilation with CXXFLAGS
# =============================================================================

FROM rocker/shiny-verse:latest

# =============================================================================
# IMPORTANT: Stan Compilation Optimization
# =============================================================================
# For production Stan models, set CXXFLAGS to optimize compilation:
# ENV CXXFLAGS="-O3 -march=native"
# This significantly speeds up Stan model execution but may reduce portability.
# Uncomment above line for maximum performance on the target hardware.
# =============================================================================

# Install system dependencies required for rstan and app
# - libv8-dev: Required for V8 JavaScript engine
# - libnode-dev: Node.js development files
# - clang: Alternative C++ compiler (can improve Stan compilation)
# - Additional dependencies for rstan and tidyverse
RUN apt-get update && apt-get install -y \
    libv8-dev \
    libnode-dev \
    clang \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages using remotes::install_cran for better dependency resolution
# This ensures all package dependencies are properly installed
# Note: 'digest' is included for model caching functionality
RUN R -e "install.packages('remotes', repos='https://cloud.r-project.org/')" && \
    R -e "remotes::install_cran(c('shiny', 'shinythemes', 'tidyverse', 'rstan', 'bayesplot', 'DT', 'gridExtra', 'MASS', 'digest'), repos='https://cloud.r-project.org/')"

# Create app directory
WORKDIR /app

# Copy application files
# Note: Using the standard files (global.R, server.R, ui.R)
# These should be the production-ready versions
COPY global.R /app/global.R
COPY server.R /app/server.R
COPY ui.R /app/ui.R

# Create cache directory for pre-compiled Stan models
RUN mkdir -p /app/cache

# Expose port 3838 (Shiny default, configured in fly.toml)
EXPOSE 3838

# Run Shiny app on 0.0.0.0:3838 (required for Fly.io)
CMD ["R", "-e", "shiny::runApp('/app', host='0.0.0.0', port=3838)"]
