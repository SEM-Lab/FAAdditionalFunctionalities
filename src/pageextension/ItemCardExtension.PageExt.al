namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.Inventory.Item;

pageextension 60002 "Item Card Extension" extends "Item Card"
{
    layout
    {
        addlast(content)
        {
            group("FA Conversion")
            {
                Caption = 'FA Conversion';

                field("FA No. Series"; Rec."FA No. Series")
                {
                    ApplicationArea = All;
                }
                field("FA Conv. Gen. Bus. Post. Group"; Rec."FA Conv. Gen. Bus. Post. Group")
                {
                    ApplicationArea = All;
                }
                field("FA Posting Group"; Rec."FA Posting Group")
                {
                    ApplicationArea = All;
                }

                field("FA Subclass Code"; Rec."FA Subclass Code")
                {
                    ApplicationArea = All;
                }

                field("FA Depr. Profile Code INF"; Rec."FA Depr. Profile Code INF")
                {
                    ApplicationArea = All;
                }

                field("FA Life Years INF"; Rec."FA Life Years INF")
                {
                    ApplicationArea = All;
                }

                field("FA Conversion Count"; Rec."FA Conversion Count")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    ToolTip = 'Specifies the total number of Fixed Asset conversions created from this item.';
                }
            }
        }
    }
    actions
    {
        addfirst(Functions)
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
                    FAConversionFunctions.CreateFAConversionFromItemCard(Rec);
                end;
            }
        }
    }
    var
        FAConversionFunctions: Codeunit "FA Conversion Functions";
}
