# Change history

## 2026-10-29 — Active-only matching, TEL aliases, and separate POC snapshot

- Adopted the user's source rule: only EMPLOYEE_STATUS = Active rows are eligible. Multiple active matches remain blocked.
- Added exact-email-first matching with tel.com/us.tel.com fallback only when no active exact match exists. Preserved match method and matched address for traceability.
- Replaced the 12-test organization suite with 30 native regression checks for active/inactive handling, aliases, ambiguity, saved assignment preservation, row counts and snapshot keys.
- Superseded the SharePoint-column proposal. The source list is unchanged. Added a separate values-only workbook workflow with blank-only additions and SourceItemID keys; persistence is manual for the POC.
- Added snapshot attach, empty/file staging, extract-date parameter, additions query and DimReporterSubsidiary. Updated FactIncident to consume saved assignments only.
- Updated validation and review for active matching. All 20 M files pass syntax checks; new native tests and workbook integration remain pending in Desktop.
- Desktop replacement order and final four-table load settings are in README and docs/reporter-org-setup.txt. Preserve existing configured workbook paths on later updates.

## 2026-10-29 — Unresolved match review and source-column clarification

- Recorded the user's Desktop checkpoint: still in Transform Data; relationships, date-table setup, DAX and visuals remain undone.
- Recorded all 12 native organization tests passing, 163 proposed assignments, 11 incidents with duplicate employee matches, four unmatched incidents, and zero persisted assignments.
- Added ISIR_ReporterOrgReview, retaining one row per unresolved incident with nested employee matches and duplicate classifications. Matching and assignment rules are unchanged.
- Clarified that snapshot columns belong to the curated SharePoint list, not inside Power Query or IsirSnapshot. Columns are optional and start blank.
- Replaced the proposed directory timestamp column with ReporterOrgDirectoryExtractDate (date only), using the user's explicit export date of 2026-10-26 without inventing an extraction time.
- Kept reporter attribution for the POC. Deferred any User-at-Fault identity cross-check; a name/email string inequality is not evidence of different identities.
- Desktop action: add only ISIR_ReporterOrgReview, with Enable load OFF. Existing matching queries do not need replacement. Review-query syntax passed; native execution pending.

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
