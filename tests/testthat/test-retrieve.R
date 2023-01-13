
test_that("resource is returned", {
    testthat::expect_s4_class(retrieve("reprogramSeq", metadata = TRUE, experiments = "NEPCMatrix"),
                              "ExperimentHub")
    testthat::expect_s4_class(retrieve("reprogramSeq", metadata = FALSE, experiments = "NEPCMatrix"),
                              "MultiAssayExperiment")
})

test_that("missing resources signal errors", {
    expect_error(retrieve("nonexistentdataset",
                          metadata = FALSE,
                          experiments = c("experiment1", "experiment2")))
    expect_error(retrieve("nonexistentdataset",
                          metadata = TRUE,
                          experiments = c("experiment1", "experiment2")))
})
