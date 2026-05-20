namespace Infotek.FAAdditionalFunctionalities;

enum 60001 "Wizard Step"
{
    Extensible = true;

    value(0; "")
    {
    }
    value(1; Start)
    {
        Caption = 'Start';
    }
    value(2; Step2)
    {
        Caption = 'Step 2';
    }
    value(3; Finish)
    {
        Caption = 'Finish';
    }
}