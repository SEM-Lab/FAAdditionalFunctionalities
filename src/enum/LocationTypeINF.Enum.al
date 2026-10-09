namespace Infotek.FAAdditionalFunctionalities;

/// <summary>
/// Role of a location for the FA conversion: a transfer receipt from a Warehouse location to an
/// Apartment location is converted to fixed assets automatically.
/// </summary>
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
