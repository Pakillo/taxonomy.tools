test_that("wcvp_match_names_parallel works", {

  skip_on_ci()

  df <- data.frame(taxon = c("Laurus nobilis", "Laurus nobilis", "Laurus nobili"),
                    author = c(NA, "L.", NA))
  out <- wcvp_match_names_parallel(df, name_col = "taxon", author_col = "author")
  # constructive::construct(out)

  expect_equal(out,
               data.frame(
                 taxon = c("Laurus nobilis", "Laurus nobilis", "Laurus nobili"),
                 author = c(NA, "L.", NA),
                 match_type = c("Exact (without author)", "Exact (with author)", "Fuzzy (edit distance)"),
                 multiple_matches = logical(3),
                 match_similarity = c(1, 1, 0.929),
                 match_edit_distance = c(0, 0, 1),
                 wcvp_id = rep(2349094, 3L),
                 wcvp_name = rep("Laurus nobilis", 3L),
                 wcvp_authors = rep("L.", 3L),
                 wcvp_rank = rep("Species", 3L),
                 wcvp_status = rep("Accepted", 3L),
                 wcvp_homotypic = rep(NA, 3L),
                 wcvp_ipni_id = rep("465049-1", 3L),
                 wcvp_accepted_id = rep(2349094, 3L),
                 wcvp_author_edit_distance = c(NA, 0, NA),
                 wcvp_author_lcs = c(-1L, 2L, -1L),
                 row.names = c("0.1", "0.2", "0.3")
               ) |>
                 structure(class = c("tbl_df", "tbl", "data.frame"))
  )
})



test_that("wcvp_resolve_multiple_matches works", {

  skip_on_ci()

  df <- data.frame(taxon = "Acacia dealbata")
  matching <- wcvp_match_names_parallel(df, name_col = "taxon")
  out <- wcvp_resolve_multiple_matches(matching, name_col = "taxon")

  expect_equal(as.data.frame(out),
               data.frame(
                 taxon = "Acacia dealbata",
                 match_type = "Exact (without author)",
                 multiple_matches = TRUE,
                 match_similarity = 1,
                 match_edit_distance = 0,
                 wcvp_id = 2611879,
                 wcvp_name = "Acacia dealbata",
                 wcvp_authors = "Link",
                 wcvp_rank = "Species",
                 wcvp_status = "Accepted",
                 wcvp_homotypic = NA,
                 wcvp_ipni_id = "470130-1",
                 wcvp_accepted_id = 2611879,
                 resolved_match_type = "Exact (without author)"
                 ))
})

