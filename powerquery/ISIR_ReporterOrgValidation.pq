// Query name: ISIR_ReporterOrgValidation | Enable load: OFF
// Aggregate results only; safe to review without sharing employee identities.
let
    T = Table.Buffer(ISIR_ReporterOrgPreview),
    Count = (predicate as function) as number => Table.RowCount(Table.SelectRows(T, predicate)),
    Metrics = #table(type table [Section = text, Result = text, Rows = Int64.Type], {
        {"Counts", "Source incidents", Table.RowCount(stg_ISIR_Raw)},
        {"Counts", "Preview incidents", Table.RowCount(T)},
        {"Counts", "Row count difference - must be zero", Table.RowCount(T) - Table.RowCount(stg_ISIR_Raw)},
        {"Counts", "Active exact email matches", Count(each [MatchStatus] = "Unique active exact match")},
        {"Counts", "Active TEL-domain alias matches - review initially", Count(each [MatchStatus] = "Unique active alias match")},
        {"Counts", "Ambiguous active matches", Count(each [MatchStatus] = "Duplicate active employee email")},
        {"Counts", "No active match", Count(each [MatchStatus] = "No active employee match")},
        {"Counts", "Existing snapshots kept", Count(each [Action] = "Keep existing snapshot")},
        {"Counts", "New proposed fills - not yet saved", Count(each [Action] = "Propose fill - persistence required")},
        {"Counts", "Blank assignments requiring review or retry", Count(each [Action] = "Leave blank - review or retry")},
        {"Counts", "Current directory differs from saved snapshot", Count(each [CurrentDirectoryDiffers])},
        {"Counts", "Reporter email changed since capture", Count(each [ReporterEmailChangedSinceCapture])}
    }),
    Match0 = Table.Group(T, {"MatchStatus"}, {{"Rows", each Table.RowCount(_), Int64.Type}}),
    Match1 = Table.RenameColumns(Match0, {{"MatchStatus", "Result"}}),
    Matches = Table.AddColumn(Match1, "Section", each "Email match status", type text),
    Proposed = Table.SelectRows(T, each [ProposedReporterSubsidiary] <> null),
    Prefix0 = Table.Group(Proposed, {"ProposedReporterSubsidiary"}, {{"Rows", each Table.RowCount(_), Int64.Type}}),
    Prefix1 = Table.RenameColumns(Prefix0, {{"ProposedReporterSubsidiary", "Result"}}),
    Prefixes = Table.AddColumn(Prefix1, "Section", each "Proposed subsidiary prefix", type text),
    Combined = Table.Combine({Metrics, Matches, Prefixes}),
    Output = Table.ReorderColumns(Combined, {"Section", "Result", "Rows"})
in
    Output
