// Query name: fnISIRTransform
// Input: one source row per incident. Output: exactly one row per input row.
// No web requests, AI calls, writebacks, row filters, deduplication, or date fallback.
(Input as table) as table =>
let
    Required = {
        "ID", "SourceItemID", "SubmittedDate", "IsirSnapshot",
        "Incident Category", "User at Fault", "LostItems",
        "LostCountPhone", "LostCountPC", "LostCountUSB", "LostOther"
    },
    Optional = {
        "Task Phase", "Approver Status Phase", "CaseState", "ConsistencyFlag",
        "ConsistencyStatus", "SourceModifiedAt", "LastSyncSucceededAt", "Modified"
    },
    Missing = List.Difference(Required, Table.ColumnNames(Input)),
    Checked = if List.Count(Missing) > 0 then
        error Error.Record("ISIR.Schema", "Required source columns are missing.", Missing)
        else Input,
    Selected = Table.SelectColumns(Checked, Required & Optional, MissingField.UseNull),
    TodayUTC = Date.From(DateTimeZone.FixedUtcNow()),

    CleanText = (x as any) as nullable text =>
        if x = null then null else
        let t = Text.Trim(Text.Replace(Text.From(x), Character.FromNumber(160), " "))
        in if t = "" then null else t,

    DigitsOnly = (t as text) as logical =>
        Text.Length(t) > 0 and Text.Select(t, {"0".."9"}) = t,

    Quantity = (x as any) as record =>
        let
            t = CleanText(x),
            n = if t = null then null else
                if Value.Is(x, type number) then x else
                if DigitsOnly(t) then (try Number.FromText(t, "en-US") otherwise null)
                else null,
            valid = if n = null then false else
                (try n >= 0 and n = Number.RoundDown(n) and Int64.From(n) = n otherwise false)
        in [Value = if valid then Int64.From(n) else null,
            Status = if t = null then "Missing" else if valid then "Valid" else "Invalid"],

    // Only year-first numeric dates are accepted. Ambiguous dates are not guessed.
    ParseDate = (raw as nullable text) as nullable date =>
        if raw = null then null else
        let
            p = List.Transform(Text.SplitAny(raw, "-/"), each Text.Trim(_)),
            shapeOK = if List.Count(p) <> 3 then false else
                Text.Length(p{0}) = 4 and
                Text.Length(p{1}) <= 2 and Text.Length(p{2}) <= 2 and
                List.AllTrue(List.Transform(p, each DigitsOnly(_))),
            result = if not shapeOK then null else
                (try #date(Number.FromText(p{0}), Number.FromText(p{1}), Number.FromText(p{2}))
                 otherwise null)
        in result,

    // Match complete labels at the START of a line, not words in the narrative.
    FieldValues = (lines as list, label as text) as list =>
        List.Transform(
            List.Select(lines, each Text.StartsWith(_, label & ":", Comparer.OrdinalIgnoreCase)),
            each CleanText(Text.Range(_, Text.Length(label) + 1))
        ),
    SingleValue = (values as list) as nullable text =>
        if List.Count(values) = 1 then values{0} else null,

    ParseOther = (raw as nullable text) as record =>
        let
            parts = if raw = null then {} else
                List.Select(List.Transform(Text.SplitAny(raw, ";#(cr)#(lf)"), each Text.Trim(_)), each _ <> ""),
            parsed = List.Transform(parts, (part) =>
                let
                    kv = Text.Split(part, ":"),
                    label = if List.Count(kv) <> 2 then "" else
                        Text.Lower(Text.Remove(Text.Trim(kv{0}), {" ", "#(tab)", "/", "-", "_"})),
                    kind = if label = "usb" then "USB" else
                        if label = "accesskeysbadges" then "Badge" else
                        if label = "documentsdrawings" then "Document" else null,
                    q = Quantity(if List.Count(kv) = 2 then kv{1} else null)
                in [Kind = kind, Value = q[Value],
                    Valid = kind <> null and q[Status] = "Valid"]
            ),
            Get = (kind as text) as record =>
                let m = List.Select(parsed, each [Kind] = kind)
                in [Value = if List.Count(m) = 1 and m{0}[Valid] then m{0}[Value] else null,
                    Duplicate = List.Count(m) > 1],
            usb = Get("USB"), badge = Get("Badge"), doc = Get("Document"),
            bad = List.Count(List.Select(parsed, each not [Valid])),
            duplicates = usb[Duplicate] or badge[Duplicate] or doc[Duplicate],
            issue = if raw = null then false else List.Count(parts) = 0 or bad > 0 or duplicates
        in [USB = usb, Badge = badge, Document = doc,
            Status = if raw = null then "Missing" else if issue then "Needs review" else "Parsed",
            Issues = List.RemoveNulls({
                if raw <> null and List.Count(parts) = 0 then "Empty LostOther structure" else null,
                if bad > 0 then "Unrecognized LostOther label or invalid quantity" else null,
                if duplicates then "Repeated asset type in LostOther" else null
            })],

    Added = Table.AddColumn(Selected, "_Derived", (r as record) =>
        let
            snapshot = CleanText(r[IsirSnapshot]),
            lines = if snapshot = null then {} else List.Transform(Lines.FromText(snapshot), each Text.Trim(_)),
            dateValues = FieldValues(lines, "Incident Date"),
            dateRaw = SingleValue(dateValues),
            incidentDate = ParseDate(dateRaw),
            dateStatus = if List.Count(dateValues) = 0 then "Missing label" else
                if List.Count(dateValues) > 1 then "Multiple labels" else
                if dateRaw = null then "Blank value" else
                if incidentDate = null then "Invalid or unsupported format" else "Parsed",
            submitted = if r[SubmittedDate] = null then null else
                (try Date.From(r[SubmittedDate]) otherwise null),
            lag = if incidentDate = null or submitted = null then null else Duration.Days(submitted - incidentDate),
            futureDate = if incidentDate = null then false else incidentDate > TodayUTC,
            cityValues = FieldValues(lines, "City"),
            stateValues = FieldValues(lines, "State"),
            countryValues = FieldValues(lines, "Country"),
            workValues = FieldValues(lines, "Place of Work"),
            city = SingleValue(cityValues), state = SingleValue(stateValues),
            country = SingleValue(countryValues), work = SingleValue(workValues),
            duplicateGeo = List.AnyTrue(List.Transform({cityValues, stateValues, countryValues, workValues}, each List.Count(_) > 1)),
            locationStatus = if duplicateGeo then "Multiple labels" else
                if city <> null and country <> null then "City and country extracted" else "Incomplete",
            userText = CleanText(Record.Field(r, "User at Fault")),
            userTokens = if userText = null then {} else
                List.Select(Text.SplitAny(userText, " #(tab)#(cr)#(lf)"), each _ <> ""),
            subsidiary = if List.Count(userTokens) = 0 then null else Text.Upper(userTokens{0}),
            category = CleanText(Record.Field(r, "Incident Category")),
            phone = Quantity(r[LostCountPhone]), pc = Quantity(r[LostCountPC]), usb = Quantity(r[LostCountUSB]),
            other = ParseOther(CleanText(r[LostOther])),
            otherUSB = other[USB][Value],
            usbConflict = if usb[Value] = null or otherUSB = null then false else usb[Value] <> otherUSB,
            usbStatus = if usb[Status] = "Invalid" then "Invalid structured quantity" else
                if other[USB][Duplicate] then "Repeated USB in LostOther" else
                if usbConflict then "Conflict" else
                if usb[Value] <> null and otherUSB <> null then "Both agree; counted once" else
                if usb[Value] <> null then "Structured column" else
                if otherUSB <> null then "LostOther" else "Missing",
            usbResolved = if usb[Status] = "Invalid" or other[USB][Duplicate] or usbConflict then null else
                if usb[Value] <> null then usb[Value] else otherUSB,
            values = List.RemoveNulls({phone[Value], pc[Value], usbResolved, other[Badge][Value], other[Document][Value]}),
            knownCount = if List.Count(values) = 0 then null else List.Sum(values),
            lostItems = CleanText(r[LostItems]),
            tokens = if lostItems = null then {} else
                List.Select(List.Transform(Text.Split(lostItems, ","), each Text.Upper(Text.Trim(_))), each _ <> ""),
            unknownTokens = List.Difference(tokens, {"PC", "PHONE", "OTHER", "USB"}),
            selectedPC = List.Contains(tokens, "PC"), selectedPhone = List.Contains(tokens, "PHONE"),
            selectedOther = List.Contains(tokens, "OTHER"), selectedUSB = List.Contains(tokens, "USB"),
            otherValues = List.RemoveNulls({otherUSB, other[Badge][Value], other[Document][Value]}),
            otherKnown = if List.Count(otherValues) = 0 then null else List.Sum(otherValues),
            assetIssues = List.RemoveNulls({
                if phone[Status] = "Invalid" then "Invalid phone quantity" else null,
                if pc[Status] = "Invalid" then "Invalid PC quantity" else null,
                if usb[Status] = "Invalid" then "Invalid structured USB quantity" else null,
                if usbConflict then "USB quantities disagree" else null,
                if selectedPC and (pc[Value] = null or pc[Value] = 0) then "PC selected without a positive valid count" else null,
                if selectedPhone and (phone[Value] = null or phone[Value] = 0) then "Phone selected without a positive valid count" else null,
                if selectedUSB and (usbResolved = null or usbResolved = 0) then "USB selected without a positive valid count" else null,
                if selectedOther and (otherKnown = null or otherKnown = 0) then "Other selected without a positive parsed count" else null,
                if List.Count(unknownTokens) > 0 then "Unrecognized LostItems selection" else null,
                if pc[Value] <> null and pc[Value] > 0 and not selectedPC then "Positive PC count absent from LostItems" else null,
                if phone[Value] <> null and phone[Value] > 0 and not selectedPhone then "Positive phone count absent from LostItems" else null,
                if otherKnown <> null and otherKnown > 0 and not selectedOther and not selectedUSB then "Positive other count absent from LostItems" else null
            }) & other[Issues],
            hasAssetEvidence = List.Count(List.Intersect({tokens, {"PC", "PHONE", "OTHER", "USB"}})) > 0 or
                (knownCount <> null and knownCount > 0),
            qualityIssues = List.RemoveNulls({
                if r[ID] = null then "Missing SharePoint ID" else null,
                if category = null then "Missing curated category" else null,
                if subsidiary = null then "Missing subsidiary prefix" else null,
                if dateStatus <> "Parsed" then "Incident date: " & dateStatus else null,
                if futureDate then "Incident date is in the future (UTC date check)" else null,
                if r[SubmittedDate] <> null and submitted = null then "Invalid SubmittedDate" else null,
                if lag <> null and lag < 0 then "Incident date is after SubmittedDate; confirm meanings" else null,
                if duplicateGeo then "Repeated location label" else null
            }) & assetIssues
        in [
            IncidentCategory = category, SubsidiaryCandidate = subsidiary,
            SubmittedDateOnly = submitted, IncidentDateRaw = dateRaw,
            IncidentDate = incidentDate, IncidentDateStatus = dateStatus,
            DaysFromIncidentToSubmission = lag, IsFutureIncidentDate = futureDate,
            SnapshotCity = city, SnapshotState = state, SnapshotCountry = country,
            SnapshotPlaceOfWork = work, LocationExtractStatus = locationStatus,
            PhoneCount = phone[Value], PCCount = pc[Value], USBCount = usbResolved,
            BadgeCount = other[Badge][Value], DocumentCount = other[Document][Value],
            KnownLostAssetCount = knownCount, HasRecordedAssetLoss = hasAssetEvidence,
            PhoneCountStatus = phone[Status], PCCountStatus = pc[Status],
            USBCountStatus = usbStatus, LostOtherStatus = other[Status],
            AssetIssues = Text.Combine(List.Distinct(assetIssues), "; "),
            QualityIssues = Text.Combine(List.Distinct(qualityIssues), "; "),
            NeedsReview = List.Count(qualityIssues) > 0
        ], type record),
    DerivedNames = {
        "IncidentCategory", "SubsidiaryCandidate", "SubmittedDateOnly", "IncidentDateRaw",
        "IncidentDate", "IncidentDateStatus", "DaysFromIncidentToSubmission", "IsFutureIncidentDate",
        "SnapshotCity", "SnapshotState", "SnapshotCountry", "SnapshotPlaceOfWork", "LocationExtractStatus",
        "PhoneCount", "PCCount", "USBCount", "BadgeCount", "DocumentCount", "KnownLostAssetCount",
        "HasRecordedAssetLoss", "PhoneCountStatus", "PCCountStatus", "USBCountStatus", "LostOtherStatus",
        "AssetIssues", "QualityIssues", "NeedsReview"
    },
    Expanded = Table.ExpandRecordColumn(Added, "_Derived", DerivedNames, DerivedNames),
    DateNames = {"SubmittedDateOnly", "IncidentDate"},
    NumberNames = {"DaysFromIncidentToSubmission", "PhoneCount", "PCCount", "USBCount", "BadgeCount", "DocumentCount", "KnownLostAssetCount"},
    LogicalNames = {"IsFutureIncidentDate", "HasRecordedAssetLoss", "NeedsReview"},
    TextNames = List.Difference(DerivedNames, DateNames & NumberNames & LogicalNames),
    Typed = Table.TransformColumnTypes(Expanded,
        List.Transform(DateNames, each {_, type date}) &
        List.Transform(NumberNames, each {_, Int64.Type}) &
        List.Transform(LogicalNames, each {_, type logical}) &
        List.Transform(TextNames, each {_, type text}))
in
    Typed
