page 60002 "FA Conversion"
{
    ApplicationArea = All;
    Caption = 'FA Conversion';
    PageType = Card;
    SourceTable = "FA Conversion";
    UsageCategory = None;
    //Editable = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = false;

                field("No."; Rec."No.")
                {
                }
                field("Item No."; Rec."Item No.")
                {
                }
                field("Variant Code"; Rec."Variant Code")
                {
                }
                field("Item Description"; Rec."Item Description")
                {
                }
                field("FA No."; Rec."FA No.")
                {
                    trigger OnDrillDown()
                    var
                        FixedAsset: Record "Fixed Asset";
                    begin
                        FixedAsset.Get(Rec."FA No.");
                        Page.Run(Page::"Fixed Asset Card", FixedAsset);
                    end;
                }
                field("FA Description"; Rec."FA Description")
                {
                }
            }
            group("Negative Adjustment Information")
            {
                Caption = 'Negative Adjustment Information';

                field("Posting Date"; Rec."Posting Date")
                {
                }
                field("Location Code"; Rec."Location Code")
                {
                }
                field("Serial No."; Rec."Serial No.")
                {
                    Editable = SerialNoEditable;
                }
                field("Negative Adjmt. ILE Entry No."; Rec."Negative Adjmt. ILE Entry No.")
                {
                    trigger OnDrillDown()
                    var
                        ItemLedgerEntry: Record "Item Ledger Entry";
                    begin
                        ItemLedgerEntry.Get(Rec."Negative Adjmt. ILE Entry No.");
                        Page.Run(Page::"Item Ledger Entries", ItemLedgerEntry);
                    end;
                }
            }
            group("FA Acquisition")
            {
                Caption = 'FA Acquisition';
                field("FA Acquisition Entry No."; Rec."FA Acquisition Entry No.")
                {
                    trigger OnDrillDown()
                    var
                        FALedgerEntry: Record "FA Ledger Entry";
                    begin
                        FALedgerEntry.Get(Rec."FA Acquisition Entry No.");
                        Page.Run(Page::"FA Ledger Entries", FALedgerEntry);
                    end;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(NegativeAdjustment)
            {
                ApplicationArea = All;
                Caption = 'Negative Adjustment';
                ToolTip = 'Executes the Negative Adjustment action.';
                Image = NegativeLines;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    FAConversionFunctions.NegativeAdjustment(Rec, false);
                end;
            }
            action(FAAcquisition)
            {
                ApplicationArea = All;
                Caption = 'FA Acquisition';
                ToolTip = 'Executes the FA Acquisition action.';
                Image = FixedAssets;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    FAConversionFunctions.FAAcquisition(Rec);
                end;
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        SerialNoEditable := false;

        Item.Get(Rec."Item No.");
        if Item."Item Tracking Code" <> '' then
            SerialNoEditable := true;
    end;

    var
        Item: Record Item;
        FAConversionFunctions: Codeunit "FA Conversion Functions";
        SerialNoEditable: Boolean;
}
