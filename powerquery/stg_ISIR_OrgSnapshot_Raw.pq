// Query name: stg_ISIR_OrgSnapshot_Raw | Enable load: OFF
// FIRST INSTALL: leave SnapshotFilePath empty to initialize an empty snapshot.
// After saving the workbook, enter its local/full network path below.
// Once connected, retain this connection; do not clear the path on later updates.
let
    SnapshotFilePath = "",
    Empty = #table(type table [
        SourceItemID = Int64.Type,
        ReporterSubsidiarySnapshot = nullable text,
        ReporterEmailAtCapture = nullable text,
        ReporterMatchedEmailAtCapture = nullable text,
        ReporterOrgCapturedAtUTC = nullable text,
        ReporterOrgDirectoryExtractDate = nullable date,
        ReporterOrgCaptureBasis = nullable text,
        ReporterOrgMatchMethod = nullable text
    ], {}),
    Output = if Text.Trim(SnapshotFilePath) = "" then Empty else
        let Workbook = Excel.Workbook(File.Contents(SnapshotFilePath), null, true)
        in Workbook{[Item = "ISIR_OrgSnapshot", Kind = "Table"]}[Data]
in
    Output
