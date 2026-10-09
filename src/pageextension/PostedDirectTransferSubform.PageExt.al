namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.Inventory.Item;
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
                ToolTip = 'Executes the Create Fixed Assets For Selected Lines action.';
                Image = FixedAssets;

                trigger OnAction()
                var
                    DirectTransLine: Record "Direct Trans. Line";
                    ItemVariant: Record "Item Variant";
                    i: Integer;
                begin
                    CurrPage.SetSelectionFilter(DirectTransLine);
                    DirectTransLine.FindSet();
                    repeat
                        i := 0;
                        repeat
                            if not FAPageFunctions.GetItemVariant(Rec."Item No.", Rec."Variant Code", ItemVariant) then
                                Error(RecordWithTwoKeysDoesNotExistErr, ItemVariant.TableCaption(), Rec."Item No.", Rec."Variant Code");
                            FAConversionFunctions.CreateFAConversionFromItemVariant(ItemVariant, false, Rec."Transfer-to Code");
                            i += 1;
                        until i >= Rec.Quantity;
                    until DirectTransLine.Next() = 0;
                end;
            }
        }
    }
    var
        FAConversionFunctions: Codeunit "FA Conversion Functions";
        FAPageFunctions: Codeunit "FA Page Functions";
        RecordWithTwoKeysDoesNotExistErr: Label '%1 %2, %3 does not exist.', Comment = '%1 = Table caption, %2 = First key value, %3 = Second key value';
}