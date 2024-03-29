tableextension 60002 "Resource Extension" extends Resource
{
    fields
    {
        field(60000; "Current Location"; Code[20])
        {
            Caption = 'Current Location';
            FieldClass = FlowField;
            CalcFormula = lookup("Item Ledger Entry"."Location Code" where("Serial No." = field("Fixed Asset No."), Open = const(true)));
            Editable = false;
        }
        field(60001; "FA Serial No."; Text[50])
        {
            Caption = 'FA Serial No.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Fixed Asset"."Serial No." where("No." = field("Fixed Asset No.")));
        }
        field(60002; "Fixed Asset No."; Code[20])
        {
            Caption = 'Fixed Asset No.';
            TableRelation = "Fixed Asset"."No.";
        }
    }
}
