pageextension 60004 "Item Variants Ext." extends "Item Variants"
{
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
                    FAConversionFunctions.CreateFAConversionFromItemVariant(Rec);
                end;
            }
        }
    }
    var
        FAConversionFunctions: Codeunit "FA Conversion Functions";
}