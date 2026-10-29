// Query name: DimDate | Enable load: ON
// Calendar dates only. Fiscal fields will be added after the fiscal convention is confirmed.
// Calendar extent does not certify reporting completeness or refresh freshness.
let
    Dates = List.RemoveNulls(FactIncident[IncidentDate] & FactIncident[SubmittedDate]),
    TodayUTC = Date.From(DateTimeZone.FixedUtcNow()),
    Bounds = Dates & {TodayUTC},
    FirstDate = Date.StartOfYear(List.Min(Bounds)),
    LastDate = Date.EndOfYear(List.Max(Bounds)),
    DateList = List.Dates(FirstDate, Duration.Days(LastDate - FirstDate) + 1, #duration(1,0,0,0)),
    Base = Table.FromColumns({DateList}, type table [Date = date]),
    Year = Table.AddColumn(Base, "Year", each Date.Year([Date]), Int64.Type),
    MonthNumber = Table.AddColumn(Year, "MonthNumber", each Date.Month([Date]), Int64.Type),
    MonthName = Table.AddColumn(MonthNumber, "MonthName", each Date.ToText([Date], [Format="MMM", Culture="en-US"]), type text),
    MonthStart = Table.AddColumn(MonthName, "MonthStart", each Date.StartOfMonth([Date]), type date),
    YearMonth = Table.AddColumn(MonthStart, "YearMonth", each Date.ToText([Date], [Format="yyyy-MM", Culture="en-US"]), type text),
    YearMonthSort = Table.AddColumn(YearMonth, "YearMonthSort", each [Year] * 100 + [MonthNumber], Int64.Type),
    QuarterNumber = Table.AddColumn(YearMonthSort, "QuarterNumber", each Date.QuarterOfYear([Date]), Int64.Type),
    Quarter = Table.AddColumn(QuarterNumber, "Quarter", each "Q" & Text.From([QuarterNumber], "en-US"), type text)
in
    Quarter
