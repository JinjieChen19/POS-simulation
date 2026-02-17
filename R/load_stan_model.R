#' Load Precompiled Stan Model
#'
#' @description
#' Loads the precompiled Stan model from the package installation.
#' If not found, returns NULL and the app will fall back to compilation.
#'
#' @return Stan model object or NULL if not found
#' @export
#'
#' @examples
#' \dontrun{
#' model <- load_precompiled_stan_model()
#' if (!is.null(model)) {
#'   # Use precompiled model
#' } else {
#'   # Compile from source
#' }
#' }
load_precompiled_stan_model <- function() {
  # Try package installation path first
  precompiled_path <- system.file("stan/stan_model_compiled.rds", package = "POSsimulation")
  
  if (precompiled_path != "" && file.exists(precompiled_path)) {
    tryCatch({
      model <- readRDS(precompiled_path)
      message("Loaded precompiled Stan model from package")
      return(model)
    }, error = function(e) {
      warning("Failed to load precompiled Stan model: ", e$message)
      return(NULL)
    })
  }
  
  # Try local development path
  local_paths <- c(
    "inst/stan/stan_model_compiled.rds",
    "stan_model_compiled.rds",
    "../stan_model_compiled.rds"
  )
  
  for (path in local_paths) {
    if (file.exists(path)) {
      tryCatch({
        model <- readRDS(path)
        message("Loaded precompiled Stan model from: ", path)
        return(model)
      }, error = function(e) {
        warning("Failed to load precompiled Stan model from ", path, ": ", e$message)
      })
    }
  }
  
  # No precompiled model found
  return(NULL)
}
