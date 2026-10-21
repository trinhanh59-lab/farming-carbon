# Analysis history and supporting files

`Analysis_History_2026-10-20.zip` preserves 86 historical scientific files, including superseded stock-profile models and the separate orchard covariance analysis. Its bytes are unchanged from the first cleanup.

`Supporting_Files_2026-10-20.zip` preserves 33 additional files: duplicate data snapshots and readbacks, recovered notebook cell extracts, optional plotting/export helpers, and two historical hedgerow scope comparisons. Each ZIP retains original repository-relative paths and includes `FILE_MANIFEST.csv` with every member's size, SHA-256 and MD5.

`Run_Support_History_2026-10-21.zip` preserves 51 run-support files: the dated hedgerow checkpoint, extra bulk-density outputs, unused model/simulation caches, run records and detailed diagnostics. Published summary tables, source residuals and the two supplement bulk-density group summaries remain active. All 13 current scripts are unchanged.

All 23 source workbooks, current inputs, published numerical results and figure assets remain in the main folders. Current code uses one canonical copy of each shared annual input. Perennial notebook readbacks are retained in the portable module; their duplicate copies and original source cells are in the support archive.

To use an archived helper, extract the relevant ZIP into a separate repository copy, preserving its folders. The support archive includes the saved-residual diagnostic renderer and the optional annual check plotters. Restore these before redrawing those supporting graphics. Some optional diagnostic plotters also use cached objects in the run-support archive; restore both support ZIPs into the same separate copy when using those saved objects. Current paper analyses and figure rendering do not read the run-support archive. The existing root-check tables and diagnostic image remain available through [ROOT_MODEL_CHECKS.md](../docs/ROOT_MODEL_CHECKS.md).

Original project code retains the [MIT License](../LICENSE). Project data and numerical results retain [CC BY 4.0](../DATA_LICENSE). Third-party terms and software/source provenance are unchanged; see [LICENSING.md](../LICENSING.md).
