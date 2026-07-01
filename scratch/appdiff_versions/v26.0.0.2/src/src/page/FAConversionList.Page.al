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
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                }
                field("Item No."; Rec."Item No.")
                {
                }
                field("Item Description"; Rec."Item Description")
                {
                }
                field("FA No."; Rec."FA No.")
                {
                }
                field("FA Description"; Rec."FA Description")
                {
                }
            }
        }
    }
}
