// Query name: ISIR_ReporterOrgPreview | Enable load: OFF
// Reads ReporterEmail directly from stg_ISIR_Raw: the original parser omits it.
// Import the employee CSV as stg_GLOBAL_EMPLOYEE_Raw before creating this query.
// Optional saved SharePoint columns are read when present; no writes occur here.
let
    Preview = fnISIRReporterOrgMatch(stg_ISIR_Raw, stg_GLOBAL_EMPLOYEE_Raw)
in
    Preview
