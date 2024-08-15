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
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("FA Conversion No. Series"; Rec."FA Conversion No. Series")
                {
                }

                group(FAAcquistion)
                {
                    Caption = 'FA Acquistion';

                    field("Depreciation Book Code"; Rec."Depreciation Book Code")
                    {
                    }
                    field("Gen. Journal Template Name"; Rec."Gen. Journal Template Name")
                    {
                    }
                    field("Gen. Journal Batch Name"; Rec."Gen. Journal Batch Name")
                    {
                    }
                    field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                    {
                    }
                    field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                    {
                    }
                }
                group(NegativeAdjusment)
                {
                    Caption = 'Negative Adjustment';

                    field("Item Journal Template Name"; Rec."Item Journal Template Name")
                    {
                    }
                    field("Item Journal Batch Name"; Rec."Item Journal Batch Name")
                    {
                    }
                }
            }
            group(FATransfer)
            {
                Caption = 'FA Transfer Setup';

                field("FA Transfer Item No."; Rec."FA Transfer Item No.")
                {
                }
                field("FA Trans. Pos. Adjmt. Loc. "; Rec."FA Trans. Pos. Adjmt. Loc.")
                {
                }
            }
            group(ResourceSetup)
            {
                Caption = 'Resource Setup';

                field("Resource Gen. Prod Post. Group"; Rec."Resource Gen. Prod Post. Group")
                {
                }
                field("Resource VAT Prod. Post. Group"; Rec."Resource VAT Prod. Post. Group")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.InsertIfNotExists();
    end;

}
