namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Projects.Resources.Resource;

pageextension 60003 "Resource Card Extension" extends "Resource Card"
{
    layout
    {
        addlast(content)
        {
            group("FA Data")
            {
                Caption = 'FA Data';

                field("Fixed Asset No."; Rec."Fixed Asset No.")
                {
                    ApplicationArea = All;
                }
                field("FA Serial No."; Rec."FA Serial No.")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        FixedAsset: Record "Fixed Asset";
                    begin
                        if not FAPageFunctions.GetFixedAsset(Rec."Fixed Asset No.", FixedAsset) then
                            Error(RecordDoesNotExistErr, FixedAsset.TableCaption(), Rec."Fixed Asset No.");
                        Page.Run(Page::"Fixed Asset Card", FixedAsset);
                    end;
                }
                field("Current Location"; Rec."Current Location")
                {
                    ApplicationArea = All;
                    Visible = FATransferEnabled;
                }
            }
        }
    }
    var
        FATransferFunctions: Codeunit "FA Transfer Functions";
        FAPageFunctions: Codeunit "FA Page Functions";
        FATransferEnabled: Boolean;
        RecordDoesNotExistErr: Label '%1 %2 does not exist.', Comment = '%1 = Table caption, %2 = Key value';

    trigger OnOpenPage()
    begin
        FATransferEnabled := FATransferFunctions.IsFATransferEnabled();
    end;
}
