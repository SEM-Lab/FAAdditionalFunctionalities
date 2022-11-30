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

                group(FAAcquistion)
                {
                    Caption = 'FA Acquistion';

                    field("Depreciation Book Code"; Rec."Depreciation Book Code")
                    {
                        ToolTip = 'Specifies the value of the Depreciation Book Code field.';
                    }
                    field("Gen. Journal Template Name"; Rec."Gen. Journal Template Name")
                    {
                        ToolTip = 'Specifies the value of the Gen. Journal Template Name field.';
                    }
                    field("Gen. Journal Batch Name"; Rec."Gen. Journal Batch Name")
                    {
                        ToolTip = 'Specifies the value of the Gen. Journal Batch Name field.';
                    }
                    field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                    {
                        ToolTip = 'Specifies the value of the VAT Bus. Posting Group field.';
                    }
                    field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                    {
                        ToolTip = 'Specifies the value of the VAT Prod. Posting Group field.';
                    }
                }
                group(NegativeAdjusment)
                {
                    Caption = 'Negative Adjustment';

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
            group(FATransfer)
            {
                Caption = 'FA Transfer Setup';

                field("FA Transfer Item No."; Rec."FA Transfer Item No.")
                {
                    ToolTip = 'Specifies the value of the FA Transfer Item No. field.';
                }
                field("FA Trans. Pos. Adjmt. Loc. "; Rec."FA Trans. Pos. Adjmt. Loc.")
                {
                    ToolTip = 'Specifies the value of the FA Trans. Pos. Adjmt. Loc. field.';
                }
            }
            group(ResourceSetup)
            {
                Caption = 'Resource Setup';

                field("Resource Gen. Prod Post. Group"; Rec."Resource Gen. Prod Post. Group")
                {
                    ToolTip = 'Specifies the value of the Resource Gen. Prod. Posting Group field.';
                }
                field("Resource VAT Prod. Post. Group"; Rec."Resource VAT Prod. Post. Group")
                {
                    ToolTip = 'Specifies the value of the Resource VAT Prod. Posting Group field.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.InsertIfNotExists();
    end;

}
