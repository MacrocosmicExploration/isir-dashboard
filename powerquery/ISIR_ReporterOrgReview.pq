// Query name: ISIR_ReporterOrgReview | Enable load: OFF
// Unresolved incidents; nested candidates contain ACTIVE rows only.
let
    Clean = (x as any) as nullable text => if x = null then null else
        let t = Text.Trim(Text.Replace(Text.From(x), Character.FromNumber(160), " ")) in if t = "" then null else t,
    Unresolved = Table.SelectRows(ISIR_ReporterOrgPreview, each [Action] = "Leave blank - review or retry"),
    E0 = Table.SelectColumns(stg_GLOBAL_EMPLOYEE_Raw, {"EMAILADDRESS", "ACTIVEDIRECTORYDISPLAYNAME", "EMPLOYEE_STATUS"}),
    Active = Table.SelectRows(E0, each let s = Clean([EMPLOYEE_STATUS]) in s <> null and Text.Upper(s, "en-US") = "ACTIVE"),
    Key = Table.AddColumn(Active, "EmailKey", each let e = Clean([EMAILADDRESS]) in if e = null then null else Text.Lower(e, "en-US"), type nullable text),
    Nonblank = Table.SelectRows(Key, each [EmailKey] <> null),
    Joined = Table.NestedJoin(Unresolved, {"LookupEmailKey"}, Nonblank, {"EmailKey"}, "ActiveEmployeeMatches", JoinKind.LeftOuter),
    Output = Table.SelectColumns(Joined, {"ID", "SourceItemID", "ReporterEmailKey", "ReporterAlternateEmailKey", "ExactActiveRows", "AlternateActiveRows", "MatchStatus", "MatchMethod", "LookupEmailKey", "ActiveEmployeeMatches"})
in
    Output
