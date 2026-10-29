# Change history

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
