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
            }
        }
    }
}
