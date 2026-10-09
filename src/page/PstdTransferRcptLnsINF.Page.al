namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;

/// <summary>
/// List of posted transfer receipt lines with an action that converts the selected lines into fixed assets;
/// can also be used as the item charge assignment lookup (Initialize).
/// </summary>
page 60004 "Pstd Transfer RcptLns INF"
{
    Caption = 'Posted Transfer Receipt Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Transfer Receipt Line";
    UsageCategory = History;
    ApplicationArea = All;
    Permissions = tabledata Location = r,
                  tabledata "Transfer Receipt Header" = r;

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
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the number of the item that you want to transfer.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Location;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ToolTip = 'Specifies the value of the Transfer-from Code field.';
                }
                field("Transfer-to Code"; Rec."Transfer-to Code")
                {
                    ToolTip = 'Specifies the value of the Transfer-to Code field.';
                }
                field("FA Location Code"; Rec."Transfer-to Code")
                {
                    Caption = 'FA Location Code';
                    ToolTip = 'Specifies the location code that will be used for Fixed Asset conversion (same as Transfer-to Code).';
                }
                field("FA Location Name"; GetLocationName(Rec."Transfer-to Code"))
                {
                    Caption = 'FA Location Name';
                    ToolTip = 'Specifies the location name that will be used for Fixed Asset conversion.';
                    Editable = false;
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
                }
                field("Remaning Quantity"; Rec."Remaning Quantity")
                {
                }
                field("Receipt Date"; Rec."Receipt Date")
                {
                    ApplicationArea = Location;
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
                        if not TransRcptHeader.Get(Rec."Document No.") then
                            Error(RecordDoesNotExistErr, TransRcptHeader.TableCaption(), Rec."Document No.");
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
                begin
                    CurrPage.SetSelectionFilter(TransferReceiptLine);
                    if TransferReceiptLine.FindSet() then
                        repeat
                            FAConversionFunctions.CreateMultipleFAConversionsFromTransferReceiptLine(TransferReceiptLine);
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
        TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary;
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
        FAConversionFunctions: Codeunit "FA Conversion Functions";
        UnitCost: Decimal;
        CreateCostDistrib: Boolean;
        DocumentNoHideValue: Boolean;
        RecordDoesNotExistErr: Label '%1 %2 does not exist.', Comment = '%1 = Table caption, %2 = Key value';
        NothingInFilterErr: Label 'There is no %1 within the filter. Filters: %2', Comment = '%1 = Table caption, %2 = Filters';

    /// <summary>
    /// Prepares the page as the lookup for an item charge assignment: when the user confirms the lookup
    /// (LookupOK), item charge assignment lines are created for the selected transfer receipt lines.
    /// </summary>
    /// <param name="NewItemChargeAssignmentPurch">The item charge assignment line used as the template for the new assignment lines.</param>
    /// <param name="NewUnitCost">The unit cost to assign.</param>
    procedure Initialize(NewItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; NewUnitCost: Decimal)
    begin
        TempItemChargeAssignmentPurch := NewItemChargeAssignmentPurch;
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
            if not TransferReceiptLine.FindFirst() then
                Error(NothingInFilterErr, TransferReceiptLine.TableCaption(), TransferReceiptLine.GetFilters());
            TempTransferReceiptLine := TransferReceiptLine;
            TempTransferReceiptLine.Insert(false);
        end;
        if TempTransferReceiptLine."Line No." = LineNo then
            exit(true);
        exit(false);
    end;

    local procedure LookupOKOnPush()
    begin
        if CreateCostDistrib then begin
            FromTransferReceiptLine.Copy(Rec);
            CurrPage.SetSelectionFilter(FromTransferReceiptLine);
            if FromTransferReceiptLine.FindFirst() then begin
                // Template record only: CreateTransferRcptChargeAssgnt reads its field values and inserts
                // new lines through its own record variable, so the template is kept temporary and its
                // Unit Cost is set without running OnValidate (which would modify the purchase document's
                // assignment lines via SuggestAssgntFromLine) - as before.
                TempItemChargeAssignmentPurch."Unit Cost" := UnitCost;
                ItemChargeAssgntPurch.CreateTransferRcptChargeAssgnt(FromTransferReceiptLine, TempItemChargeAssignmentPurch);
            end;
        end;
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstLine(Rec."Document No.", Rec."Line No.") then
            DocumentNoHideValue := true;
    end;

    local procedure GetLocationName(LocationCode: Code[10]): Text[100]
    var
        Location: Record Location;
    begin
        if LocationCode = '' then
            exit('');

        Location.SetLoadFields(Name);
        if Location.Get(LocationCode) then
            exit(Location.Name);

        exit('');
    end;

}

