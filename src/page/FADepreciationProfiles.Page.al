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
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Depreciation Life Formula"; Rec."Depreciation Life Formula")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
