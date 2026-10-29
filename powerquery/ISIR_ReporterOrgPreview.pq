// Query name: ISIR_ReporterOrgPreview | Enable load: OFF
// Read saved assignments from the separate workbook; never write to SharePoint.
let
    WithSaved = fnISIRAttachOrgSnapshot(stg_ISIR_Raw, stg_ISIR_OrgSnapshot_Raw),
    Preview = fnISIRReporterOrgMatch(WithSaved, stg_GLOBAL_EMPLOYEE_Raw)
in
    Preview
