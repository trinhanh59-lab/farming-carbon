# Scientific figures

The history/support ZIPs named below are unchanged inner members of [History_and_Support_2026-10-21.zip](../archive/History_and_Support_2026-10-21.zip). Restore the outer container, then the needed inner ZIP into the same separate copy before using an archived helper.

`assets/` contains the five manuscript/sampling PNGs, plus the unchanged annual root diagnostic PNG documented in [ROOT_MODEL_CHECKS.md](../docs/ROOT_MODEL_CHECKS.md). Current Figures 2–4 use the approved framed 2×2 layout at 9 × 8.45 inches, with Arial text, the original green/orange/gold palettes, black-outlined group shapes and distinct line patterns. Greyscale companions are in `grayscale/`. Panels a/b/d show fitted response-scale means ±1 SE; panel c shows observed cumulative-stock means ±1 sample SE. Current and historical image hashes are recorded in `FIGURE_ASSET_PROVENANCE.json`. Figure 1, the static sampling illustration and the annual root diagnostic image are unchanged.

## Commands

Run from the repository root, using a new output directory:

```sh
Rscript --vanilla figures/render_profile_figures.R [NEW_OUTPUT_DIR]
python figures/map/render_figure1.py [NEW_OUTPUT_DIR]
```

Brackets indicate an optional argument, not literal shell syntax. Defaults are separate subdirectories of `figures/regenerated/`. Both commands leave supplied assets unchanged. Figure 1 reads the verified original Census ZIPs inside `map/basemap/Census_Basemaps_2023_500k.zip`; the two original loose ZIPs are also supported when that wrapper is absent. See [source credits](map/THIRD_PARTY_MAP_SOURCES.md).

`render_profile_figures.R` calls the portable saved-value renderers in `profile_renderers/`. They read frozen approved tables in `profile_data/{annual,orchard,hedgerow}_means1se.csv` and matching `_brackets.csv` files. The `_raw.csv` readbacks retain observations for audit; individual observations are not drawn. The figures contain 128 means: 96 fitted root/C-concentration/Δ¹⁴C means and 32 observed stock means. Bounds are estimate minus/plus one saved response-scale SE, without clipping. The density equivalent of the 0.00017-g addition is subtracted from fitted root means for display. Rendering fits no model and runs no statistical test.

The [support archive](../archive/History_and_Support_2026-10-21.zip) preserves alternate panel renderers, copy-only asset exporters and optional annual diagnostic plotters at their original paths. Restore it into a separate repository copy before using these helpers. In particular, `figures/render_saved_annual_diagnostics.R` redraws the former Figure S2 from saved residuals without fitting or simulation. Its fixed PNG and detailed numerical summaries remain visible in [ROOT_MODEL_CHECKS.md](../docs/ROOT_MODEL_CHECKS.md); the underlying residuals are preserved in [Diagnostic_Results_2026-10-21.zip](../archive/Diagnostic_Results_2026-10-21.zip).

The older panel crops and superseded hedgerow helper remain in the separate [analysis history](../archive/History_and_Support_2026-10-21.zip). They are not current rendering inputs.

## Figure-specific limits

- Figure 1 uses the recovered current map specifications, approximate vicinity points and Census boundaries. A fresh execution of the recovered map code matches the publication's decoded pixels. See `map/THIRD_PARTY_MAP_SOURCES.md` for required source credit and use limits.
- Figures 2–4 show clean mean profiles ±1 SE, not individual-core root curves or 95% confidence intervals. Annual and orchard groups share depth-row centers; their brackets are annotation-only row markers for the two-group comparison. Hedgerow groups retain small vertical offsets, and brackets identify the compared pair. Both corrected hedgerow root masses are included. Historical root-mass and stock-profile GLMM panels must not replace these current displays.
- S1 is the exact current static scientific illustration and approved caption. Its editable drawing source was not found. No diagram was redrawn by inference.
- The former S2 fixed PNG remains byte-for-byte unchanged as the repository diagnostic image. A new graphics device or font can change regenerated pixels without changing the saved residual values.

The 19 October non-root revision and preceding 17 October analysis verification remain dated records. The 30 October synchronization publishes the approved Figures 2–4 with fitted perennial root means, both hedgerow root-mass corrections and the selected overall stock tests. Code/data release and licensing choices remain separate from the manuscript license. Census source conditions remain attached to its boundary files.

The earlier 20 October orchard-stock restoration and its fitted panel are historical. Current stock panels use 32 observed means ±1 SE. Each panel has one overall ns bracket at the selected endpoint: 0–100 cm for annual fields and 0–75 cm for orchards and hedgerows. The hedgerow stock bracket compares all three margins overall, not a specific pair. Other panels show only significant unadjusted within-depth pairwise comparisons: * p < 0.05, ** p < 0.01 and *** p < 0.001. There are five annual, four orchard and 16 hedgerow significant pairs. Daggers, letters and former joint-test stars are not used.

## Optional cached-object plots

Some diagnostic helpers in `Supporting_Files_2026-10-20.zip` use objects now stored in [Run_Support_History_2026-10-21.zip](../archive/History_and_Support_2026-10-21.zip). Restore both support archives into the same separate copy before using those saved objects. Current Figures 1–4 and the fixed S1/S2 assets do not read the run-support ZIP.

## Restore the saved-residual renderer

In a separate repository copy, run these commands from its root. They restore the original residuals and archived helper before drawing the diagnostic image:

```sh
python -m zipfile -e archive/Diagnostic_Results_2026-10-21.zip .
python -m zipfile -e archive/History_and_Support_2026-10-21.zip .
python -m zipfile -e archive/Supporting_Files_2026-10-20.zip .
Rscript --vanilla figures/render_saved_annual_diagnostics.R outputs_rerun/saved_residual_figure
```

Use a new output directory. This renderer uses the restored saved residuals; it fits no models and generates no new simulations. Current Figures 1–4 do not require these restoration steps.
