// Query name: DimReporterSubsidiary | Enable load: ON
// Saved assignments only; missing assignments remain explicit.
let
    Source = Table.SelectColumns(FactIncident, {"ReporterSubsidiaryKey", "ReporterSubsidiarySnapshot"}),
    Grouped = Table.Group(Source, {"ReporterSubsidiaryKey"}, {{"ReporterSubsidiary", each
        if [ReporterSubsidiaryKey]{0} = "U|" then "Unassigned" else
        Text.Range([ReporterSubsidiaryKey]{0}, 2), type text}}),
    Output = Table.Sort(Grouped, {{"ReporterSubsidiary", Order.Ascending}})
in
    Output
