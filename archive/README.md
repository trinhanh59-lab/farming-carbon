# Analysis history and supporting files

`Analysis_History_2026-10-20.zip` preserves 86 historical scientific files, including superseded stock-profile models and the separate orchard covariance analysis. Its bytes are unchanged from the first cleanup.

`Supporting_Files_2026-10-20.zip` preserves 33 additional files: duplicate data snapshots and readbacks, recovered notebook cell extracts, optional plotting/export helpers, and two historical hedgerow scope comparisons. Each ZIP retains original repository-relative paths and includes `FILE_MANIFEST.csv` with every member's size, SHA-256 and MD5.

`Run_Support_History_2026-10-21.zip` preserves 51 run-support files: the dated hedgerow checkpoint, extra bulk-density outputs, unused model/simulation caches, run records and detailed diagnostics. Published summary tables, source residuals and the two supplement bulk-density group summaries remain active. All 13 scientific script paths remain active.

All 23 source workbooks, current inputs, published numerical results and figure assets remain in the main folders. Current code uses one canonical copy of each shared annual input. The retained annual and perennial CSVs are the current root inputs. Notebook/Sheets readbacks and their source-verification records are preserved in the support archives at their original paths.

To use an archived helper, extract the relevant ZIP into a separate repository copy, preserving its folders. The support archive includes the saved-residual diagnostic renderer and the optional annual check plotters. Restore these before redrawing those supporting graphics. Some optional diagnostic plotters also use cached objects in the run-support archive; restore both support ZIPs into the same separate copy when using those saved objects. Current paper analyses and figure rendering do not read the run-support archive. The existing root-check tables and diagnostic image remain available through [ROOT_MODEL_CHECKS.md](../docs/ROOT_MODEL_CHECKS.md).

Original project code retains the [MIT License](../LICENSE). Project data and numerical results retain [CC BY 4.0](../DATA_LICENSE). Third-party terms and software/source provenance are unchanged; see [LICENSING.md](../LICENSING.md).

`Additional_Support_2026-10-21.zip` preserves 17 files: duplicate current-scope/readback tables, older preparation checks, the earlier Figure 2 review record, historical verification documentation and three July bulk-density outputs. The latter contain the retained annual/orchard results and the older 100 cm hedgerow scope. Current bulk-density tables remain in `analysis/hedgerow_0_75/current_bulk_density/`; current full 111-row data, 96-row paper input, inclusion flags and all 23 original source workbooks remain active. The legacy bulk-density script now creates its missing output folder; the saved-result checker points to the current rerun guide. Neither change alters calculations.

The verification narrative and JSON audit in this ZIP are dated records. The repository-wide `reproducibility/FILE_CHECKSUMS.csv` is the current integrity list; `analysis/FILE_MANIFEST.json` in this ZIP describes its earlier snapshot. Each archive manifest preserves the original member paths and hashes. The three earlier ZIPs are unchanged.
