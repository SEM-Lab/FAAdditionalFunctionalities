namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Inventory.Ledger;

pageextension 60000 "Fixed Asset Card Ext." extends "Fixed Asset Card"
{
    layout
    {
        // // Make FA Location Code uneditable to enforce automatic location mapping
        // modify("FA Location Code")
        // {
        //     Editable = false;
        // }

        addafter("FA Location Code")
        {
            field("Current Location"; Rec."Current Location")
            {
                ApplicationArea = All;
            }
            field("Current Location Name"; Rec."Current Location Name")
            {
                ApplicationArea = All;
            }
            field("Current Location Ship-to Code"; Rec."Current Location Ship-to Code")
            {
                ApplicationArea = All;
            }
            field("Current Location Type INF"; Rec."Current Location Type INF")
            {
                ApplicationArea = All;
            }
            field("Source Item No."; Rec."Source Item No.")
            {
                ApplicationArea = All;
            }
            field("Source Variant Code"; Rec."Source Variant Code")
            {
                ApplicationArea = All;
            }
        }
    }
    actions
    {
        addfirst(processing)
        {
            action(CreateFATransferItem)
            {
                ApplicationArea = All;
                Caption = 'Create FA Transfer Item';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = NewItem;
                ToolTip = 'Executes the Create FA Transfer Item action.';

                trigger OnAction()
                begin
                    FATransferFunctions.NewItemForTransfer(Rec);
                end;
            }
            action(CreateResourceCard)
            {
                ApplicationArea = All;
                Caption = 'Create Resource Card';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = NewResource;
                ToolTip = 'Executes the Create Resource Card action.';

                trigger OnAction()
                begin
                    FATransferFunctions.CreateResourceCard(Rec);
                end;
            }
            action(ShowItemLedgerEntries)
            {
                ApplicationArea = All;
                Caption = 'Item Ledger Entries';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = ItemLedger;
                ToolTip = 'View item ledger entries filtered by the selected fixed asset''s serial number.';

                trigger OnAction()
                var
                    ItemLedgerEntry: Record "Item Ledger Entry";
                begin
                    ItemLedgerEntry.SetRange("Serial No.", Rec."No.");
                    Page.Run(Page::"Item Ledger Entries", ItemLedgerEntry);
                end;
            }

        }
    }
    var
        FATransferFunctions: Codeunit "FA Transfer Functions";
}
