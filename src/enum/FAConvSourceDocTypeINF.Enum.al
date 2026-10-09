namespace Infotek.FAAdditionalFunctionalities;

/// <summary>
/// Kind of posted transfer document that an FA Conversion was created from. The blank value is used by
/// conversions that have no source document: the card flows and the conversions created before the source
/// document was recorded.
/// </summary>
enum 60011 "FA Conv. Source Doc. Type INF"
{
    Access = Public;
    Extensible = false;
    Caption = 'FA Conversion Source Document Type';

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; "Transfer Receipt")
    {
        Caption = 'Transfer Receipt';
    }
    value(2; "Direct Transfer")
    {
        Caption = 'Direct Transfer';
    }
}
