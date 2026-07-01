table 60002 "FA Depreciation Profile"
{
    Caption = 'FA Depreciation Profile';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Depreciation Life Formula"; DateFormula)
        {
            Caption = 'Depreciation Life Formula';
            ToolTip = 'Defines the depreciation life that will be applied to fixed assets created from items linked to this profile.';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
}
