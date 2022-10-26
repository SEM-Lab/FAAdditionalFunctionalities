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
                    ToolTip = 'Specifies the value of the FA No. Series field.';
                }
                field("FA Conv. Gen. Bus. Post. Group"; Rec."FA Conv. Gen. Bus. Post. Group")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the FA Conversion Gen. Bus. Posting Group field.';
                }
                field("FA Posting Group"; Rec."FA Posting Group")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the FA Posting Group field.';
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
