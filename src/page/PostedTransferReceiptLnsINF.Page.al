page 60004 "Posted Transfer ReceiptLns INF"
{
    Caption = 'Posted Transfer Receipt Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Transfer Receipt Line";
    UsageCategory = History;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Location;
                    HideValue = DocumentNoHideValue;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the document number associated with this transfer line.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the number of the item that you want to transfer.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the description of the item being transferred.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ToolTip = 'Specifies the value of the Transfer-from Code field.';
                }
                field("Transfer-to Code"; Rec."Transfer-to Code")
                {
                    ToolTip = 'Specifies the value of the Transfer-to Code field.';
                }
                field("Item Category Code"; Rec."Item Category Code")
                {
                    ToolTip = 'Specifies the value of the Item Category Code field.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the quantity of the item specified on the line.';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                }
                field("Remaning Quantity"; Rec."Remaning Quantity")
                {
                    ToolTip = 'Specifies the value of the Remaning Quantity field.';
                }
                field("Receipt Date"; Rec."Receipt Date")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the receipt date of the transfer receipt line.';
                }
            }
        }
        area(FactBoxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Show Document")
                {
                    ApplicationArea = Location;
                    Caption = 'Show Document';
                    Image = View;
                    ShortcutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    var
                        TransRcptHeader: Record "Transfer Receipt Header";
                    begin
                        TransRcptHeader.Get(Rec."Document No.");
                        Page.Run(Page::"Posted Transfer Receipt", TransRcptHeader);
                    end;
                }
                action(Dimensions)
                {
                    AccessByPermission = tabledata Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortcutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Show Document_Promoted"; "Show Document")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
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
                    TransferReceiptLine: Record "Transfer Receipt Line";
                    ItemVariant: Record "Item Variant";
                begin
                    CurrPage.SetSelectionFilter(TransferReceiptLine);
                    TransferReceiptLine.FindSet();
                    repeat
                        ItemVariant.Get(Rec."Item No.", Rec."Variant Code");
                        FAConversionFunctions.CreateFAConversionFromItemVariant(ItemVariant, false, Rec."Transfer-to Code");
                    until TransferReceiptLine.Next() = 0;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DocumentNoHideValue := false;
        DocumentNoOnFormat();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::LookupOK then
            LookupOKOnPush();
    end;

    var
        FromTransferReceiptLine: Record "Transfer Receipt Line";
        TempTransferReceiptLine: Record "Transfer Receipt Line" temporary;
        ItemChargeAssgntPurchItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
        FAConversionFunctions: Codeunit "FA Conversion Functions";
        UnitCost: Decimal;
        CreateCostDistrib: Boolean;
        DocumentNoHideValue: Boolean;

    procedure Initialize(NewItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; NewUnitCost: Decimal)
    begin
        ItemChargeAssgntPurchItemChargeAssignmentPurch := NewItemChargeAssignmentPurch;
        UnitCost := NewUnitCost;
        CreateCostDistrib := true;
    end;

    local procedure IsFirstLine(DocNo: Code[20]; LineNo: Integer): Boolean
    var
        TransferReceiptLine: Record "Transfer Receipt Line";
    begin
        TempTransferReceiptLine.Reset();
        TempTransferReceiptLine.CopyFilters(Rec);
        TempTransferReceiptLine.SetRange("Document No.", DocNo);
        if not TempTransferReceiptLine.FindFirst() then begin
            TransferReceiptLine.CopyFilters(Rec);
            TransferReceiptLine.SetRange("Document No.", DocNo);
            TransferReceiptLine.FindFirst();
            TempTransferReceiptLine := TransferReceiptLine;
            TempTransferReceiptLine.Insert();
        end;
        if TempTransferReceiptLine."Line No." = LineNo then
            exit(true);
    end;

    local procedure LookupOKOnPush()
    begin
        if CreateCostDistrib then begin
            FromTransferReceiptLine.Copy(Rec);
            CurrPage.SetSelectionFilter(FromTransferReceiptLine);
            if FromTransferReceiptLine.FindFirst() then begin
                ItemChargeAssgntPurchItemChargeAssignmentPurch."Unit Cost" := UnitCost;
                ItemChargeAssgntPurch.CreateTransferRcptChargeAssgnt(FromTransferReceiptLine, ItemChargeAssgntPurchItemChargeAssignmentPurch);
            end;
        end;
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstLine(Rec."Document No.", Rec."Line No.") then
            DocumentNoHideValue := true;
    end;

}

