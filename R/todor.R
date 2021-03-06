#' TODOR
#' This package helps you to find all code rows in your code with places
#' to be filled in the future.
#'
#' @name todor
NULL

#' Default patterns
DEFAULT_PATTERNS <- "default.csv"

rex::register_shortcuts("todor")

#' Todor addin
#'
#' Called on project that are not R packages. Checks all places in the code which require amendents
#' as specified in \code{todo_types} on R and r files. When option \code{todor_rmd} is set to TRUE
#' it searches also through Rmd files. Unless option \code{todor_exlude_packrat} is set to FALSE, all files in the packrat directory are excluded.
#' It triggers rstudio markers to appear.
#'
#' @param todo_types vector with character describing types of elements to detect.
#' If NULL default items will be used.
#' @param search_path vector with paths that contains comments you are looking for.
#' @param file character with path to file. If not NULL the search_path will be ignored.
#'
#' @export
#' @import rex
#' @import utils
todor <- function(todo_types = NULL, search_path = getwd(), file = NULL) {
  if (is.null(file)) {
    files <- dir(
      path = search_path,
      pattern = rex::rex(".", one_of("Rr"), end),
      recursive = TRUE,
      full.names = TRUE
    )
    if (getOption("todor_rmd", FALSE)) {
      rmdfiles <- list_files_with_extension("Rmd", search_path)
      files <- c(files, rmdfiles)
    }
    if (getOption("todor_rnw", FALSE)) {
      rnwfiles <- list_files_with_extension("Rnw", search_path)
      files <- c(files, rnwfiles)
    }
    if (getOption("todor_rhtml", FALSE)) {
      rhtmlfiles <- list_files_with_extension("Rhtml", search_path)
      files <- c(files, rhtmlfiles)
    }

    if (getOption("todor_exclude_packrat", TRUE)) {
      # Remove all filesnames, which include the packrat directory
      files <- files[!stringr::str_detect(files, "/packrat/")]
    }
  }
  else {
    if (!file.exists(file))
      stop("File does not exists!")
    else
      files <- file
  }
  # Default TODO types
  patterns <- as.character(read.csv(
    system.file(DEFAULT_PATTERNS, package = "todor"),
    stringsAsFactors = FALSE, header = FALSE)
  )

  if (is.null(todo_types))
    todo_types <- patterns
  else {
    if (!all(todo_types %in% patterns))
      stop(paste("One or more 'todo_types' were not recognized.",
           "See documentation of 'todor' for more information"))
  }
  processed <- lapply(files, function(x) process_file(x, todo_types))
  names(processed) <- files
  markers <- create_markers(processed)
  build_rstudio_markers(markers)
}

#' Todor Package addin
#'
#' Called on packages. Checks all places in the code which require amendents
#' as specified in \code{todo_types}.
#' It triggers rstudio markers to appear.
#'
#' @param todo_types vector with character describing types of elements to detect.
#' If NULL default items will be used.
#'
#' @export
todor_package <- function(todo_types = NULL) {
  pkg_path    <- find_package()
  search_path <- file.path(pkg_path,
                           c("R", "tests", "inst")
                  )
  todor(todo_types = todo_types, search_path = search_path)
}

#' Todor file
#'
#' @param file_name character with file name
#' @param todo_types vector with character describing types of elements to detect.
#' If NULL default items will be used.
#'
#' @export
todor_file <- function(file_name, todo_types = NULL) {
  todor(todo_types = todo_types, file = file_name)
}

#' Todor project addin
#'
#' Calls \code{todor} function.
#'
#' @export
#' @import rstudioapi
todor_project_addin <- function() {
  project_path <- rstudioapi::getActiveProject()
  if (is.null(project_path))
    stop(paste0("You're not within R project. Change to project, ",
                "or use `todor_file` instead."))
  todor(search_path = project_path)
}

#' Todor package addin
#'
#' Calls \code{todor_package} function.
#'
#' @export
todor_package_addin <- function() {
  todor_package()
}
