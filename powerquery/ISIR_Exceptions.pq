// Query name: ISIR_Exceptions
// Inspect locally. These rows are NOT removed from stg_ISIR_Parsed.
let
    T = stg_ISIR_Parsed,
    Flagged = Table.SelectRows(T, each [NeedsReview]),
    Output = Table.SelectColumns(Flagged, {
        "ID", "SourceItemID", "IncidentCategory", "SubsidiaryCandidate",
        "SubmittedDateOnly", "IncidentDateRaw", "IncidentDate", "IncidentDateStatus",
        "LostItems", "LostCountPhone", "LostCountPC", "LostCountUSB", "LostOther",
        "PhoneCount", "PCCount", "USBCount", "BadgeCount", "DocumentCount",
        "KnownLostAssetCount", "AssetIssues", "QualityIssues"
    })
in
    Output
