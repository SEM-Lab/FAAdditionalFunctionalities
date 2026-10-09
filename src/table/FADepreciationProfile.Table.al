namespace Infotek.FAAdditionalFunctionalities;

/// <summary>
/// Depreciation profile that an item can reference to set the depreciation life of the fixed assets
/// created from it when the item has no FA life years.
/// </summary>
table 60002 "FA Depreciation Profile"
{
    Caption = 'FA Depreciation Profile';
    DataClassification = CustomerContent;
    DrillDownPageId = "FA Depreciation Profiles";
    LookupPageId = "FA Depreciation Profiles";

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            ToolTip = 'Specifies the code that uniquely identifies the depreciation profile.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the depreciation profile.';
        }
        field(3; "Depreciation Life Formula"; DateFormula)
        {
            Caption = 'Depreciation Life Formula';
            ToolTip = 'Specifies the depreciation life that is applied to fixed assets created from items linked to this profile.';
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
