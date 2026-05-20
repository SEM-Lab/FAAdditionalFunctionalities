namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.Inventory.Location;

tableextension 60004 "Location Extension" extends Location
{
    fields
    {
        field(60000; "Location Type INF"; Enum "Location Type INF")
        {
            Caption = 'Location Type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the location behaves like a warehouse or an apartment for FA conversion.';
        }
    }
}
