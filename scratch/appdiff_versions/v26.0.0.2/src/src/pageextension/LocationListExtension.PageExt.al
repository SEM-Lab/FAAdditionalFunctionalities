pageextension 60009 "Location List Extension" extends "Location List"
{
    layout
    {
        addlast(Control1)
        {
            field("Location Type INF"; Rec."Location Type INF")
            {
                ApplicationArea = All;
                ToolTip = 'Shows whether the location behaves as a warehouse or an apartment for FA conversions.';
            }
        }
    }
}
