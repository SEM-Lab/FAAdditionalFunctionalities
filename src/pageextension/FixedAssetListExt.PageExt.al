pageextension 60006 "Fixed Asset List Ext." extends "Fixed Asset List"
{
    layout
    {
        movefirst(Control1; "No.")
        addlast(Control1)
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
            field("Source Item No."; Rec."Source Item No.")
            {
                ApplicationArea = All;
            }
            field("Source Variant Code"; Rec."Source Variant Code")
            {
                ApplicationArea = All;
            }
            field("Source Item Description"; Rec."Source Item Description")
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
                var
                    FixedAsset: Record "Fixed Asset";
                begin
                    CurrPage.SetSelectionFilter(FixedAsset);
                    if FixedAsset.FindSet() then
                        repeat
                            FATransferFunctions.NewItemForTransfer(FixedAsset);
                        until FixedAsset.Next() = 0;
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
                var
                    FixedAsset: Record "Fixed Asset";
                begin
                    CurrPage.SetSelectionFilter(FixedAsset);
                    if FixedAsset.FindSet() then
                        repeat
                            FATransferFunctions.CreateResourceCard(FixedAsset);
                        until FixedAsset.Next() = 0;
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
            action(CreateBulkTransferOrder)
            {
                ApplicationArea = All;
                Caption = 'Create Bulk Transfer Order';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = TransferOrder;
                ToolTip = 'Creates a transfer order for selected fixed assets with automatic serial number tracking.';

                trigger OnAction()
                var
                    FixedAsset: Record "Fixed Asset";
                    TransferToLocation: Record Location;
                    LocationList: Page "Location List";
                    TransferToCode: Code[10];
                begin
                    // Get selected Fixed Assets
                    CurrPage.SetSelectionFilter(FixedAsset);

                    if not FixedAsset.FindSet() then
                        Error('Please select at least one Fixed Asset.');

                    // Validate selection and get Transfer-from location
                    FATransferFunctions.ValidateBulkTransferSelection(FixedAsset);

                    // Prompt for Transfer-to Location
                    LocationList.LookupMode(true);
                    if LocationList.RunModal() = Action::LookupOK then begin
                        LocationList.GetRecord(TransferToLocation);
                        TransferToCode := TransferToLocation.Code;

                        // Reset record set for CreateBulkTransferOrder
                        CurrPage.SetSelectionFilter(FixedAsset);

                        // Create bulk transfer order
                        FATransferFunctions.CreateBulkTransferOrder(FixedAsset, TransferToCode);
                    end;
                end;
            }

        }
    }
    var
        FATransferFunctions: Codeunit "FA Transfer Functions";
}
