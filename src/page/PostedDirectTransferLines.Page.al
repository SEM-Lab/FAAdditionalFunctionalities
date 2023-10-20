page 60005 "Posted Direct Transfer Lines"
{
    ApplicationArea = All;
    Caption = 'Posted Direct Transfer Lines';
    PageType = List;
    SourceTable = "Direct Trans. Line";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Document No."; Rec."Document No.")
                {
                    ToolTip = 'Specifies the value of the Document No. field.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ToolTip = 'Specifies the value of the Line No. field.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ToolTip = 'Specifies the number of the item.';
                }
                field("FA No. Series"; Rec."FA No. Series")
                {
                    ToolTip = 'Specifies the value of the FA No. Series field.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ToolTip = 'Specifies how many units of the record are processed.';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                }
                field("Remaning Quantity"; Rec."Remaning Quantity")
                {
                    ToolTip = 'Specifies the value of the Remaning Quantity field.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ToolTip = 'Specifies the value of the Gen. Prod. Posting Group field.';
                }
                field("Inventory Posting Group"; Rec."Inventory Posting Group")
                {
                    ToolTip = 'Specifies the value of the Inventory Posting Group field.';
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ToolTip = 'Specifies the value of the Quantity (Base) field.';
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ToolTip = 'Specifies the value of the Qty. per Unit of Measure field.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Gross Weight"; Rec."Gross Weight")
                {
                    ToolTip = 'Specifies the value of the Gross Weight field.';
                }
                field("Net Weight"; Rec."Net Weight")
                {
                    ToolTip = 'Specifies the value of the Net Weight field.';
                }
                field("Unit Volume"; Rec."Unit Volume")
                {
                    ToolTip = 'Specifies the value of the Unit Volume field.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Units per Parcel"; Rec."Units per Parcel")
                {
                    ToolTip = 'Specifies the value of the Units per Parcel field.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ToolTip = 'Specifies the value of the Description 2 field.';
                }
                field("Transfer Order No."; Rec."Transfer Order No.")
                {
                    ToolTip = 'Specifies the value of the Transfer Order No. field.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ToolTip = 'Specifies the value of the Posting Date field.';
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ToolTip = 'Specifies the value of the Transfer-from Code field.';
                }
                field("Transfer-to Code"; Rec."Transfer-to Code")
                {
                    ToolTip = 'Specifies the value of the Transfer-to Code field.';
                }
                field("Item Shpt. Entry No."; Rec."Item Shpt. Entry No.")
                {
                    ToolTip = 'Specifies the value of the Item Shpt. Entry No. field.';
                }
                field("Item Rcpt. Entry No."; Rec."Item Rcpt. Entry No.")
                {
                    ToolTip = 'Specifies the value of the Item Rcpt. Entry No. field.';
                }
                field("Dimension Set ID"; Rec."Dimension Set ID")
                {
                    ToolTip = 'Specifies the value of the Dimension Set ID field.';
                }
                field("Item Category Code"; Rec."Item Category Code")
                {
                    ToolTip = 'Specifies the value of the Item Category Code field.';
                }
                field("Transfer-from Bin Code"; Rec."Transfer-from Bin Code")
                {
                    ToolTip = 'Specifies the code for the bin that the items are transferred from.';
                }
                field("Transfer-To Bin Code"; Rec."Transfer-To Bin Code")
                {
                    ToolTip = 'Specifies the value of the Transfer-To Bin Code field.';
                }
                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    ToolTip = 'Specifies the value of the SystemCreatedAt field.';
                }
                field(SystemCreatedBy; Rec.SystemCreatedBy)
                {
                    ToolTip = 'Specifies the value of the SystemCreatedBy field.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
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
                            ItemVariant.Get(DirectTransLine."Item No.", DirectTransLine."Variant Code");
                            FAConversionFunctions.CreateFAConversionFromItemVariant(ItemVariant, false, DirectTransLine."Transfer-to Code");
                            i += 1;
                        until i = DirectTransLine.Quantity;
                    until DirectTransLine.Next() = 0;
                end;
            }

        }
    }
    var
        FAConversionFunctions: Codeunit "FA Conversion Functions";
}