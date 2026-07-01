pageextension 60007 "Item List Ext." extends "Item List"
{
    layout
    {
        addlast(Control1)
        {
            field("FA Conversion Count"; Rec."FA Conversion Count")
            {
                ApplicationArea = All;
                Style = Strong;
                ToolTip = 'Specifies the total number of Fixed Asset conversions created from this item.';
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
                ToolTip = 'Create a new Fixed Asset conversion from the selected item.';

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
