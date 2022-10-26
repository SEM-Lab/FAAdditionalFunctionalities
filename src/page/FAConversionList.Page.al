page 60003 "FA Conversion List"
{
    ApplicationArea = All;
    Caption = 'FA Conversions';
    PageType = List;
    SourceTable = "FA Conversion";
    UsageCategory = Lists;
    CardPageId = "FA Conversion";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the value of the No. field.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ToolTip = 'Specifies the value of the Item No. field.';
                }
                field("Item Description"; Rec."Item Description")
                {
                    ToolTip = 'Specifies the value of the Item Description field.';
                }
                field("FA No."; Rec."FA No.")
                {
                    ToolTip = 'Specifies the value of the FA No. field.';
                }
                field("FA Description"; Rec."FA Description")
                {
                    ToolTip = 'Specifies the value of the FA Description field.';
                }
            }
        }
    }
}
