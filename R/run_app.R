#' Run Bayesian PoS Simulation App
#'
#' Launches the Bayesian Probability of Success simulation Shiny application.
#' This is the main version with all features including Model Description and Help tabs.
#'
#' @param host Host IP address. Use "127.0.0.1" for local only, or "0.0.0.0" to allow
#'   network access. Default is "127.0.0.1".
#' @param port Port number for the application. Default is 3838.
#' @param launch.browser If TRUE, opens the app in the default web browser. Default is TRUE.
#' @param ... Additional arguments passed to \code{shiny::runApp()}.
#'
#' @return No return value, called for side effects (launches Shiny app).
#'
#' @examples
#' \dontrun{
#' # Run app locally
#' run_pos_app()
#'
#' # Run app and allow network access
#' run_pos_app(host = "0.0.0.0", port = 3838)
#' }
#'
#' @export
#' @import rstan
#' @import shiny
#' @import shinythemes
#' @import shinymanager
#' @import tidyverse
#' @import ggplot2
#' @import bayesplot
#' @import digest
#' @importFrom dplyr filter select mutate arrange summarise group_by ungroup bind_rows across everything
#' @importFrom DT datatable renderDT DTOutput
#' @importFrom gridExtra grid.arrange
#' @importFrom MASS mvrnorm
run_pos_app <- function(host = "127.0.0.1", port = 3838, launch.browser = TRUE, ...) {
  app_dir <- system.file("shiny", package = "POSsimulation")
  
  if (app_dir == "") {
    stop("Could not find app directory. Try re-installing `POSsimulation`.", call. = FALSE)
  }
  
  shiny::runApp(
    appDir = app_dir,
    host = host,
    port = port,
    launch.browser = launch.browser,
    ...
  )
}


#' Run Bayesian PoS Simulation App (Local Server Version)
#'
#' Launches the optimized local server version of the app with pre-compiled Stan models
#' and real-time progress display. This version is optimized for team access on local
#' networks with single Stan model compilation at startup.
#'
#' @param host Host IP address. Use "127.0.0.1" for local only, or "0.0.0.0" to allow
#'   network access. Default is "0.0.0.0" for team access.
#' @param port Port number for the application. Default is 3838.
#' @param launch.browser If TRUE, opens the app in the default web browser. Default is TRUE.
#' @param ... Additional arguments passed to \code{shiny::runApp()}.
#'
#' @details
#' The local server version includes:
#' \itemize{
#'   \item Universal Stan model compiled once at startup
#'   \item Prior changes passed as data (no recompilation needed)
#'   \item Real-time MCMC sampling progress display
#'   \item Optimized for multi-user access
#'   \item Non-centered parameterization for better sampling
#'   \item User-configurable PoS target thresholds
#' }
#'
#' @return No return value, called for side effects (launches Shiny app).
#'
#' @examples
#' \dontrun{
#' # Run local server version for team access
#' run_pos_app_local()
#'
#' # Custom port
#' run_pos_app_local(port = 8080)
#' }
#'
#' @export
#' @importFrom shiny runApp
run_pos_app_local <- function(host = "0.0.0.0", port = 3838, launch.browser = TRUE, ...) {
  app_dir <- system.file("shiny/local", package = "POSsimulation")
  
  if (app_dir == "") {
    stop("Could not find local app directory. Try re-installing `POSsimulation`.", call. = FALSE)
  }
  
  message("=== Starting Bayesian PoS Simulation App (Local Server Version) ===")
  message("NOTE: Stan model compilation will occur at startup (1-2 minutes).")
  message("After compilation, prior changes will be instant (no recompilation needed).")
  message("")
  
  shiny::runApp(
    appDir = app_dir,
    host = host,
    port = port,
    launch.browser = launch.browser,
    ...
  )
}


#' Run Bayesian PoS Simulation App (Authenticated Version)
#'
#' Launches the app with username/password authentication using shinymanager.
#' Useful for remote access or when sharing the app with specific team members.
#'
#' @param host Host IP address. Use "127.0.0.1" for local only, or "0.0.0.0" to allow
#'   network access. Default is "0.0.0.0" for remote access.
#' @param port Port number for the application. Default is 3838.
#' @param launch.browser If TRUE, opens the app in the default web browser. Default is TRUE.
#' @param ... Additional arguments passed to \code{shiny::runApp()}.
#'
#' @details
#' The authenticated version includes a login screen before app access.
#' Default users (CHANGE THESE PASSWORDS!):
#' \itemize{
#'   \item admin / Change_This_Password_123!
#'   \item analyst1 / Analyst_Pass_456!
#' }
#'
#' To customize users, edit the credentials in inst/shiny/authenticated/app.R
#'
#' @return No return value, called for side effects (launches Shiny app).
#'
#' @examples
#' \dontrun{
#' # Run authenticated version
#' run_pos_app_authenticated()
#' }
#'
#' @export
#' @importFrom shiny runApp
run_pos_app_authenticated <- function(host = "0.0.0.0", port = 3838, launch.browser = TRUE, ...) {
  app_dir <- system.file("shiny/authenticated", package = "POSsimulation")
  
  if (app_dir == "") {
    stop("Could not find authenticated app directory. Try re-installing `POSsimulation`.", call. = FALSE)
  }
  
  message("=== Starting Bayesian PoS Simulation App (Authenticated Version) ===")
  message("Default login: admin / Change_This_Password_123!")
  message("WARNING: Change default passwords before deployment!")
  message("")
  
  shiny::runApp(
    appDir = app_dir,
    host = host,
    port = port,
    launch.browser = launch.browser,
    ...
  )
}
