pageextension 60000 "Fixed Asset Card Ext." extends "Fixed Asset Card"
{
    layout
    {
        addafter("FA Location Code")
        {
            field("Current Location"; Rec."Current Location")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Current Location field.';
            }
        }
    }
}
