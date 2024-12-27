#' Parallelised matching of plant taxonomic names against WCVP
#'
#' Parallelised version of [rWCVP::wcvp_match_names()] to check plant taxonomic names
#' against the World Checklist of Vascular Plants (WCVP), using [future.apply::future.apply()].
#'
#' @param df Data frame containing taxonomic names to be matched against WCVP.
#' @param name_col Character. The column in 'df' containing the taxon names for matching.
#' @param author_col Character. The column in 'df' that has the name authority, to aid matching.
#' Set to NULL to match with no author string.
#' @param fuzzy Logical; whether or not fuzzy matching should be used for names that could not be matched exactly.
#' @param plan Character. Name of a [future::plan()] to be used for parallelisation.
#' Recommended plan is "multisession". Use "sequential" for non-parallel processing.
#' @param cores Number of cores to use in parallel.
#' @param ... Further arguments to be passed to [rWCVP::wcvp_match_names()]
#'
#' @return A data frame
#' @export
#'
#' @examples
#' \dontrun{
#' df <- data.frame(taxon = c("Laurus nobilis", "Laurus nobilis", "Laurus nobili"),
#'                   author = c(NA, "L.", NA))
#' out <- wcvp_match_names_parallel(df, name_col = "taxon", author_col = "author",
#'   cores = 3)
#' }

wcvp_match_names_parallel <- function(df = NULL,
                                      name_col = NULL,
                                      author_col = NULL,
                                      fuzzy = TRUE,
                                      plan = "multisession",
                                      cores = 1,
                                      ...
) {

  # Parallelise using future.apply package
  if (!is.null(plan)) {
    stopifnot(plan %in% c("sequential", "multisession", "multicore", "cluster"))
    ## return to former plan on exit
    oplan <- future::plan()
    on.exit(future::plan(oplan), add = TRUE)

    stopifnot(is.numeric(cores))
    if (cores > future::availableCores()) {
      stop("'cores' can't be higher than the number of available cores: ", future::availableCores(), ".\n")
    }
    future::plan(plan, workers = cores)
  }


  # Remove duplicated taxa
  df.unique <- dplyr::distinct(df, dplyr::pick(dplyr::any_of(c(name_col, author_col))), .keep_all = TRUE)
  if (nrow(df.unique) < nrow(df)) {
    message("Some taxa were duplicated in the original data frame. Returning results for ",
            nrow(df.unique), " unique taxa.")
  }

  # Split df and run match_names in parallel
  #https://stackoverflow.com/a/71717780
  df.list <- split(df.unique, (1:nrow(df.unique) - 1) %/% ceiling(nrow(df.unique) / cores))
  out.list <- future.apply::future_lapply(df.list,
                                          rWCVP::wcvp_match_names,
                                          name_col = name_col,
                                          author_col = author_col,
                                          fuzzy = fuzzy,
                                          progress = FALSE,
                                          ...)

  out <- do.call(rbind, out.list)

}





#' Resolve multiple matches in WCVP
#'
#' This function tries to resolve automatically the cases of multiple matches found
#' after running a vector of taxonomic names against the World Checklist of Vascular Plants (WCVP).
#'
#' @author Adapted from `rWCVP` [vignette](https://matildabrown.github.io/rWCVP/articles/redlist-name-matching.html#multiple-matches)
#' @seealso https://matildabrown.github.io/rWCVP/articles/redlist-name-matching.html
#'
#' @param df Data frame with matching results, as produced by [rWCVP::wcvp_match_names()] or
#' [wcvp_match_names_parallel()]
#' @param name_col Character. Name of the column in 'df' containing the taxon names.
#'
#' @return A data frame
#' @export
#'
#' @examples
#' \dontrun{
#' df <- data.frame(taxon = "Acacia dealbata")
#' matching <- wcvp_match_names_parallel(df, name_col = "taxon")
#' out <- wcvp_resolve_multiple_matches(matching, name_col = "taxon")
#' }

wcvp_resolve_multiple_matches <- function(df = NULL, name_col = NULL) {

  df |>
    dplyr::nest_by(.data[[name_col]]) |>
    dplyr::mutate(data = list(resolve_multi(data))) |>
    tidyr::unnest(col = data) |>
    dplyr::ungroup() |>
    dplyr::mutate(resolved_match_type = dplyr::case_when(
      is.na(resolved_match_type) & is.na(match_type) ~ "No match found",
      is.na(resolved_match_type) ~ match_type,
      TRUE ~ resolved_match_type
    ))

}


resolve_multi <- function(df) {

  out <- df |>
    dplyr::mutate(resolved_match_type = match_type)
  if (nrow(out) == 1) return(out)

  # If one or more matches have the same author string, we keep them.
  if ("wcvp_author_edit_distance" %in% names(df)) {
    out <- out |>
      dplyr::filter(wcvp_author_edit_distance == 0 | !sum(wcvp_author_edit_distance == 0, na.rm = TRUE))
    if (nrow(out) == 1) return(out)
  }


  # If one (and only one) of the matches is Accepted, we keep that one.
  out <- out |>
    dplyr::filter(wcvp_status == "Accepted" | !sum(wcvp_status == "Accepted"))
  if (nrow(out) == 1) return(out)

  # If one (and only one) of the matches is a Synonym (as opposed to Invalid, Illegitimate, etc), we keep that one.
  synonym_codes <- c("Synonym", "Orthographic", "Artificial Hybrid", "Unplaced")
  out <- out |>
    dplyr::filter(wcvp_status %in% synonym_codes | !sum(wcvp_status %in% synonym_codes))
  if (nrow(out) == 1) return(out)

  n_matches <- length(unique(out$wcvp_accepted_id)) / nrow(out)
  final <- utils::head(out, 1)

  if (n_matches != 1) {
    final <- final |>
      dplyr::mutate(
        dplyr::across(wcvp_id:resolved_match_type & where(is.numeric), ~NA_real_),
        dplyr::across(wcvp_id:resolved_match_type & where(is.character), ~NA_character_),
        resolved_match_type = "Could not resolve multiple matches"
      )
  }

  final

}

