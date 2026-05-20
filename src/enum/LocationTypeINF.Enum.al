namespace Infotek.FAAdditionalFunctionalities;

enum 60002 "Location Type INF"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; Warehouse)
    {
        Caption = 'Warehouse';
    }
    value(2; Apartment)
    {
        Caption = 'Apartment';
    }
}
