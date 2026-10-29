// Query name: stg_ISIR_Parsed
// Keep Enable load OFF. Source is the existing connected staging query.
let
    Parsed = fnISIRTransform(stg_ISIR_Raw)
in
    Parsed
