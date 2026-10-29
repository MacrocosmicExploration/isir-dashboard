// Query name: FactIncident | Enable load: ON
// One row per incident; all source rows remain, including Cancel workflow records.
// Subsidiary comes only from saved incident assignments; no live-directory fallback.
let
    Source = fnISIRAttachOrgSnapshot(stg_ISIR_Parsed, stg_ISIR_OrgSnapshot_Raw),
    IDs = Source[ID],
    Checked = if List.NonNullCount(IDs) <> List.Count(IDs) then
        error Error.Record("ISIR.Model", "Missing incident ID; correct the source before refreshing the model.", null)
        else if List.Count(List.Distinct(IDs)) <> List.Count(IDs) then
        error Error.Record("ISIR.Model", "Duplicate incident ID; investigate without automatically removing rows.", null)
        else Source,
    Selected = Table.SelectColumns(Checked, {
        "ID", "SourceItemID", "IncidentDate", "SubmittedDateOnly", "IncidentDateStatus",
        "IncidentCategory", "Task Phase", "CaseState", "ConsistencyStatus",
        "PhoneCount", "PCCount", "USBCount", "BadgeCount", "DocumentCount",
        "KnownLostAssetCount", "HasRecordedAssetLoss", "PhoneCountStatus", "PCCountStatus",
        "USBCountStatus", "LostOtherStatus", "NeedsReview",
        "ReporterSubsidiarySnapshot", "ReporterOrgCapturedAtUTC", "ReporterOrgDirectoryExtractDate",
        "ReporterOrgCaptureBasis", "ReporterOrgMatchMethod"
    }),
    Renamed = Table.RenameColumns(Selected, {
        {"ID", "IncidentID"}, {"SubmittedDateOnly", "SubmittedDate"},
        {"Task Phase", "TaskPhase"}, {"IncidentCategory", "IncidentCategoryRaw"}
    }),
    // U| is a reserved missing-category member; C| prefixes real category values.
    // Match labels case-insensitively without merging different category meanings.
    CategoryKey = Table.AddColumn(Renamed, "CategoryKey", each
        if [IncidentCategoryRaw] = null then "U|" else
        "C|" & Text.Upper([IncidentCategoryRaw], "en-US"), type text),
    MissingCategory = Table.AddColumn(CategoryKey, "IsCategoryMissing", each
        [IncidentCategoryRaw] = null, type logical),
    SubsidiaryKey = Table.AddColumn(MissingCategory, "ReporterSubsidiaryKey", each
        let s = if [ReporterSubsidiarySnapshot] = null then "" else Text.Trim([ReporterSubsidiarySnapshot])
        in if s = "" then "U|" else "S|" & Text.Upper(s, "en-US"), type text),
    Typed = Table.TransformColumnTypes(SubsidiaryKey, {
        {"IncidentID", Int64.Type}, {"SourceItemID", Int64.Type},
        {"IncidentDate", type date}, {"SubmittedDate", type date},
        {"TaskPhase", type text}, {"CaseState", type text}, {"ConsistencyStatus", type text}
    })
in
    Typed
