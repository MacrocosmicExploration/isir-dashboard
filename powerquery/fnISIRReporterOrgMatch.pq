// Query name: fnISIRReporterOrgMatch | Function; do not load or invoke manually.
// READ ONLY. A proposed value is not a persisted snapshot.
// Existing nonblank ReporterSubsidiarySnapshot values are preserved exactly.
(Incidents as table, Employees as table) as table =>
let
    Clean = (x as any) as nullable text =>
        if x = null then null else
        let t = Text.Trim(Text.Replace(Text.From(x), Character.FromNumber(160), " "))
        in if t = "" then null else t,
    Email = (x as any) as nullable text =>
        let t = Clean(x) in if t = null then null else Text.Lower(t, "en-US"),
    RequiredI = {"ID", "SourceItemID", "ReporterEmail"},
    RequiredE = {"EMAILADDRESS", "ACTIVEDIRECTORYDISPLAYNAME"},
    MissingI = List.Difference(RequiredI, Table.ColumnNames(Incidents)),
    MissingE = List.Difference(RequiredE, Table.ColumnNames(Employees)),
    CheckedI = if List.Count(MissingI) > 0 then error Error.Record("ISIR.OrgSchema", "Missing incident columns.", MissingI) else Incidents,
    CheckedE = if List.Count(MissingE) > 0 then error Error.Record("ISIR.OrgSchema", "Missing employee columns.", MissingE) else Employees,
    I0 = Table.SelectColumns(CheckedI, RequiredI & {"ReporterSubsidiarySnapshot", "ReporterEmailAtCapture"}, MissingField.UseNull),
    I = if List.NonNullCount(I0[ID]) <> Table.RowCount(I0) or List.Count(List.Distinct(I0[ID])) <> Table.RowCount(I0) then
        error Error.Record("ISIR.OrgKey", "Incident IDs must be nonblank and unique. No rows were removed.", null) else I0,
    E0 = Table.SelectColumns(CheckedE, RequiredE),
    E1 = Table.AddColumn(E0, "EmailKey", each Email([EMAILADDRESS]), type nullable text),
    // Never match null incident emails to null employee emails.
    E2 = Table.SelectRows(E1, each [EmailKey] <> null),
    // Exactly one grouped lookup row per normalized email; no incident fan-out.
    Grouped = Table.Group(E2, {"EmailKey"}, {{"Lookup", (g as table) as record =>
        let n = Table.RowCount(g),
            display = if n = 1 then Clean(g[ACTIVEDIRECTORYDISPLAYNAME]{0}) else null,
            tokens = if display = null then {} else List.Select(Text.SplitAny(display, " #(tab)#(cr)#(lf)"), each _ <> ""),
            prefix = if List.Count(tokens) < 2 then null else Text.Upper(tokens{0}, "en-US"),
            status = if n > 1 then "Duplicate employee email" else
                if prefix = null then "Missing or unsupported display name" else "Unique email match"
        in [EmployeeMatchRows = n, DirectoryPrefixCandidate = prefix, DirectoryMatchStatus = status], type record}}),
    Lookup = Table.ExpandRecordColumn(Grouped, "Lookup", {"EmployeeMatchRows", "DirectoryPrefixCandidate", "DirectoryMatchStatus"}),
    WithKey = Table.AddColumn(I, "ReporterEmailKey", each Email([ReporterEmail]), type nullable text),
    Merged = Table.NestedJoin(WithKey, {"ReporterEmailKey"}, Lookup, {"EmailKey"}, "Employee", JoinKind.LeftOuter),
    Expanded = Table.ExpandTableColumn(Merged, "Employee", {"EmployeeMatchRows", "DirectoryPrefixCandidate", "DirectoryMatchStatus"}),
    Derived = Table.AddColumn(Expanded, "Decision", each
        let existing = Clean([ReporterSubsidiarySnapshot]),
            matchStatus = if [ReporterEmailKey] = null then "Missing reporter email" else
                if [DirectoryMatchStatus] = null then "No employee match" else [DirectoryMatchStatus],
            candidate = [DirectoryPrefixCandidate],
            canPropose = existing = null and matchStatus = "Unique email match",
            capturedEmail = Email([ReporterEmailAtCapture]),
            reporterChanged = existing <> null and capturedEmail <> null and capturedEmail <> [ReporterEmailKey]
        in [
            MatchStatus = matchStatus,
            ProposedReporterSubsidiary = if canPropose then candidate else null,
            Action = if existing <> null then "Keep existing snapshot" else
                if canPropose then "Propose fill - persistence required" else "Leave blank - review or retry",
            CurrentDirectoryDiffers = if existing = null or candidate = null then false else Text.Upper(existing, "en-US") <> candidate,
            ReporterEmailChangedSinceCapture = reporterChanged
        ], type record),
    Decisions = Table.ExpandRecordColumn(Derived, "Decision", {"MatchStatus", "ProposedReporterSubsidiary", "Action", "CurrentDirectoryDiffers", "ReporterEmailChangedSinceCapture"}),
    Output = Table.SelectColumns(Decisions, {"ID", "SourceItemID", "ReporterEmailKey", "ReporterSubsidiarySnapshot", "EmployeeMatchRows", "DirectoryPrefixCandidate", "MatchStatus", "ProposedReporterSubsidiary", "Action", "CurrentDirectoryDiffers", "ReporterEmailChangedSinceCapture"}),
    Typed = Table.TransformColumnTypes(Output, {
        {"ID", Int64.Type}, {"SourceItemID", Int64.Type}, {"ReporterSubsidiarySnapshot", type text},
        {"EmployeeMatchRows", Int64.Type}, {"DirectoryPrefixCandidate", type text}, {"MatchStatus", type text},
        {"ProposedReporterSubsidiary", type text}, {"Action", type text},
        {"CurrentDirectoryDiffers", type logical}, {"ReporterEmailChangedSinceCapture", type logical}
    })
in
    Typed
