namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Transfer;

tableextension 60003 "Transfer Receipt Line Ext." extends "Transfer Receipt Line"
{
    fields
    {
        field(60000; "Remaning Quantity"; Decimal)
        {
            Caption = 'Remaning Quantity';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Item Ledger Entry"."Remaining Quantity" where("Item No." = field("Item No."), "Variant Code" = field("Variant Code"), "Location Code" = field("Transfer-to Code"), "Document No." = field("Document No."), "Document Line No." = field("Line No.")));
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
        field(60002; "Auto FA Conversion Done INF"; Boolean)
        {
            Caption = 'Auto FA Conversion Completed';
            Editable = false;
            AllowInCustomizations = Never;
            ToolTip = 'Specifies whether an automatic Fixed Asset conversion was triggered for this receipt line.';
        }
    }
}