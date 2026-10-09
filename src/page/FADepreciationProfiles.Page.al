namespace Infotek.FAAdditionalFunctionalities;

/// <summary>
/// List of FA depreciation profiles that items can reference.
/// </summary>
page 60010 "FA Depreciation Profiles"
{
    Caption = 'FA Depreciation Profiles';
    PageType = List;
    ApplicationArea = All;
    SourceTable = "FA Depreciation Profile";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Code; Rec.Code)
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Depreciation Life Formula"; Rec."Depreciation Life Formula")
                {
                }
            }
        }
    }
}
