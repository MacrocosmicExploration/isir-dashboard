// Query name: ISIR_FieldProfile
// Summarizes low-cardinality fields. Each field's row counts should sum to source count.
let
    T = Table.Buffer(stg_ISIR_Parsed),
    Fields = {"IncidentCategory", "SubsidiaryCandidate", "LostItems", "IncidentDateStatus",
        "LostOtherStatus", "USBCountStatus", "ConsistencyStatus", "CaseState", "Task Phase"},
    Tables = List.Transform(Fields, (field) =>
        let
            One = Table.RenameColumns(Table.SelectColumns(T, {field}), {{field, "Value"}}),
            Normalized = Table.TransformColumns(One, {{"Value", each if _ = null then "(blank)" else Text.From(_), type text}}),
            Grouped = Table.Group(Normalized, {"Value"}, {{"Rows", each Table.RowCount(_), Int64.Type}}),
            Labeled = Table.AddColumn(Grouped, "Field", each field, type text)
        in Table.ReorderColumns(Labeled, {"Field", "Value", "Rows"})
    ),
    Combined = Table.Combine(Tables),
    Sorted = Table.Sort(Combined, {{"Field", Order.Ascending}, {"Rows", Order.Descending}, {"Value", Order.Ascending}})
in
    Sorted
