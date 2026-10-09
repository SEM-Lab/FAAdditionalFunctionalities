namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.Inventory.Transfer;

pageextension 60005 "Posted Direct Transfer Subform" extends "Posted Direct Transfer Subform"
{
    actions
    {
        addfirst("&Line")
        {
            action(CreateFixedAssetsForSelectedLines)
            {
                ApplicationArea = All;
                Caption = 'Create Fixed Assets For Selected Lines';
                ToolTip = 'Opens a dialog to choose the acquisition date and the quantity, then creates fixed assets for the selected lines.';
                Image = FixedAssets;

                trigger OnAction()
                var
                    DirectTransLine: Record "Direct Trans. Line";
                begin
                    CurrPage.SetSelectionFilter(DirectTransLine);
                    FAConversionRequestMgt.RunForDirectTransferLines(DirectTransLine);
                    CurrPage.Update(false);
                end;
            }
        }
    }
    var
        FAConversionRequestMgt: Codeunit "FA Conversion Request Mgt. INF";
}