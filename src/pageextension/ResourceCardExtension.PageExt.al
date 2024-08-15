pageextension 60003 "Resource Card Extension" extends "Resource Card"
{
    layout
    {
        addlast(content)
        {
            group("FA Data")
            {
                Caption = 'FA Data';

                field("Fixed Asset No."; Rec."Fixed Asset No.")
                {
                    ApplicationArea = All;
                }
                field("FA Serial No."; Rec."FA Serial No.")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        FixedAsset: Record "Fixed Asset";
                    begin
                        FixedAsset.Get(Rec."No.");
                        Page.Run(Page::"Fixed Asset Card", FixedAsset);
                    end;
                }
                field("Current Location"; Rec."Current Location")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
