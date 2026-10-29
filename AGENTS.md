# ISIR project instructions

- The user requested this repository as the destination for current and future ISIR project code so it can be copied from a work laptop. Keep code and setup instructions here as the project progresses.
- Keep Power Query files in `powerquery/`, named after their exact query names. Update the README install order when dependencies change.
- Preserve the existing `stg_ISIR_Raw` connection. Do not embed tenant URLs, credentials, employee records, actual incident snapshots, or data-bearing PBIX files.
- One input row represents one incident. Do not silently filter or deduplicate reporting-ready source rows. Flag data-quality exceptions separately.
- Use curated fields rather than AI suggestions. Preserve missing values and do not guess source semantics or historical department assignments.
- Run appropriate syntax checks for modified M code. The native self-test must run in Power BI; syntax validation alone is not runtime validation.
- Record changes and required Desktop replacement steps in CHANGELOG.md. Avoid force pushes and preserve user edits.
- Never open links shown in the user's screenshots. This is an explicit user preference.
- Keep the repository private unless the user explicitly requests a visibility change.

- The user replaced User-at-Fault prefix attribution with ReporterEmail -> GLOBAL_EMPLOYEE.EMAILADDRESS -> first token of ACTIVEDIRECTORYDISPLAYNAME. Treat this as Reporter Subsidiary unless the owner confirms broader incident attribution.
- Preserve nonblank incident-level organization snapshots across runs. Normal Power BI refreshes cannot persist prior output; proposals require external storage. Keep new matches separate until an approved writer saves them.
- Do not present a current-directory backfill as incident-time history. Record extraction date, capture time, match identity and capture basis for saved assignments.

- Latest checkpoint: user is still in Transform Data. Do not assume Close & Apply, relationships, marked date table, DAX or visuals have been completed.
- User accepts reporter-based attribution for the POC despite occasional proxy submissions. Defer optional User-at-Fault identity cross-checks; do not silently replace reporter assignments using names.
- User explicitly supplied employee export date 2026-10-26. Preserve date precision with ReporterOrgDirectoryExtractDate rather than inventing an exact UTC extraction time. The SharePoint snapshot-column proposal is superseded; the user wants the original list unchanged.

- Do not add snapshot columns or write assignments to the original SharePoint list for this POC. Use a separate values-only Excel snapshot workbook keyed by SourceItemID; clearly distinguish manual capture from automated query refresh.
- Only EMPLOYEE_STATUS = Active rows qualify for new directory assignments. Prefer exact email, then same-local-part tel.com/us.tel.com fallback only with no exact active match. Multiple active matches remain blocked; do not guess a latest row.
- Final reporter organization fields must come only from saved incident snapshots. Preserve nonblank values and prior rows when adding assignments. Keep snapshot-file connections configured once established.
