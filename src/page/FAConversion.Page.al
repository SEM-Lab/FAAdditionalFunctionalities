namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

/// <summary>
/// Card of one FA Conversion, with the Negative Adjustment and FA Acquisition actions.
/// </summary>
page 60002 "FA Conversion"
{
    ApplicationArea = All;
    Caption = 'FA Conversion';
    PageType = Card;
    SourceTable = "FA Conversion";
    UsageCategory = None;
    Permissions = tabledata "FA Ledger Entry" = r,
                  tabledata "Fixed Asset" = r,
                  tabledata Item = r,
                  tabledata "Item Ledger Entry" = r;
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
                        if not FixedAsset.Get(Rec."FA No.") then
                            Error(RecordDoesNotExistErr, FixedAsset.TableCaption(), Rec."FA No.");
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
                        if not ItemLedgerEntry.Get(Rec."Negative Adjmt. ILE Entry No.") then
                            Error(RecordDoesNotExistErr, ItemLedgerEntry.TableCaption(), Rec."Negative Adjmt. ILE Entry No.");
                        Page.Run(Page::"Item Ledger Entries", ItemLedgerEntry);
                    end;
                }
            }
            group("FA Acquisition")
            {
                Caption = 'FA Acquisition';
                field("E-Book Description INF"; Rec."E-Book Description INF")
                {
                }
                // field("GIB Document Desc. INF"; Rec."GIB Document Desc. INF")
                // {
                // }
                // field("GIB Document Type INF"; Rec."GIB Document Type INF")
                // {
                // }


                field("FA Acquisition Entry No."; Rec."FA Acquisition Entry No.")
                {
                    trigger OnDrillDown()
                    var
                        FALedgerEntry: Record "FA Ledger Entry";
                    begin
                        if not FALedgerEntry.Get(Rec."FA Acquisition Entry No.") then
                            Error(RecordDoesNotExistErr, FALedgerEntry.TableCaption(), Rec."FA Acquisition Entry No.");
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

        if not Item.Get(Rec."Item No.") then
            Error(RecordDoesNotExistErr, Item.TableCaption(), Rec."Item No.");
        if Item."Item Tracking Code" <> '' then
            SerialNoEditable := true;
    end;

    var
        Item: Record Item;
        FAConversionFunctions: Codeunit "FA Conversion Functions";
        SerialNoEditable: Boolean;
        RecordDoesNotExistErr: Label '%1 %2 does not exist.', Comment = '%1 = Table caption, %2 = Key value';
}
