# History and support records

[History_and_Support_2026-10-21.zip](History_and_Support_2026-10-21.zip) contains the four original history ZIP byte streams, four original module READMEs and the original method/environment ZIP at their original repository-relative paths. Its `FILE_MANIFEST.csv` lists these nine payloads with byte sizes, SHA-256 and MD5.

| Inner ZIP member | Original files | Contents |
| --- | ---: | --- |
| `archive/Analysis_History_2026-10-20.zip` | 86 | Superseded stock-profile models, separate orchard covariance analysis and earlier scientific history. |
| `archive/Supporting_Files_2026-10-20.zip` | 33 | Duplicate snapshots/source cells, optional plotters and historical scope comparisons. |
| `archive/Run_Support_History_2026-10-21.zip` | 51 | Dated checkpoints, model caches, run records and detailed diagnostics. |
| `archive/Additional_Support_2026-10-21.zip` | 17 | Additional readbacks, preparation checks, historical verification/figure records and July bulk-density reference outputs. |
| `reproducibility/Method_and_Environment_Records.zip` | 5 | Original method scope, July input settings and software/environment records; readable context remains in REPRODUCIBILITY.md. |

Each inner ZIP retains its original `FILE_MANIFEST.csv`, paths and hashes. The four history ZIPs retain their 187 original records and four inner manifests; the method/environment ZIP retains its five original records and own manifest. The four module READMEs retain their original `analysis/current_perennial_root/`, `analysis/nonroot_current/`, `analysis/hedgerow_0_75/` and `analysis/stock_endpoints_2026-10-20/` paths; current instructions are merged into [REPRODUCIBILITY.md](../REPRODUCIBILITY.md).

To inspect history or use an optional helper, extract the outer ZIP into a separate repository copy, preserving folders. Then extract the needed inner ZIP there. Some diagnostic helpers use records from both Supporting_Files and Run_Support_History, so restore both for those plots. Current paper analyses/figures do not need the container. `check_saved_results.R --archive` reads the nested history directly and extracts only required evidence into a temporary directory; an explicit old ZIP path also works after restoration. The current nine-payload and preceding eight-payload containers are both supported.

The 23 current source workbooks are preserved in the separate [data/Original_Source_Workbooks.zip](../data/Original_Source_Workbooks.zip). Current CSV inputs, published results and fixed figures remain active. The [root checks](../docs/ROOT_MODEL_CHECKS.md) retain their public resource path. Original project code retains [MIT](../LICENSE), project data/results retain [CC BY 4.0](../DATA_LICENSE), and [third-party terms](../LICENSING.md) remain unchanged.
