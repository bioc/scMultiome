
#' create data set list
#'
#' Automatically creates the data set list of the package.
#'
#' This is an internal helper function for developers and will not be called directly.
#' It creates the file inst/scripts/datasetList.Rmd, which is incorporated
#' into the package help page to automatically list the current data sets.
#'
#' @param metadata a \code{data.frame} containing data set metadata
#'
#' @return Invisible TRUE.
#'
#' @keywords internal
#'
makeDataSetList <- function(metadata) {
    checkmate::assertDataFrame(metadata)

    names <- tools::file_path_sans_ext(basename(metadata[["RDataPath"]]))
    titles <- metadata[["Title"]]

    fileName <- file.path(system.file("scripts", package = "scMultiome"), "datasetList.Rmd")
    file.create(fileName)
    writeLines(con = fileName, text = c(
        header(),
        mapply(makeLine, name = names, title = titles),
        footer())
    )

    return(invisible(TRUE))
}


makeLine <- function(name, title) {
    checkmate::assertString(name)
    checkmate::assertString(title)

    sprintf("+ **%s**: %s", name, title)
}


header <- function() {
    c(
        "---",
        "title: \"Data Set List\"",
        "output:",
        "  BiocStyle::html_document:",
        "    titlecaps: false",
        "    toc_float: true",
        "---",
        "",
        "```{r setup, include = FALSE}",
        "knitr::opts_chunk$set(echo = TRUE, eval = FALSE)",
        "```",
        ""
    )
}


footer <- function() {
    c(
        ""
    )
}
