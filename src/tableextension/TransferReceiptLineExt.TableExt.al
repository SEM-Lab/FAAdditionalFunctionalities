tableextension 60003 "Transfer Receipt Line Ext." extends "Transfer Receipt Line"
{
    fields
    {
        field(60000; "Remaning Quantity"; Decimal)
        {
            Caption = 'Remaning Quantity';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Item Ledger Entry"."Remaining Quantity" where("Item No." = field("Item No."), "Variant Code" = field("Variant Code"), "Location Code" = field("Transfer-to Code")));
            ToolTip = 'Specifies the value of the Remaning Quantity field.';
        }
        field(60001; "FA No. Series"; Code[20])
        {
            Caption = 'FA No. Series';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup(Item."FA No. Series" where("No." = field("Item No.")));
            AllowInCustomizations = Never;
        }
    }
}