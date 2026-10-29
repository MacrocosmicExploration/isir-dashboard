# ISIR dashboard

Power Query transformations and validation for an incident-reporting Power BI proof of concept. This repository is the working source for future ISIR queries, DAX measures, and setup instructions.

## Current step: load the reporting model

The original 22 self-tests passed in Power BI Desktop, as reported by the user.
The source and parsed tables reconcile, and source IDs passed the missing/duplicate checks.

**Continue with [the exact model setup steps](docs/model-setup.txt).** Add these queries in order:

| Order | Query | Enable load | Code |
| --- | --- | --- | --- |
| 1 | `FactIncident` | **ON** | [FactIncident.pq](powerquery/FactIncident.pq) |
| 2 | `DimDate` | **ON** | [DimDate.pq](powerquery/DimDate.pq) |
| 3 | `DimCategory` | **ON** | [DimCategory.pq](powerquery/DimCategory.pq) |
| 4 | `ISIR_SubsidiaryAudit` | OFF | [ISIR_SubsidiaryAudit.pq](powerquery/ISIR_SubsidiaryAudit.pq) |

Only those three model tables have Enable load checked. Keep the existing staging,
validation, profile, exception, inventory and self-test queries unloaded. Leave
`fnISIRTransform` as a function. Keep Include in report refresh enabled on the
three model tables. Do not delete the staging queries.

Create the six measures in [dax/](dax/) one at a time with **Modeling > New measure**,
starting with [Total Incidents](dax/Total_Incidents.dax). DAX does not go in Power Query.
The setup file includes relationships, sorting, expected QA totals, and the next
source-owner decisions. The four new M queries are syntax checked; their Desktop
execution and the new DAX measures still need validation in the user's model.

## Original starter queries (already installed)

1. Open a query file from the table below in GitHub. Click **Copy raw file** in the file toolbar, or open **Raw** and copy the entire file.
2. In Power BI Desktop, select **Transform data > Home > New Source > Blank Query**.
3. Give the query the exact name shown in the table.
4. Open **Advanced Editor**, replace everything with the copied code, and select **Done**.
5. Keep **Enable load** off for the staging and diagnostic queries in this package.

Prerequisite: your existing SharePoint connection query must be named `stg_ISIR_Raw`. Keep that query unchanged. No site address or credentials are embedded in these scripts.

| Install order | Exact query name | Open code |
| --- | --- | --- |
| 1 | `fnISIRTransform` | [fnISIRTransform.pq](powerquery/fnISIRTransform.pq) |
| 2 | `ISIR_SelfTest` | [ISIR_SelfTest.pq](powerquery/ISIR_SelfTest.pq) |
| 3 | `stg_ISIR_Parsed` | [stg_ISIR_Parsed.pq](powerquery/stg_ISIR_Parsed.pq) |
| 4 | `ISIR_Validation` | [ISIR_Validation.pq](powerquery/ISIR_Validation.pq) |
| 5 | `ISIR_FieldProfile` | [ISIR_FieldProfile.pq](powerquery/ISIR_FieldProfile.pq) |
| 6 | `ISIR_Exceptions` | [ISIR_Exceptions.pq](powerquery/ISIR_Exceptions.pq) |

The function's invocation screen is expected; do not invoke it manually. Create `ISIR_SelfTest` next. It should return **22 PASS results** using synthetic records before you continue with the source queries.

## Current checkpoint

- The six original and four new queries passed Microsoft's Power Query syntax parser.
- The user reported all 22 native starter assertions passed in Desktop; supplied diagnostics reconcile source and parsed rows with no missing or duplicate IDs.
- Source and parsed row counts must match. Missing and duplicate SharePoint IDs must be investigated.
- Review flags do not remove incidents. Inspect `ISIR_Exceptions` locally.
- Next: install and verify the three reporting tables, then resolve organization mapping and reporting definitions before the final pages.

See [complete setup instructions](docs/setup.txt), [validation status](docs/validation.txt), and [change history](CHANGELOG.md).

## Reporting rules

- One source row represents one incident. Keep all reporting-ready rows, including incidents abroad involving US subsidiaries.
- Use curated category and asset fields. AI suggestions do not overwrite them.
- Parse the recorded incident date without substituting the submission date or guessing ambiguous formats.
- First tokens are diagnostic candidates only. The observed source is incomplete and includes non-code tokens; do not use them directly as subsidiary labels. The model excludes these candidates pending reviewed mapping.
- Keep snapshot geography separate from workplace location. Department mapping remains pending.
- Parse recognized USB, badge, and document quantities in `LostOther`. Avoid double-counting USBs recorded in both fields.
- Preserve nulls and flag conflicting or invalid counts. `KnownLostAssetCount` is a recorded partial quantity until completeness rules are confirmed.
- Fiscal-year definitions, reporting cutoff, and owner reconciliation remain pending.

## Repository contents

This repository contains code, documentation, and synthetic tests. Keep incident exports, employee records, credentials, tenant-specific links, and data-bearing PBIX files outside the repository.

## Future updates

Use this repository for subsequent ISIR code and instructions. Query filenames match their Power BI query names. Update the change log and clearly identify any query that must be replaced in Desktop.
