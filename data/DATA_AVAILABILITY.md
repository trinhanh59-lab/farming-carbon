# Measurement records and analysis inputs

Optional historical analysis files are preserved in the [history ZIP](../archive/Analysis_History_2026-10-20.zip). Historical paths in the workbook provenance and dated records refer to ZIP members where listed in `FILE_MANIFEST.csv`. All source workbooks, processing tables, current inputs and the publication workbook remain in the main folders. Duplicate preparation snapshots and optional helper files are in the separate [support ZIP](../archive/Supporting_Files_2026-10-20.zip); each archived duplicate has an active canonical copy.

The supplied data retain all 111 sample records. Current analysis coverage includes 96 records: 36 annual, 24 orchard and 36 hedgerow observations. Six deepest orchard and nine deepest hedgerow records remain visible in the full table and are excluded from the current primary analyses. The historical 105-row input remains supplied for the earlier five-interval hedgerow analysis. Available original records are included alongside the working spreadsheets; these are different stages of the data history.

Use `processed/sample_level_analysis_96_current.csv` for the paper. In `processed/sample_level_full_111_current.csv`, `analysis_included` describes the historical 105-row scope. Current inclusion flags are in `processed/sample_level_scope_111_current.csv` and the publication workbook.

## Included records

| Location | Contents and role |
| --- | --- |
| `source_measurements/metadata/`, `soil moisture/`, `14C/`, `core cutting/`, `roots/` | Twelve direct input workbooks for sample identity, measured concentrations and radiocarbon, moisture, recovered core length and root mass. Some are corrected working compilations, rather than untouched instrument exports. |
| `source_measurements/primary_reports/CAMS/` | Six original CAMS reports covering 110 unique research samples, plus laboratory standards. Sample identities and retained radiocarbon values agree with the compiled inputs at their reported precision. Sample 111 has no radiocarbon result and is in the excluded orchard 75–100 cm interval. All 96 current analysis rows and all 105 historical analysis rows have radiocarbon values. |
| `source_measurements/primary_reports/EA/Fresno_Davis_foilball.xlsx` | Original aliquot-weight list for 110 samples, with C/N results for 42 samples. Those 42 results agree with the compiled inputs. This file does not contain the other 68 samples' C/N results. |
| `source_measurements/original_records/` | Two field measurement workbooks and preserved versions preceding the sample 108 moisture-cell and sample 13 envelope-tare corrections. These records document the earlier values; they are not current analysis inputs. |
| `processed/` | Full 111-sample and current 96-row analysis CSV tables, preserved historical 105-row inputs, correction ledger and deterministic preparation checks. Source root-mass fields are retained separately from working masses. |
| `Supplementary_Data.xlsx` | Publication workbook, with statistical tables, figure values, all 111 sample records, variable definitions and provenance. |
| `../analysis/` | Current analysis-specific inputs, saved results and historical selected-reference data. The root README identifies the current code and labels superseded analyses. |

`source_measurements/SOURCE_FILES.csv` records the relative path, byte size and SHA-256 of each of the 23 supplied source workbooks. Source workbooks are copied byte for byte. Extra samples, standards and ordinary hidden scientific columns within those workbooks are retained to preserve their original context. Seven original workbooks retain historical Excel local-save location metadata; the analysis code reads supplied relative paths and does not use those locations. Unused site-coordinate workbooks and unrelated assays are excluded.

## Corrections and processing

`../scripts/prepare_analysis_data.R` reads the twelve working inputs, checks sample identity and join uniqueness, calculates dry soil mass and recovered layer volume, and rebuilds bulk density and carbon stocks. The volume calculation retains the 1.905 cm radius and recorded recovered core lengths. On 20 October 2026, the author confirmed using the equivalent 3.81 cm sampling diameter. The actual fitted cutting-tip dimension has not been independently verified. It excludes orchard 75–100 cm rows before calculating cumulative stocks.

The script preserves the root worksheet's original mass and applies the recorded sample 143 replacement and 18 annual working-mass changes. The annual corrections come from the supplied corrected annual input, rather than new transcription or inference. Recorded zero masses mean no roots were recovered. Added mass for Gamma models is applied only in the corresponding analysis code, not to these measured working masses.

The corrected working moisture file contains 104.40 in cell M118 for sample 108; the preserved earlier version contains 352.68. The June correction record describes 104.40 as a value informed by neighboring B/C core measurements, pending confirmation from the original same-core record. On 20 October 2026, the author approved retaining 104.40 g as a neighboring-core estimate. The original same-core mass remains unverified; the preparation check establishes use of the retained estimate, not confirmation of the original measurement. The sample 13 envelope-tare correction from 1.4368 to 1.4210 is retained in the current source; its recorded net root mass remains 0.002 g. The compiled orchard radiocarbon input retains sample 142 at −11.5‰ and sample 143 at 13.2‰, consistent with the CAMS reports at the retained precision. The earlier swapped compilation is not used.

The selected historical 111- and 105-row CSVs remain at their existing paths because they support the dated non-root analysis records. Their older annual working root masses are superseded by the current root inputs and the tables in `processed/`. Measured non-root values are unchanged. Current hedgerow model results use the common 0–75 cm subset; the earlier five-interval results remain historical. The preparation check makes these distinctions explicit rather than replacing historical files.

## Records not located

- Native elemental-analyzer result exports for the other 68 C/N samples. Their values are present in the three compiled measurement workbooks and the processed tables.
- Original handwritten root-mass correction notes. The package retains recorded corrections and author-confirmed transcriptions; the available root-picking template is blank and is not offered as measurement evidence.
- Laboratory preparation records establishing carbonate screening or acid treatment. No preparation method is inferred from a missing record.
- The original orchard simulation response arrays and interactive RNG/checkpoint state. The approved 17 October reproduction includes its own 999 response datasets and fit classifications.
- The editable drawing source for Figure S1. Its exact publication image and caption are supplied.

The data-preparation check establishes agreement between the available measurement workbooks and the selected analysis inputs. It does not recover missing records or establish that the scientific models are adequate.
