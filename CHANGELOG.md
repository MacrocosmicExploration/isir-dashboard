# Change history

## 2026-10-29 — Reporter organization matching and snapshot design

- Added read-only email matching against the exported GLOBAL_EMPLOYEE CSV.
- Normalized email whitespace/case, blocked ambiguous duplicate matches, preserved input row counts, and proposed first-token directory prefixes for review.
- Preserved existing nonblank ReporterSubsidiarySnapshot values; flagged subsequent directory or reporter-email changes without proposing overwrites.
- Added aggregate diagnostics and 12 synthetic native M checks for matching, missing values, row preservation, and historical-value preservation.
- Documented incident-level SharePoint persistence, capture provenance, and conditional fill-only writes. No writer has been deployed; query proposals alone do not freeze history.
- Distinguished reporter organization from affected-person organization and current-directory backfill from incident-time history.
- Desktop action: import the employee CSV as stg_GLOBAL_EMPLOYEE_Raw, then add the four new queries in README order. Keep all new queries unloaded. Existing queries and model tables are unchanged.
- Validation: M syntax passed; new native tests and CSV matching remain pending in Desktop.

## 2026-10-29 — Reporting model and load configuration

- Recorded user-reported success of the original 22 native self-tests and source reconciliation.
- Added `FactIncident`, `DimDate`, and `DimCategory` as the only loaded ISIR tables.
- Added an aggregate subsidiary audit that suppresses non-code first tokens from its output.
- Added six starter DAX measures and exact model relationship, sorting, and QA steps.
- Kept every incident, original null quantities, and the missing-date row. Workflow state does not silently exclude records.
- Kept unverified subsidiary candidates out of the reporting model. Fiscal and YoY measures await business definitions and coverage.
- Desktop action: keep all six original queries unchanged; add the four new queries, set load flags, add the relationships and measures, and run the QA steps in `docs/model-setup.txt`.
- Validation: M syntax passed for all ten queries. New query execution and DAX validation remain pending in Desktop.

## 2026-10-29 — Initial query package

- Added the six previously delivered Power Query scripts as individual `.pq` files.
- Added copy-and-paste installation instructions and validation notes.
- Preserved the existing transformation logic without functional changes.
- Included 22 native Power Query assertions over 17 synthetic records.
- Status: syntax checked; Desktop execution and source validation pending.
