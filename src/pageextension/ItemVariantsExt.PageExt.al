namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.Inventory.Item;

pageextension 60004 "Item Variants Ext." extends "Item Variants"
{
    layout
    {
        addlast(Control1)
        {
            field("FA Conversion Count"; Rec."FA Conversion Count")
            {
                ApplicationArea = All;
                Style = Strong;
                ToolTip = 'Specifies the total number of Fixed Asset conversions created from this item variant.';
            }
        }
    }

    actions
    {
        addfirst(Processing)
        {
            action(NewFAConversion)
            {
                ApplicationArea = All;
                Caption = 'New FA Conversion';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = FixedAssets;
                ToolTip = 'Executes the New FA Conversion action.';
                trigger OnAction()
                begin
                    FAConversionFunctions.CreateFAConversionFromItemVariant(Rec, true, '');
                end;
            }
        }
    }
    var
        FAConversionFunctions: Codeunit "FA Conversion Functions";
}