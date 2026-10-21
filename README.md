# Farming Carbon: data and code

Data and analysis code for *Soil Carbon Stocks and Radiocarbon Profiles in Three Agricultural Systems of California’s Central Valley*.

The paper compares annual fields through 100 cm and orchards and hedgerows through 75 cm. All 111 sample records are preserved; the current paper uses 96 observations.

## Start here

- [Publication workbook](data/Supplementary_Data.xlsx): sample data, statistical tables and values used in the figures.
- [Current analysis input](data/processed/sample_level_analysis_96_current.csv): the 96 paper observations. [Sample inclusion](data/processed/sample_level_scope_111_current.csv) identifies current and historical inclusion across all 111 records.
- [File map](COVERAGE_MAP.md): inputs, selected code and saved results for each figure and table.
- [Rerun instructions](REPRODUCIBILITY.md): software versions and current analysis commands. [Figure instructions](figures/README.md) cover rendering.

## Check the supplied files

Run from the repository root:

```sh
Rscript --vanilla scripts/check_repository.R
Rscript --vanilla scripts/check_saved_results.R
```

These commands check files and saved calculations without fitting models. Run analyses in a separate writable copy, using the output directories described in the rerun instructions.

## Source records and history

[Original_Source_Workbooks.zip](data/Original_Source_Workbooks.zip) contains all 23 supplied source workbooks at their original paths. The [data documentation](data/DATA_AVAILABILITY.md) describes these records, corrections and unavailable laboratory exports. It also explains the author-confirmed diameter and estimated mass for sample 108. Recorded method/environment details are in the [rerun guide](REPRODUCIBILITY.md#method-records-and-map-sources); their five original files remain in one ZIP. Census sources are bundled separately with the map.

[Earlier analyses and supporting files](archive/README.md) are preserved in one container. It holds the four original history ZIPs and module guides; original source data, selected analyses and published results remain in the main folders.

## License and citation

Original code uses the [MIT License](LICENSE); project data and numerical results use [CC BY 4.0](DATA_LICENSE). See [licensing scope and third-party terms](LICENSING.md) and the [manuscript citation](CITATION.md).
