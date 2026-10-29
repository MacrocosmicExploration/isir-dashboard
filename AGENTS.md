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
