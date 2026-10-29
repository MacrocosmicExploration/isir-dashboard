// Query name: ISIR_SubsidiaryAudit | Enable load: OFF
// Aggregate diagnostics only. The listed prefixes are review candidates, not approved mappings.
// No names, email addresses, IDs or incident narratives are returned.
let
    Source = stg_ISIR_Parsed,
    ReviewPrefixes = {"TEA", "TEH", "TMEA", "TTCA"},
    SourceState = Table.AddColumn(Source, "SourceFieldState", each
        let raw = Record.Field(_, "User at Fault"),
            text = if raw = null then null else Text.Trim(Text.Replace(Text.From(raw), Character.FromNumber(160), " "))
        in if text = null or text = "" then "Blank User at Fault" else "Nonblank User at Fault", type text),
    Bucket = Table.AddColumn(SourceState, "PrefixBucket", each
        if [SubsidiaryCandidate] = null then "No first token" else
        if List.Contains(ReviewPrefixes, [SubsidiaryCandidate]) then [SubsidiaryCandidate] else
        "Other first token - inspect locally", type text),
    Grouped = Table.Group(Bucket, {"SourceFieldState", "PrefixBucket"}, {{"Rows", each Table.RowCount(_), Int64.Type}}),
    Sorted = Table.Sort(Grouped, {{"Rows", Order.Descending}, {"PrefixBucket", Order.Ascending}})
in
    Sorted
