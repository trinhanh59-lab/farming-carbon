# Orchard cumulative-stock correlation sensitivity

This module contains the final recorded OU/core-intercept Gamma sensitivity method. This secondary archive retains the completed 17 October 2026 execution in `reproduction_2026-10-17/`; `saved_results/` preserves the original historical run. It uses 24 existing cumulative C stocks from six cores at 10, 20, 50 and 75 cm. Stock values are supplied directly; no stock calculation is repeated.

## Historical evidence

`saved_results/frozen_all999_fit_audit.csv` is the original 999-row, 46-column table, extracted byte-for-byte from the saved notebook output. Its SHA-256 is `04f384c53f877e4d170a5ba2c950634561af25236ad62ffbd51395ca984ca0ce`.

The saved result is LR = 8.7784597675772034, with 123 definite exceedances, 871 definite nonexceedances, four unresolved fits and one ambiguous comparison. All 999 indices remain in the denominator. The plus-one numerical p-value bounds are 0.124–0.129. The bounds are separate from the conservative 95% Monte Carlo envelope, 0.1033813880–0.1504544456. Infinite-Gamma-shape fits account for 671 full and 683 null selections.

In the per-index CSV, `unresolved` is the union `failed OR numerical_ambiguity`: five rows in total. The previous S4's four unresolved **fits** correspond to `failed` only; the one ambiguous comparison is separate. The bootstrap upper bound counts this union once, so the ambiguous row must not be added to `unresolved` again.

The 20,000-dataset full-model diagnostic recorded a smoothness statistic of 0.784663473 and 524 simulations at or below the observation. Its plus-one lower-tail probability is 525/20001. The diagnostic CSV retains the precision printed in the saved output, rather than inventing additional digits. The PNG is the original saved plot.

The correlation check is a conditional sensitivity analysis. It changes covariance handling and test calibration together and does not validate a uniquely correct covariance model. The previous endpoint-only Welch comparison answered a separate question and is now archived. The current paper uses the restored July Gamma(log)/core profile model over 0–75 cm.

## Future reproduction

An isolated top-to-bottom execution completed on 17 October 2026. The observed LR differed from the archived value by 7.31e-11 and the 20,000-dataset diagnostic reproduced 524 lower-tail counts. The new bootstrap gave 125 definite exceedances, 870 nonexceedances, three failed fits and one ambiguous case, with p-value bounds 0.126–0.130. The historical run had 123, 871, four and one, with bounds 0.124–0.129. The new run is retained as secondary archived evidence and is excluded from the current paper and supplement. Its conservative 95% Monte Carlo envelope is 0.105236125639516–0.151520977138336; infinite-shape selections number 671 full and 682 null. The verification records retain both result sets, the changed classifications and numerical-search review.

The original notebook records a full-model diagnostic seed of 20261016 and a null-generation seed of 20261018. It pregenerated 4,999 responses and fitted the first 999. The original simulated response vectors, fit-object cache, and interactive checkpoint/RNG state were not stored in the notebook and have not been recovered. In particular, no serialized generator-fit object, `.Random.seed` vector or `RNGkind()` record is available; the numeric seed arguments alone do not establish exact recovery of the original simulated vectors. A future run therefore produces a **new reproduction**, not recovered original random datasets.

The scripts retain the final active likelihood/profile, optimization, cap, retry, boundary-audit and tail-classification rules. Superseded preliminary boundary implementations and interrupted checkpoint drivers are excluded. The final rules are used from the start of a fresh batch. This cleanup can change numerical fit paths relative to the historical interactive run; the original per-index classifications remain in the frozen CSV. A comparison file reports differences while preserving the historical results.

Use the recorded R 4.6.1 environment and package versions in `environment/recorded_versions.tsv`. The entry script checks those versions and does not install packages automatically. After integration at `analysis/orchard_cumulative_correlation/`, from the repository root:

```sh
Rscript --vanilla analysis/orchard_cumulative_correlation/run_new_reproduction.R NEW_OUTPUT_DIR
```

`NEW_OUTPUT_DIR` must name a new or empty directory. From the module directory, the equivalent entry is `Rscript --vanilla run_new_reproduction.R [NEW_OUTPUT_DIR]`.

An optional first argument selects a new output directory. Otherwise output goes to `outputs_rerun/`. The directory must be new or empty; the script protects `saved_results/`, `inputs/`, `R/` and `environment/`. Output paths are resolved through their nearest existing ancestor, including symlink aliases and `..` components, before the protection checks. Linux/macOS use up to two forked workers; Windows uses one. The recorded datasets are generated before parallel refits, with worker RNG seeding disabled as in the source.

For a parent runner, source `run_new_reproduction.R` and call `run_orchard_correlation(module_dir, output_dir)`. This is computationally expensive. It records the starting RNG kind/state and writes diagnostic plots, the new per-index table, an RDS cache, session information and a comparison with the frozen counts. A future execution can be compared with the archived 17 October run. This module is excluded from the current paper and supplement.

## New reproduction evidence

`reproduction_2026-10-17/` preserves the completed new run separately from `saved_results/`. It includes the 24 × 999 simulated null-response matrix in numeric CSV/RDS form, its exact observation ordering, all 999 classifications, diagnostics and change tables. These are simulated analysis records, not field measurements. The numeric RDS preserves the newly generated response values exactly; the CSV uses 17 significant digits. This evidence does not recover the missing original response arrays.

## Source map

`SOURCE_MAP.tsv` identifies the recorded source cells and their hashes using relative source labels. The original saved notebook is preserved separately in private provenance and is not needed at runtime. The input stock CSV preserves the source decimal strings and sample identifiers. No private credentials or machine-specific source paths are required.
