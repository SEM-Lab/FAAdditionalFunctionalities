namespace Infotek.FAAdditionalFunctionalities;

/// <summary>
/// How much of each selected posted transfer line is converted to fixed assets: every convertible unit of
/// the line, or a given quantity from each line. The enum has no ordinal 0 on purpose: there is no empty
/// choice, the request dialog starts with All.
/// </summary>
enum 60012 "FA Conv. Quantity Mode INF"
{
    Access = Public;
    Extensible = false;
    Caption = 'FA Conversion Quantity Mode';

    value(1; All)
    {
        Caption = 'All';
    }
    value(2; Quantity)
    {
        Caption = 'Quantity';
    }
}
