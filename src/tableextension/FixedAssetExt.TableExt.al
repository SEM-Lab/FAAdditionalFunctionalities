tableextension 60022 "Fixed Asset Ext." extends "Fixed Asset"
{
    fields
    {
        field(60000; "Current Location"; Code[20])
        {
            Caption = 'Current Location';
            FieldClass = FlowField;
            CalcFormula = lookup("Item Ledger Entry"."Location Code" where("Serial No." = field("No."), Open = const(true)));
            Editable = false;
        }
    }
}
