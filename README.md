
<!-- README.md is generated from README.Rmd. Please edit that file -->

# taxonomy.tools

<!-- badges: start -->

[![R-CMD-check](https://github.com/Pakillo/taxonomy.tools/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Pakillo/taxonomy.tools/actions/workflows/R-CMD-check.yaml)
[![Project Status: Active - The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
<!-- badges: end -->

taxonomy.tools is an R package to help working with taxonomic data.

By now, it builds upon [rWCVP
package](https://matildabrown.github.io/rWCVP) to match plant taxonomic
names against the [World Checklist of Vascular Plants
(WCVP)](https://powo.science.kew.org/about-wcvp).

## Installation

You can install the development version of taxonomy.tools from
[R-universe](https://pakillo.r-universe.dev/taxonomy.tools):

``` r
install.packages("taxonomy.tools", repos = c("https://pakillo.r-universe.dev", "https://cloud.r-project.org"))
```

or from [GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("Pakillo/taxonomy.tools")
```

## Usage

``` r
library(taxonomy.tools)
```

### Matching plant taxonomic names against WCVP

[wcvp_match_names_parallel](https://pakillo.github.io/taxonomy.tools/reference/wcvp_match_names_parallel.html)
runs
[rWCVP::wcvp_match_names](https://matildabrown.github.io/rWCVP/reference/wcvp_match_names.html)
in parallel to speed up matching with large taxonomic lists.

``` r

df <- data.frame(taxon = c("Laurus nobilis", "Laurus nobilis", "Laurus nobili"),
                 author = c(NA, "L.", NA))

out <- wcvp_match_names_parallel(df, 
                                 name_col = "taxon", 
                                 author_col = "author", 
                                 cores = 3)
```

``` r
dplyr::glimpse(out)
#> Rows: 3
#> Columns: 16
#> $ taxon                     <chr> "Laurus nobilis", "Laurus nobilis", "Laurus …
#> $ author                    <chr> NA, "L.", NA
#> $ match_type                <chr> "Exact (without author)", "Exact (with autho…
#> $ multiple_matches          <lgl> FALSE, FALSE, FALSE
#> $ match_similarity          <dbl> 1.000, 1.000, 0.929
#> $ match_edit_distance       <dbl> 0, 0, 1
#> $ wcvp_id                   <dbl> 2349094, 2349094, 2349094
#> $ wcvp_name                 <chr> "Laurus nobilis", "Laurus nobilis", "Laurus …
#> $ wcvp_authors              <chr> "L.", "L.", "L."
#> $ wcvp_rank                 <chr> "Species", "Species", "Species"
#> $ wcvp_status               <chr> "Accepted", "Accepted", "Accepted"
#> $ wcvp_homotypic            <lgl> NA, NA, NA
#> $ wcvp_ipni_id              <chr> "465049-1", "465049-1", "465049-1"
#> $ wcvp_accepted_id          <dbl> 2349094, 2349094, 2349094
#> $ wcvp_author_edit_distance <dbl> NA, 0, NA
#> $ wcvp_author_lcs           <int> -1, 2, -1
```

## Citation

``` r
citation("taxonomy.tools")
#> To cite package 'taxonomy.tools' in publications use:
#> 
#>   Rodriguez-Sanchez F (2024). _taxonomy.tools: Tools to Work with
#>   Taxonomic Data_. <https://github.com/Pakillo/taxonomy.tools>.
#> 
#> A BibTeX entry for LaTeX users is
#> 
#>   @Manual{,
#>     title = {taxonomy.tools: Tools to Work with Taxonomic Data},
#>     author = {Francisco Rodriguez-Sanchez},
#>     year = {2024},
#>     url = {https://github.com/Pakillo/taxonomy.tools},
#>   }
```
