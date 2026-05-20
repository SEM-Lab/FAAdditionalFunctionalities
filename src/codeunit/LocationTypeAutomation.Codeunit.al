namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using System.Utilities;

codeunit 60003 "Location Type Automation"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", OnAfterInsertTransRcptLine, '', false, false)]
    local procedure OnAfterInsertTransRcptLine(var TransRcptLine: Record "Transfer Receipt Line"; TransLine: Record "Transfer Line"; CommitIsSuppressed: Boolean; TransferReceiptHeader: Record "Transfer Receipt Header")
    var
        AutoConversionFailedErr: Label 'Automatic FA conversion failed for receipt %1 line %2. Details: %3', Comment = '%1 = Document No., %2 = Line No., %3 = Error Text';
    begin
        if TransRcptLine."Auto FA Conversion Done INF" then
            exit;

        if not ShouldAutoConvert(TransRcptLine) then
            exit;

        if not TryRunAutoConversion(TransRcptLine) then
            Error(AutoConversionFailedErr, TransRcptLine."Document No.", TransRcptLine."Line No.", GetLastErrorText());

        TransRcptLine."Auto FA Conversion Done INF" := true;
        TransRcptLine.Modify(false);
    end;

    local procedure ShouldAutoConvert(TransferReceiptLine: Record "Transfer Receipt Line"): Boolean
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
    begin
        if TransferReceiptLine."Item No." = '' then
            exit(false);

        if TransferReceiptLine.Quantity = 0 then
            exit(false);

        if not LocationHasType(FromLocation, TransferReceiptLine."Transfer-from Code", FromLocation."Location Type INF"::Warehouse) then
            exit(false);

        if not LocationHasType(ToLocation, TransferReceiptLine."Transfer-to Code", ToLocation."Location Type INF"::Apartment) then
            exit(false);

        exit(true);
    end;

    local procedure LocationHasType(var Location: Record Location; LocationCode: Code[10]; ExpectedType: Enum "Location Type INF"): Boolean
    begin
        if LocationCode = '' then
            exit(false);

        if not Location.Get(LocationCode) then
            exit(false);

        exit(Location."Location Type INF" = ExpectedType);
    end;

    [TryFunction]
    local procedure TryRunAutoConversion(var TransferReceiptLine: Record "Transfer Receipt Line")
    var
        FAConversionFunctions: Codeunit "FA Conversion Functions";
    begin
        FAConversionFunctions.CreateMultipleFAConversionsFromTransferReceiptLine(TransferReceiptLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnAfterValidateEvent, "Transfer-to Code", false, false)]
    local procedure TransferLineOnAfterValidateTransferToCode(var Rec: Record "Transfer Line"; var xRec: Record "Transfer Line"; CurrFieldNo: Integer)
    var
        Location: Record Location;
        ConfirmManagement: Codeunit "Confirm Management";
        PromptTxt: Label 'Location %1 does not have a Location Type. Do you want to set it to Apartment?', Comment = '%1 = Location Code';
    begin
        if Rec."Transfer-to Code" = '' then
            exit;

        if not Location.Get(Rec."Transfer-to Code") then
            exit;

        if Location."Location Type INF" <> Location."Location Type INF"::" " then
            exit;

        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(PromptTxt, Location.Code), true) then
            exit;

        Location.Validate("Location Type INF", Location."Location Type INF"::Apartment);
        Location.Modify(true);
    end;
}
