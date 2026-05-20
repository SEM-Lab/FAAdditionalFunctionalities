namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.Inventory.Journal;

pageextension 60001 "Item Journal Extension" extends "Item Journal"
{
    layout
    {
        modify("Gen. Bus. Posting Group")
        {
            Visible = true;
        }
    }
}
