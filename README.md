# ISIR dashboard

Power Query, DAX, and setup instructions for the ISIR Power BI proof of concept.

## Current step: active employee matching and a separate snapshot workbook

The user is still in Transform Data. Relationships, DAX measures, and visuals have
not yet been built. The SharePoint source list will remain unchanged.

**Follow [the complete current instructions](docs/reporter-org-setup.txt).** They
replace the earlier proposal to add snapshot columns to SharePoint.

**Already installed the queries but entered the employee CSV in the snapshot
path? Follow [this recovery guide](docs/snapshot-path-recovery.txt).** You do not
need to reinstall the queries. These are two separate files:

| Query | File it reads | First-time setup |
| --- | --- | --- |
| `stg_GLOBAL_EMPLOYEE_Raw` | Your existing GLOBAL_EMPLOYEE `.csv` export | Keep the existing employee CSV connection. |
| `stg_ISIR_OrgSnapshot_Raw` | A separate `ISIR_OrgSnapshot.xlsx` workbook containing saved incident assignments | Leave `SnapshotFilePath = ""` until you create this workbook from `ISIR_ReporterOrgSnapshotAdditions`. |

Opening a CSV in Excel does not make it an Excel workbook. Do not enter the
employee CSV path in the snapshot query or convert the employee export into the
snapshot. The snapshot needs incident assignments keyed by `SourceItemID`.

- Match only `EMPLOYEE_STATUS = Active` rows, normalizing case and whitespace.
- Prefer a unique exact email. With zero active exact matches, try only the same
  local part under `tel.com` / `us.tel.com`; label this fallback separately.
- Multiple active matches remain unresolved. No name or fuzzy matching is used.
- Save reviewed assignments as literal values in a separate Excel workbook keyed
  by `SourceItemID`. Power BI reads it; the POC capture step is manual.
- Keep populated saved assignments unchanged. New/unresolved incidents can be
  filled later. Current directory assignments are not proof of incident-time history.

## Install order for this update

First retain `EMAILADDRESS`, `ACTIVEDIRECTORYDISPLAYNAME`, and `EMPLOYEE_STATUS`
as Text in `stg_GLOBAL_EMPLOYEE_Raw`. Edit its existing column-selection step if needed.
Then copy each file below into Advanced Editor with the exact query name.

| Order | Action | Query | Enable load |
| --- | --- | --- | --- |
| 1 | New | [fnISIRAttachOrgSnapshot](powerquery/fnISIRAttachOrgSnapshot.pq) | Function |
| 2 | New, first install only | [stg_ISIR_OrgSnapshot_Raw](powerquery/stg_ISIR_OrgSnapshot_Raw.pq) | OFF |
| 3 | New | [pEmployeeDirectoryExtractDate](powerquery/pEmployeeDirectoryExtractDate.pq) | Parameter |
| 4 | Replace | [fnISIRReporterOrgMatch](powerquery/fnISIRReporterOrgMatch.pq) | Function |
| 5 | Replace | [ISIR_ReporterOrgSelfTest](powerquery/ISIR_ReporterOrgSelfTest.pq) | OFF |
| 6 | Replace | [ISIR_ReporterOrgPreview](powerquery/ISIR_ReporterOrgPreview.pq) | OFF |
| 7 | Replace | [ISIR_ReporterOrgValidation](powerquery/ISIR_ReporterOrgValidation.pq) | OFF |
| 8 | Replace | [ISIR_ReporterOrgReview](powerquery/ISIR_ReporterOrgReview.pq) | OFF |
| 9 | New | [ISIR_ReporterOrgSnapshotAdditions](powerquery/ISIR_ReporterOrgSnapshotAdditions.pq) | OFF |
| 10 | Replace after capture | [FactIncident](powerquery/FactIncident.pq) | ON |
| 11 | New after capture | [DimReporterSubsidiary](powerquery/DimReporterSubsidiary.pq) | ON |

The updated organization suite should return **30 PASS** rows. It requires both
function queries. The original 22-test `ISIR_SelfTest` is unchanged. New code has
passed M syntax checks; the new native tests and workbook read-back are pending.

The snapshot staging query starts empty. After saving the workbook, set its
`SnapshotFilePath` to the saved **snapshot `.xlsx` file**, not the employee CSV.
Keep that configured connection on future
updates. The named Excel table must be `ISIR_OrgSnapshot`.

## Final load configuration

Load only `FactIncident`, `DimDate`, `DimCategory`, and `DimReporterSubsidiary`.
All source/staging, diagnostic, review, additions queries, functions, and parameters
remain unloaded. Do not delete them. Final relationships, sorting and measures are
in [model setup](docs/model-setup.txt); [the current guide](docs/reporter-org-setup.txt)
includes snapshot capture and the complete transition out of Transform Data.

## Existing starter files

Keep these installed and unchanged:
[fnISIRTransform](powerquery/fnISIRTransform.pq),
[ISIR_SelfTest](powerquery/ISIR_SelfTest.pq),
[stg_ISIR_Parsed](powerquery/stg_ISIR_Parsed.pq),
[ISIR_Validation](powerquery/ISIR_Validation.pq),
[ISIR_FieldProfile](powerquery/ISIR_FieldProfile.pq),
[ISIR_Exceptions](powerquery/ISIR_Exceptions.pq),
[DimDate](powerquery/DimDate.pq), and [DimCategory](powerquery/DimCategory.pq).
Keep the existing `stg_ISIR_Raw` SharePoint connection unchanged. The old
User-at-Fault `ISIR_SubsidiaryAudit` is superseded and stays unloaded.
Starter measures are in [dax/](dax/); create them one at a time with Modeling > New measure.

## Reporting rules and progress

- One row is one incident. Keep all source rows, including incidents abroad and
  Cancel workflow records until their reporting meaning is decided.
- The original 22 tests and former 12 organization tests passed in Desktop.
  The revised 30 organization tests have not yet run there.
- Use curated categories and asset counts; preserve null quantities and undated
  incidents. AI suggestions do not overwrite curated values.
- Fiscal definitions, completeness cutoff, final asset reconciliation, and
  department/geography modeling remain pending.
- The directory export date supplied by the user is `2026-10-26`; change the
  parameter when the directory file is replaced. No exact export time is invented.
- Original SharePoint data is read-only. No writeback or new pipeline is deployed.

See [validation status](docs/validation.txt) and [change history](CHANGELOG.md).
Keep employee exports, saved assignment workbooks, tenant credentials, and
incident-bearing PBIX files in corporate storage, outside this repository.
