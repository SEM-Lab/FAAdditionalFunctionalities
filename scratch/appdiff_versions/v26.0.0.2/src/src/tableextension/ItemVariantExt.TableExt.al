tableextension 60023 "Item Variant Ext." extends "Item Variant"
{
    fields
    {
        field(60000; "FA Conversion Count"; Integer)
        {
            Caption = 'FA Conversion Count';
            FieldClass = FlowField;
            CalcFormula = count("FA Conversion" where("Item No." = field("Item No."), "Variant Code" = field(Code)));
            Editable = false;
            ToolTip = 'Specifies how many Fixed Asset conversions have been created from this item variant.';
        }
    }
}