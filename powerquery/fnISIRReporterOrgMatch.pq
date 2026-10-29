// Query name: fnISIRReporterOrgMatch | Function; no load.
// Active employees only. Exact email first; controlled tel.com/us.tel.com fallback.
// READ ONLY. Existing nonblank snapshots are kept; proposals require persistence.
(Incidents as table, Employees as table) as table =>
let
    Clean = (x as any) as nullable text =>
        if x = null then null else
        let t = Text.Trim(Text.Replace(Text.From(x), Character.FromNumber(160), " "))
        in if t = "" then null else t,
    Email = (x as any) as nullable text =>
        let t = Clean(x) in if t = null then null else Text.Lower(t, "en-US"),
    ValidEmail = (s as nullable text) as logical =>
        if s = null then false else
        let p = Text.Split(s, "@")
        in List.Count(p) = 2 and p{0} <> "" and p{1} <> "" and Text.Length(Text.Select(s, {" ", "#(tab)", "#(cr)", "#(lf)"})) = 0,
    AlternateEmail = (s as nullable text) as nullable text =>
        if not ValidEmail(s) then null else
        let p = Text.Split(s, "@")
        in if p{1} = "tel.com" then p{0} & "@us.tel.com" else
            if p{1} = "us.tel.com" then p{0} & "@tel.com" else null,
    RequiredI = {"ID", "SourceItemID", "ReporterEmail"},
    RequiredE = {"EMAILADDRESS", "ACTIVEDIRECTORYDISPLAYNAME", "EMPLOYEE_STATUS"},
    MissingI = List.Difference(RequiredI, Table.ColumnNames(Incidents)),
    MissingE = List.Difference(RequiredE, Table.ColumnNames(Employees)),
    CheckedI = if List.Count(MissingI) > 0 then error Error.Record("ISIR.OrgSchema", "Missing incident columns.", MissingI) else Incidents,
    CheckedE = if List.Count(MissingE) > 0 then error Error.Record("ISIR.OrgSchema", "Retain EMAILADDRESS, ACTIVEDIRECTORYDISPLAYNAME and EMPLOYEE_STATUS in the employee staging query.", MissingE) else Employees,
    I0 = Table.SelectColumns(CheckedI, RequiredI & {"ReporterSubsidiarySnapshot", "ReporterEmailAtCapture"}, MissingField.UseNull),
    I = if List.NonNullCount(I0[ID]) <> Table.RowCount(I0) or List.Count(List.Distinct(I0[ID])) <> Table.RowCount(I0) then
        error Error.Record("ISIR.OrgKey", "Incident IDs must be nonblank and unique. No incidents were removed.", null) else I0,
    E0 = Table.SelectColumns(CheckedE, RequiredE),
    // Active is a business eligibility rule, not a timestamp ranking.
    Active = Table.SelectRows(E0, each
        let status = Clean([EMPLOYEE_STATUS]) in status <> null and Text.Upper(status, "en-US") = "ACTIVE"),
    E1 = Table.AddColumn(Active, "EmailKey", each Email([EMAILADDRESS]), type nullable text),
    E2 = Table.SelectRows(E1, each ValidEmail([EmailKey])),
    Grouped = Table.Group(E2, {"EmailKey"}, {{"Lookup", (g as table) as record =>
        let n = Table.RowCount(g),
            display = if n = 1 then Clean(g[ACTIVEDIRECTORYDISPLAYNAME]{0}) else null,
            tokens = if display = null then {} else List.Select(Text.SplitAny(display, " #(tab)#(cr)#(lf)"), each _ <> ""),
            prefix = if List.Count(tokens) < 2 then null else Text.Upper(tokens{0}, "en-US")
        in [Count = n, Prefix = prefix], type record}}),
    WithKey = Table.AddColumn(I, "ReporterEmailKey", each Email([ReporterEmail]), type nullable text),
    WithAlt = Table.AddColumn(WithKey, "ReporterAlternateEmailKey", each AlternateEmail([ReporterEmailKey]), type nullable text),
    ExactJoin = Table.NestedJoin(WithAlt, {"ReporterEmailKey"}, Grouped, {"EmailKey"}, "Exact", JoinKind.LeftOuter),
    AltJoin = Table.NestedJoin(ExactJoin, {"ReporterAlternateEmailKey"}, Grouped, {"EmailKey"}, "Alternate", JoinKind.LeftOuter),
    Added = Table.AddColumn(AltJoin, "Decision", each
        let exact = if Table.IsEmpty([Exact]) then [Count = 0, Prefix = null] else [Exact]{0}[Lookup],
            alternate = if Table.IsEmpty([Alternate]) then [Count = 0, Prefix = null] else [Alternate]{0}[Lookup],
            useExact = exact[Count] > 0,
            useAlias = not useExact and alternate[Count] > 0,
            chosen = if useExact then exact else if useAlias then alternate else [Count = 0, Prefix = null],
            method = if useExact then "Exact email" else if useAlias then "TEL domain alias" else "None",
            lookupKey = if useAlias then [ReporterAlternateEmailKey] else [ReporterEmailKey],
            status = if [ReporterEmailKey] = null then "Missing reporter email" else
                if not ValidEmail([ReporterEmailKey]) then "Invalid reporter email" else
                if chosen[Count] = 0 then "No active employee match" else
                if chosen[Count] > 1 then "Duplicate active employee email" else
                if chosen[Prefix] = null then "Missing or unsupported display name" else
                if useAlias then "Unique active alias match" else "Unique active exact match",
            existing = Clean([ReporterSubsidiarySnapshot]),
            reliable = chosen[Count] = 1 and chosen[Prefix] <> null,
            canPropose = existing = null and reliable,
            capturedEmail = Email([ReporterEmailAtCapture])
        in [
            EmployeeMatchRows = chosen[Count], ExactActiveRows = exact[Count], AlternateActiveRows = alternate[Count],
            MatchMethod = method, LookupEmailKey = lookupKey,
            MatchedEmployeeEmailKey = if chosen[Count] = 1 then lookupKey else null,
            DirectoryPrefixCandidate = chosen[Prefix], MatchStatus = status,
            ProposedReporterSubsidiary = if canPropose then chosen[Prefix] else null,
            Action = if existing <> null then "Keep existing snapshot" else if canPropose then "Propose fill - persistence required" else "Leave blank - review or retry",
            CurrentDirectoryDiffers = existing <> null and chosen[Prefix] <> null and Text.Upper(existing, "en-US") <> chosen[Prefix],
            ReporterEmailChangedSinceCapture = existing <> null and capturedEmail <> null and capturedEmail <> [ReporterEmailKey]
        ], type record),
    Names = {"EmployeeMatchRows", "ExactActiveRows", "AlternateActiveRows", "MatchMethod", "LookupEmailKey", "MatchedEmployeeEmailKey", "DirectoryPrefixCandidate", "MatchStatus", "ProposedReporterSubsidiary", "Action", "CurrentDirectoryDiffers", "ReporterEmailChangedSinceCapture"},
    Expanded = Table.ExpandRecordColumn(Added, "Decision", Names),
    Selected = Table.SelectColumns(Expanded, {"ID", "SourceItemID", "ReporterEmailKey", "ReporterAlternateEmailKey", "ReporterSubsidiarySnapshot"} & Names),
    NumberNames = {"ID", "SourceItemID", "EmployeeMatchRows", "ExactActiveRows", "AlternateActiveRows"},
    LogicalNames = {"CurrentDirectoryDiffers", "ReporterEmailChangedSinceCapture"},
    TextNames = List.Difference(Table.ColumnNames(Selected), NumberNames & LogicalNames),
    Typed = Table.TransformColumnTypes(Selected,
        List.Transform(NumberNames, each {_, Int64.Type}) & List.Transform(LogicalNames, each {_, type logical}) & List.Transform(TextNames, each {_, type text}))
in
    Typed
