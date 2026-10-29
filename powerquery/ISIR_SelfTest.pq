// Query name: ISIR_SelfTest
// Synthetic data only. Requires fnISIRTransform; does NOT read SharePoint.
// Every row in this output should say PASS before using the source queries.
let
    Base = [ID = 0, SourceItemID = 0, SubmittedDate = #datetime(2026, 2, 9, 0, 0, 0),
        IsirSnapshot = "Incident Date: 2026-02-09#(lf)City: Example City#(lf)State: Example State#(lf)Country: United States#(lf)Place of Work: Different City",
        #"Incident Category" = "Example category", #"User at Fault" = "TEA GCE SPS Person, Example",
        LostItems = null, LostCountPhone = 0, LostCountPC = 0, LostCountUSB = null, LostOther = null],
    Cases = {
        [ID=1, IsirSnapshot="Incident Date: 20206-02-09", LostItems="Other", LostOther="Access keys / badges: 1"],
        [ID=2, LostItems="PC, Phone, Other", LostCountPC=4, LostCountPhone=2,
            LostOther="USB: 1; Access keys / badges: 3; Documents / drawings: 2"],
        [ID=3, LostItems="Other", LostCountUSB=4, LostOther="USB: 4"],
        [ID=4, LostItems="Other", LostCountUSB=4, LostOther="USB: 1"],
        [ID=5, LostCountPC=null, LostCountPhone=null],
        [ID=6, LostItems="Other", LostOther="Documents / drawings: many"],
        [ID=7, LostItems="Other", LostOther="USB: 1; USB: 1"],
        [ID=8, IsirSnapshot="Incident Date: 02/09/2026"],
        [ID=9, IsirSnapshot="Incident Date: 2026/2/9"],
        [ID=10, IsirSnapshot="Incident Date: 2026-02-30"],
        [ID=11, LostItems="Other", LostOther="NFC tokens: 4"],
        [ID=12, LostCountPhone=0, LostCountPC=null],
        [ID=13, LostCountPhone=1.5, LostItems="Phone"],
        [ID=14, IsirSnapshot="Incident Date: 2026-02-09#(lf)Incident Date: 2026-02-10"],
        [ID=15, IsirSnapshot=null],
        [ID=16, LostItems="PC", LostCountPC=null],
        [ID=17, #"ConsistencyStatus"="Needs attention", CaseState="Pending", LostItems="Other", LostOther="USB: 1"]
    },
    Source = Table.FromRecords(List.Transform(Cases, each Record.Combine({Base, _})), null, MissingField.UseNull),
    Attempt = try Table.Buffer(fnISIRTransform(Source)),
    Run = if Attempt[HasError] then
        #table(type table [Test=text, Result=text, Detail=text],
            {{"Transform executes", "FAIL", Attempt[Error][Message]}})
        else
        let
            T = Attempt[Value],
            Row = (id as number) as record => Table.SelectRows(T, each [ID] = id){0},
            Check = (label as text, predicate as function) as record =>
                let a = try predicate()
                in [Test=label, Result=if a[HasError] then "FAIL" else if a[Value] = true then "PASS" else "FAIL",
                    Detail=if a[HasError] then a[Error][Message] else ""],
            Checks = {
                Check("One output row per input row", () => Table.RowCount(T)=17),
                Check("Five-digit year is rejected without changing SubmittedDate", () => Row(1)[IncidentDate]=null and Row(1)[SubmittedDateOnly]=#date(2026,2,9)),
                Check("Badge quantity recovered from LostOther", () => Row(1)[BadgeCount]=1 and Row(1)[KnownLostAssetCount]=1),
                Check("Semicolon-separated other assets parsed", () => Row(2)[USBCount]=1 and Row(2)[BadgeCount]=3 and Row(2)[DocumentCount]=2),
                Check("PC + phone + other quantities total correctly", () => Row(2)[KnownLostAssetCount]=12),
                Check("Same USB quantity in both fields counted once", () => Row(3)[USBCount]=4 and Row(3)[KnownLostAssetCount]=4),
                Check("Conflicting USB quantities are flagged and not guessed", () => Row(4)[USBCount]=null and Row(4)[USBCountStatus]="Conflict"),
                Check("All-missing quantities remain null", () => Row(5)[KnownLostAssetCount]=null and Row(5)[PCCount]=null),
                Check("Non-numeric LostOther quantity is flagged", () => Row(6)[LostOtherStatus]="Needs review" and Row(6)[DocumentCount]=null),
                Check("Repeated USB type is not silently summed", () => Row(7)[USBCount]=null and Row(7)[LostOtherStatus]="Needs review"),
                Check("Ambiguous month-first/day-first date is not guessed", () => Row(8)[IncidentDate]=null),
                Check("Year-first slash date is supported", () => Row(9)[IncidentDate]=#date(2026,2,9)),
                Check("Impossible date is rejected", () => Row(10)[IncidentDate]=null),
                Check("Unknown LostOther label is visible as an exception", () => Row(11)[LostOtherStatus]="Needs review"),
                Check("Zero and missing remain distinct", () => Row(12)[PhoneCount]=0 and Row(12)[PCCount]=null),
                Check("Fractional device quantity is rejected", () => Row(13)[PhoneCount]=null and Row(13)[PhoneCountStatus]="Invalid"),
                Check("Repeated incident-date labels are flagged", () => Row(14)[IncidentDate]=null and Row(14)[IncidentDateStatus]="Multiple labels"),
                Check("Absent snapshot retains the incident", () => Row(15)[IncidentDateStatus]="Missing label"),
                Check("Selected asset with unknown quantity is flagged", () => Row(16)[HasRecordedAssetLoss] and Row(16)[AssetIssues]<>""),
                Check("Workflow status does not exclude reporting-ready rows", () => Row(17)[USBCount]=1),
                Check("Prefix extraction preserves subsidiary candidate", () => Row(2)[SubsidiaryCandidate]="TEA"),
                Check("Workplace and snapshot city remain separate", () => Row(2)[SnapshotCity]="Example City" and Row(2)[SnapshotPlaceOfWork]="Different City")
            }
        in Table.FromRecords(Checks, type table [Test=text, Result=text, Detail=text])
in
    Run
