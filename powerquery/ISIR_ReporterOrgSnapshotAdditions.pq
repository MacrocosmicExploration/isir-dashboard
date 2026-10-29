// Query name: ISIR_ReporterOrgSnapshotAdditions | Enable load: OFF
// NEW assignments only. Review, copy, and paste as VALUES into the snapshot workbook.
// This query does not save anything. CapturedAt is proposal generation time,
// retained literally on save; it is not the workbook's save/modified timestamp.
let
    T = Table.SelectRows(ISIR_ReporterOrgPreview, each [Action] = "Propose fill - persistence required"),
    Selected = Table.SelectColumns(T, {"SourceItemID", "ProposedReporterSubsidiary", "ReporterEmailKey", "MatchedEmployeeEmailKey", "MatchMethod"}),
    Renamed = Table.RenameColumns(Selected, {{"ProposedReporterSubsidiary", "ReporterSubsidiarySnapshot"}, {"ReporterEmailKey", "ReporterEmailAtCapture"}, {"MatchedEmployeeEmailKey", "ReporterMatchedEmailAtCapture"}, {"MatchMethod", "ReporterOrgMatchMethod"}}),
    Captured = Table.AddColumn(Renamed, "ReporterOrgCapturedAtUTC", each DateTimeZone.ToText(DateTimeZone.FixedUtcNow(), [Format="yyyy-MM-dd'T'HH:mm:ss'Z'", Culture="en-US"]), type text),
    ExtractDate = Table.AddColumn(Captured, "ReporterOrgDirectoryExtractDate", each Date.From(pEmployeeDirectoryExtractDate), type date),
    Basis = Table.AddColumn(ExtractDate, "ReporterOrgCaptureBasis", each "Current-directory lookup (CSV)", type text),
    Output = Table.ReorderColumns(Basis, {"SourceItemID", "ReporterSubsidiarySnapshot", "ReporterEmailAtCapture", "ReporterMatchedEmailAtCapture", "ReporterOrgCapturedAtUTC", "ReporterOrgDirectoryExtractDate", "ReporterOrgCaptureBasis", "ReporterOrgMatchMethod"})
in
    Output
