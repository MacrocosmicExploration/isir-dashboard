// Query name: ISIR_ReporterOrgReview | Enable load: OFF
// Local review of unresolved assignments only. Does not alter any incident or match.
// EmployeeMatches contains names/emails for local inspection; do not upload its contents.
let
    Clean = (x as any) as nullable text =>
        if x = null then null else
        let t = Text.Trim(Text.Replace(Text.From(x), Character.FromNumber(160), " "))
        in if t = "" then null else t,
    Unresolved = Table.SelectRows(ISIR_ReporterOrgPreview, each [Action] = "Leave blank - review or retry"),
    E0 = Table.SelectColumns(stg_GLOBAL_EMPLOYEE_Raw, {"EMAILADDRESS", "ACTIVEDIRECTORYDISPLAYNAME"}),
    E1 = Table.AddColumn(E0, "EmailKey", each
        let t = Clean([EMAILADDRESS]) in if t = null then null else Text.Lower(t, "en-US"), type nullable text),
    E2 = Table.SelectRows(E1, each [EmailKey] <> null),
    E3 = Table.AddColumn(E2, "DisplayNameNormalized", each
        let t = Clean([ACTIVEDIRECTORYDISPLAYNAME]) in if t = null then null else
        Text.Upper(Text.Combine(List.Select(Text.SplitAny(t, " #(tab)#(cr)#(lf)"), each _ <> ""), " "), "en-US"), type nullable text),
    E4 = Table.AddColumn(E3, "DirectoryPrefix", each
        let tokens = if [DisplayNameNormalized] = null then {} else Text.Split([DisplayNameNormalized], " ")
        in if List.Count(tokens) < 2 then null else tokens{0}, type nullable text),
    Joined = Table.NestedJoin(Unresolved, {"ReporterEmailKey"}, E4, {"EmailKey"}, "EmployeeMatches", JoinKind.LeftOuter),
    Added = Table.AddColumn(Joined, "Review", each
        let candidates = [EmployeeMatches],
            n = Table.RowCount(candidates),
            names = List.Distinct(List.RemoveNulls(candidates[DisplayNameNormalized])),
            prefixes = List.Sort(List.Distinct(List.RemoveNulls(candidates[DirectoryPrefix]))),
            missingPrefixes = n - List.NonNullCount(candidates[DirectoryPrefix]),
            classification = if n = 0 then [MatchStatus] else
                if missingPrefixes > 0 then "Missing or unsupported display name in candidates" else
                if n > 1 and List.Count(prefixes) > 1 then "Duplicate rows - conflicting subsidiary prefixes" else
                if n > 1 and List.Count(names) > 1 then "Duplicate rows - same prefix, different display names" else
                if n > 1 then "Duplicate rows - same normalized display name and prefix" else
                "Review source record"
        in [
            DirectoryRowsFound = n,
            DistinctDisplayNameCount = List.Count(names),
            DistinctSubsidiaryPrefixCount = List.Count(prefixes),
            MissingPrefixRows = missingPrefixes,
            SubsidiaryPrefixes = Text.Combine(prefixes, " | "),
            ReviewClassification = classification
        ], type record),
    Expanded = Table.ExpandRecordColumn(Added, "Review", {"DirectoryRowsFound", "DistinctDisplayNameCount", "DistinctSubsidiaryPrefixCount", "MissingPrefixRows", "SubsidiaryPrefixes", "ReviewClassification"}),
    Output = Table.SelectColumns(Expanded, {"ID", "SourceItemID", "ReporterEmailKey", "MatchStatus", "DirectoryRowsFound", "DistinctDisplayNameCount", "DistinctSubsidiaryPrefixCount", "MissingPrefixRows", "SubsidiaryPrefixes", "ReviewClassification", "EmployeeMatches"}),
    Typed = Table.TransformColumnTypes(Output, {
        {"DirectoryRowsFound", Int64.Type}, {"DistinctDisplayNameCount", Int64.Type},
        {"DistinctSubsidiaryPrefixCount", Int64.Type}, {"MissingPrefixRows", Int64.Type},
        {"SubsidiaryPrefixes", type text}, {"ReviewClassification", type text}
    })
in
    Typed
