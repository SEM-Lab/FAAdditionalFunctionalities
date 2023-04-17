pageextension 60005 "Posted Direct Transfer Subform" extends "Posted Direct Transfer Subform"
{
    actions
    {
        addfirst("&Line")
        {
            action(CreateFixedAssetsForSelectedLines)
            {
                ApplicationArea = All;
                Caption = 'Create Fixed Assets For Selected Lines';
                ToolTip = 'Executes the Create Fixed Assets For Selected Lines action.';
                Image = FixedAssets;

                trigger OnAction()
                var
                    DirectTransLine: Record "Direct Trans. Line";
                    ItemVariant: Record "Item Variant";
                    i: Integer;
                begin
                    CurrPage.SetSelectionFilter(DirectTransLine);
                    DirectTransLine.FindSet();
                    repeat
                        i := 0;
                        repeat
                            ItemVariant.Get(Rec."Item No.", Rec."Variant Code");
                            FAConversionFunctions.CreateFAConversionFromItemVariant(ItemVariant, false, Rec."Transfer-to Code");
                            i += 1;
                        until i >= Rec.Quantity;
                    until DirectTransLine.Next() = 0;
                end;
            }
        }
    }
    var
        FAConversionFunctions: Codeunit "FA Conversion Functions";
}