// Query name: DimCategory | Enable load: ON
// Keep curated category meanings; missing categories receive an explicit label.
let
    Source = Table.SelectColumns(FactIncident, {"CategoryKey", "IncidentCategoryRaw"}),
    Grouped = Table.Group(Source, {"CategoryKey"}, {{"Category", each
        if [CategoryKey]{0} = "U|" then "Uncategorized" else
        List.First(List.Sort(List.RemoveNulls([IncidentCategoryRaw]), Comparer.Ordinal)), type text}}),
    Sorted = Table.Sort(Grouped, {{"Category", Order.Ascending}})
in
    Sorted
