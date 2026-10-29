// Query name: ISIR_Validation
// Diagnostic counts only; no incident narratives or employee identities.
let
    T = Table.Buffer(stg_ISIR_Parsed),
    N = Table.RowCount(T),
    Count = (predicate as function) as number => Table.RowCount(Table.SelectRows(T, predicate)),
    DuplicateExtras = (values as list) as number =>
        let nonNull = List.RemoveNulls(values)
        in List.Count(nonNull) - List.Count(List.Distinct(nonNull)),
    DateText = (values as list, earliest as logical) as text =>
        let dates = List.RemoveNulls(values)
        in if List.Count(dates) = 0 then "No dates" else
            Date.ToText(if earliest then List.Min(dates) else List.Max(dates), [Format="yyyy-MM-dd", Culture="en-US"]),
    Rows = {
        {"Source rows", Table.RowCount(stg_ISIR_Raw), "178 at the initial checkpoint; may grow."},
        {"Parsed rows", N, "Must equal source rows."},
        {"Row count difference", N - Table.RowCount(stg_ISIR_Raw), "Must be zero; no records are intentionally removed."},
        {"Missing ID", Count(each [ID] = null), "Must be zero before using ID as a key."},
        {"Duplicate ID extra rows", DuplicateExtras(T[ID]), "Must be zero before using ID as a key."},
        {"Missing SourceItemID", Count(each [SourceItemID] = null), "Traceability check; do not remove these rows."},
        {"Duplicate SourceItemID extra rows", DuplicateExtras(T[SourceItemID]), "Investigate; do not automatically deduplicate."},
        {"Rows needing review", Count(each [NeedsReview]), "Open ISIR_Exceptions locally to see reasons."},
        {"Parsed occurrence dates", Count(each [IncidentDateStatus] = "Parsed"), "Syntactic success, not owner confirmation of field meaning."},
        {"Unparsed or missing occurrence dates", Count(each [IncidentDateStatus] <> "Parsed"), "Remain in incident total, but lack a usable occurrence date."},
        {"Future occurrence dates", Count(each [IsFutureIncidentDate]), "Compared with the UTC date of query evaluation."},
        {"Occurrence after submission", Count(each [DaysFromIncidentToSubmission] <> null and [DaysFromIncidentToSubmission] < 0), "Check source values and the meaning of SubmittedDate."},
        {"Earliest parsed occurrence date", DateText(T[IncidentDate], true), "Inspect history coverage before YoY reporting."},
        {"Latest parsed occurrence date", DateText(T[IncidentDate], false), "Does not establish that reporting is complete through this date."},
        {"Earliest SubmittedDate", DateText(T[SubmittedDateOnly], true), "Date extracted from the structured timestamp; no timezone shift."},
        {"Latest SubmittedDate", DateText(T[SubmittedDateOnly], false), "Not a refresh timestamp or completeness cutoff."},
        {"Missing curated category", Count(each [IncidentCategory] = null), "Use curated category; AI fields are not substitutes."},
        {"Missing subsidiary candidate", Count(each [SubsidiaryCandidate] = null), "Nonblank prefixes still require mapping review."},
        {"Rows with city and country extracted", Count(each [LocationExtractStatus] = "City and country extracted"), "Field meaning and geographic values still need verification."},
        {"Rows with asset issues", Count(each [AssetIssues] <> ""), "Do not present known quantities as a fully reconciled total."},
        {"Missing phone quantity", Count(each [PhoneCountStatus] = "Missing"), "Nulls have not been converted to zeros."},
        {"Missing PC quantity", Count(each [PCCountStatus] = "Missing"), "Nulls have not been converted to zeros."},
        {"Invalid phone quantity", Count(each [PhoneCountStatus] = "Invalid"), "Negative, fractional, or otherwise invalid count."},
        {"Invalid PC quantity", Count(each [PCCountStatus] = "Invalid"), "Negative, fractional, or otherwise invalid count."},
        {"USB sourced from LostOther", Count(each [USBCountStatus] = "LostOther"), "Recovered from a recognized labeled quantity."},
        {"USB recorded in both and agreeing", Count(each [USBCountStatus] = "Both agree; counted once"), "Included once, never added together."},
        {"USB conflicts", Count(each [USBCountStatus] = "Conflict"), "USB count left null until resolved."},
        {"LostOther needing review", Count(each [LostOtherStatus] = "Needs review"), "Unknown labels, invalid quantities, or repeated types."},
        {"Incidents with recorded asset-loss evidence", Count(each [HasRecordedAssetLoss]), "Based on selected LostItems or positive parsed quantities."}
    },
    Output = #table(type table [Check = text, Result = any, Meaning = text], Rows)
in
    Output
