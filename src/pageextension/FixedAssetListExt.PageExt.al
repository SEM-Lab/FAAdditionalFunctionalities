pageextension 60006 "Fixed Asset List Ext." extends "Fixed Asset List"
{
    layout
    {
        addlast(Control1)
        {
            field("Current Location"; Rec."Current Location")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Current Location field.';
            }
            field("Current Location Name"; Rec."Current Location Name")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Current Location Name field.';
            }
            field("Current Location Ship-to Code"; Rec."Current Location Ship-to Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Current Location Ship-to Code field.';
            }
            field("Source Item No."; Rec."Source Item No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Source Item No. field.';
            }
            field("Source Variant Code"; Rec."Source Variant Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Source Variant Code field.';
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

        }
    }
    var
        FATransferFunctions: Codeunit "FA Transfer Functions";
}
