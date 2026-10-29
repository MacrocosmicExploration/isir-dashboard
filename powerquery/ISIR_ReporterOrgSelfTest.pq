// Query name: ISIR_ReporterOrgSelfTest | Enable load: OFF
// Synthetic data only. Expected: 12 PASS rows. Run in Power BI Desktop.
let
    Employees = #table(type table [EMAILADDRESS = nullable text, ACTIVEDIRECTORYDISPLAYNAME = nullable text], {
        {" alpha@example.invalid ", "TEL FS SAMPLE, ALPHA"},
        {"duplicate@example.invalid", "TEA FS SAMPLE, DUP"},
        {"DUPLICATE@EXAMPLE.INVALID", "TEH FS SAMPLE, DUP"},
        {"empty@example.invalid", null},
        {null, "TEA FS SAMPLE, NOEMAIL"},
        {"single@example.invalid", "SAMPLE"}
    }),
    Incidents = #table(type table [ID = Int64.Type, SourceItemID = Int64.Type, ReporterEmail = nullable text, ReporterSubsidiarySnapshot = nullable text, ReporterEmailAtCapture = nullable text], {
        {1,101,"ALPHA@example.invalid",null,null},
        {2,102,"alpha@example.invalid"," TEA ","alpha@example.invalid"},
        {3,103,"duplicate@example.invalid",null,null},
        {4,104,null,null,null},
        {5,105,"absent@example.invalid",null,null},
        {6,106,"empty@example.invalid",null,null},
        {7,107,"alpha@example.invalid","   ",null},
        {8,108,"absent@example.invalid","TEH","previous@example.invalid"},
        {9,109,"single@example.invalid",null,null},
        {10,110,"duplicate@example.invalid","TMEA","duplicate@example.invalid"}
    }),
    T = fnISIRReporterOrgMatch(Incidents, Employees),
    Row = (id as number) as record => Table.SelectRows(T, each [ID] = id){0},
    BadIDs = try Table.RowCount(fnISIRReporterOrgMatch(Table.Combine({Incidents, Table.FirstN(Incidents,1)}), Employees)),
    NoSnapshotColumns = fnISIRReporterOrgMatch(Table.SelectColumns(Table.FirstN(Incidents,1), {"ID","SourceItemID","ReporterEmail"}), Employees),
    Checks = {
        {"Case and surrounding whitespace normalize", Row(1)[ProposedReporterSubsidiary] = "TEL"},
        {"Existing nonblank snapshot preserved exactly", Row(2)[ReporterSubsidiarySnapshot] = " TEA " and Row(2)[ProposedReporterSubsidiary] = null},
        {"Directory move flagged without overwrite", Row(2)[CurrentDirectoryDiffers] and Row(2)[Action] = "Keep existing snapshot"},
        {"Duplicate employee email blocks new assignment", Row(3)[MatchStatus] = "Duplicate employee email" and Row(3)[ProposedReporterSubsidiary] = null},
        {"Blank emails never match", Row(4)[MatchStatus] = "Missing reporter email" and Row(4)[ProposedReporterSubsidiary] = null},
        {"Unmatched email stays blank", Row(5)[MatchStatus] = "No employee match" and Row(5)[ProposedReporterSubsidiary] = null},
        {"Missing and single-token display names blocked", Row(6)[ProposedReporterSubsidiary] = null and Row(9)[ProposedReporterSubsidiary] = null},
        {"Whitespace-only snapshot is eligible", Row(7)[ProposedReporterSubsidiary] = "TEL"},
        {"Historical snapshot retained when employee absent", Row(8)[ReporterSubsidiarySnapshot] = "TEH" and Row(8)[Action] = "Keep existing snapshot" and Row(8)[ReporterEmailChangedSinceCapture]},
        {"Existing snapshot survives duplicate lookup", Row(10)[ReporterSubsidiarySnapshot] = "TMEA" and Row(10)[ProposedReporterSubsidiary] = null},
        {"No row multiplication; bad incident keys rejected", Table.RowCount(T) = Table.RowCount(Incidents) and BadIDs[HasError]},
        {"Preview runs before optional source columns exist", NoSnapshotColumns{0}[ProposedReporterSubsidiary] = "TEL"}
    },
    Base = #table(type table [Check = text, Passed = logical], Checks),
    Output = Table.AddColumn(Base, "Result", each if [Passed] then "PASS" else "FAIL", type text)
in
    Output
