page 60001 "FA Conversion Setup"
{
    PageType = Card;
    SourceTable = "FA Conversion Setup";
    Caption = 'FA Conversion Setup';
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = Administration;
    ApplicationArea = All;


    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("FA Conversion No. Series"; Rec."FA Conversion No. Series")
                {
                    ToolTip = 'Specifies the value of the FA Conversion No. Series field.';
                }
                field("Depreciation Book Code"; Rec."Depreciation Book Code")
                {
                    ToolTip = 'Specifies the value of the Depreciation Book Code field.';
                }
                field("Item Journal Template Name"; Rec."Item Journal Template Name")
                {
                    ToolTip = 'Specifies the value of the Item Journal Template Name field.';
                }
                field("Item Journal Batch Name"; Rec."Item Journal Batch Name")
                {
                    ToolTip = 'Specifies the value of the Item Journal Batch Name field.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.InsertIfNotExists();
    end;

}
