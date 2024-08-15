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
            ToolTip = 'Specifies the value of the Current Location field.';
        }
        field(60001; "Source Item No."; Code[20])
        {
            Caption = 'Source Item No.';
            TableRelation = Item."No.";
            ToolTip = 'Specifies the value of the Source Item No. field.';
        }
        field(60002; "Current Location Name"; Text[100])
        {
            Caption = 'Current Location Name';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup(Location.Name where(Code = field("Current Location")));
            ToolTip = 'Specifies the value of the Current Location Name field.';
        }
        field(60003; "Current Location Ship-to Code"; Code[20])
        {
            Caption = 'Current Location Ship-to Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup(Location."Consignment Ship-to Code INF" where(Code = field("Current Location")));
            ToolTip = 'Specifies the value of the Current Location Ship-to Code field.';
        }
        field(60004; "Source Variant Code"; Code[10])
        {
            Caption = 'Source Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Source Item No."));
            ToolTip = 'Specifies the value of the Source Variant Code field.';
        }
    }
}
