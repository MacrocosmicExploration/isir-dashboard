// Query name: fnISIRAttachOrgSnapshot | Function; no load.
// Join saved, literal assignments by SourceItemID. Never reads the current directory.
// Input must belong to the same ISIR source as this one-source snapshot file.
(Incidents as table, Snapshots as table) as table =>
let
    Fields = {"ReporterSubsidiarySnapshot", "ReporterEmailAtCapture", "ReporterMatchedEmailAtCapture", "ReporterOrgCapturedAtUTC", "ReporterOrgDirectoryExtractDate", "ReporterOrgCaptureBasis", "ReporterOrgMatchMethod"},
    Required = {"SourceItemID", "ReporterSubsidiarySnapshot", "ReporterEmailAtCapture"},
    Missing = List.Difference(Required, Table.ColumnNames(Snapshots)),
    Schema = if List.Count(Missing) > 0 then error Error.Record("ISIR.SnapshotSchema", "Missing snapshot workbook columns.", Missing) else Snapshots,
    Chosen = Table.SelectColumns(Schema, {"SourceItemID"} & Fields, MissingField.UseNull),
    // Ignore only completely empty worksheet rows; never silently remove a partial record.
    Nonempty = Table.SelectRows(Chosen, each List.AnyTrue(List.Transform(Record.FieldValues(_), (v) => v <> null and Text.Trim(Text.From(v)) <> ""))),
    KeysOK = (t as table) as logical => List.AllTrue(List.Transform(t[SourceItemID], (v) =>
        v <> null and (try Number.From(v) > 0 and Number.From(v) = Int64.From(v) otherwise false))),
    SafeS = if not KeysOK(Nonempty) then error Error.Record("ISIR.SnapshotKey", "Snapshot keys must be nonblank positive whole numbers.", null) else Nonempty,
    SafeI = if not KeysOK(Incidents) then error Error.Record("ISIR.SourceKey", "SourceItemID must be a nonblank positive whole number.", null) else Incidents,
    S = Table.TransformColumnTypes(SafeS, {{"SourceItemID", Int64.Type}, {"ReporterSubsidiarySnapshot", type text}, {"ReporterEmailAtCapture", type text}, {"ReporterMatchedEmailAtCapture", type text}, {"ReporterOrgCapturedAtUTC", type text}, {"ReporterOrgDirectoryExtractDate", type date}, {"ReporterOrgCaptureBasis", type text}, {"ReporterOrgMatchMethod", type text}}, "en-US"),
    I = Table.TransformColumnTypes(SafeI, {{"SourceItemID", Int64.Type}}),
    CheckedS = if List.Count(List.Distinct(S[SourceItemID])) <> Table.RowCount(S) then error Error.Record("ISIR.SnapshotKey", "Duplicate saved SourceItemID. Resolve it; do not pick a row automatically.", null) else S,
    CheckedI = if List.Count(List.Distinct(I[SourceItemID])) <> Table.RowCount(I) then error Error.Record("ISIR.SourceKey", "Duplicate source SourceItemID. No incidents were removed.", null) else I,
    Base = Table.RemoveColumns(CheckedI, Fields, MissingField.Ignore),
    Merged = Table.NestedJoin(Base, {"SourceItemID"}, CheckedS, {"SourceItemID"}, "SavedOrg", JoinKind.LeftOuter),
    Expanded = Table.ExpandTableColumn(Merged, "SavedOrg", Fields)
in
    Expanded
