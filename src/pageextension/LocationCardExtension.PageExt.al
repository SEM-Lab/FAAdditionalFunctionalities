namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.Inventory.Location;

pageextension 60008 "Location Card Extension" extends "Location Card"
{
    layout
    {
        addlast(General)
        {
            field("Location Type INF"; Rec."Location Type INF")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether the location acts as a warehouse or an apartment for FA conversions.';
            }
        }
    }
}
