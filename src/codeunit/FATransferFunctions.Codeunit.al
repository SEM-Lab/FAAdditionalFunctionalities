codeunit 60001 "FA Transfer Functions"
{
    SingleInstance = true;
    Access = Public;
    procedure CreateResourceCard(FixedAsset: Record "Fixed Asset")
    var
        Resource: Record Resource;
        ConfirmQst: Label 'Resource No.: %1 already exist. Do you want to view resource card?', Comment = '%1 = Resource No.';
    begin
        if Resource.Get(FixedAsset."No.") then begin
            if not Confirm(ConfirmQst, true, Resource."No.") then
                exit;

            Page.Run(Page::"Resource Card", Resource);
            exit;
        end;

        FAConversionSetup.GetRecordOnce();
        FAConversionSetup.TestField("Resource Gen. Prod Post. Group");
        FAConversionSetup.TestField("Resource VAT Prod. Post. Group");

        Resource.Init();
        Resource.Insert(true);
        Resource.Validate("Fixed Asset No.", FixedAsset."No.");
        Resource.Validate(Name, FixedAsset.Description);
        Resource.Validate(Type, Resource.Type::Machine);
        Resource.Validate("Gen. Prod. Posting Group", FAConversionSetup."Resource Gen. Prod Post. Group");
        Resource.Validate("VAT Prod. Posting Group", FAConversionSetup."Resource VAT Prod. Post. Group");
        Resource.Modify(true);

        Page.Run(Page::"Resource Card", Resource);
    end;

    procedure NewItemForTransfer(FixedAsset: Record "Fixed Asset")
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        FAConversion: Record "FA Conversion";
        LocationCode: Code[10];
        AlreadyCreatedErr: Label 'FA Transfer Item has been already created.';
    begin
        ItemLedgerEntry.SetRange("Serial No.", FixedAsset."No.");
        if not ItemLedgerEntry.IsEmpty then
            Error(AlreadyCreatedErr);

        FAConversionSetup.GetRecordOnce();
        FAConversionSetup.TestField("FA Transfer Item No.");
        FAConversionSetup.TestField("FA Trans. Pos. Adjmt. Loc.");

        FAConversion.SetRange("FA No.", FixedAsset."No.");
        if FAConversion.FindFirst() then
            LocationCode := FAConversion."Location Code"
        else
            LocationCode := FAConversionSetup."FA Trans. Pos. Adjmt. Loc.";

        Item.Get(FAConversionSetup."FA Transfer Item No.");
        Item.TestField("Item Tracking Code");

        ItemTrackingCode.Get(Item."Item Tracking Code");
        ItemTrackingCode.TestField("SN Specific Tracking", true);

        FAConversionSetup.TestField("Item Journal Template Name");
        FAConversionSetup.TestField("Item Journal Batch Name");

        CommitRequired := true;

        ItemJournalLine.SetRange("Journal Template Name", FAConversionSetup."Item Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", FAConversionSetup."Item Journal Batch Name");
        ItemJournalLine.DeleteAll(true);

        ItemJournalLine.Init();
        ItemJournalLine."Journal Template Name" := FAConversionSetup."Item Journal Template Name";
        ItemJournalLine."Journal Batch Name" := FAConversionSetup."Item Journal Batch Name";
        ItemJournalLine."Line No." := 10000;
        ItemJournalLine.SetUpNewLine(ItemJournalLine);
        CommitRequired := false;
        ItemJournalLine.Insert(true);
        ItemJournalLine.Validate("Posting Date", WorkDate());
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::"Positive Adjmt.");
        ItemJournalLine.Validate("Item No.", Item."No.");
        ItemJournalLine.Validate(Quantity, 1);
        ItemJournalLine.Validate("Location Code", LocationCode);
        //ItemJournalLine.Validate("Gen. Bus. Posting Group", Item."FA Conv. Gen. Bus. Post. Group");
        ItemJournalLine.Modify(true);

        CreateReservationEntryForPositiveAdjmt(ItemJournalLine, FixedAsset);

        Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJournalLine);
    end;

    local procedure CreateReservationEntryForPositiveAdjmt(ItemJournalLine: Record "Item Journal Line"; FixedAsset: Record "Fixed Asset")
    var
        TempReservationEntry: Record "Reservation Entry" temporary;
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservStatus: Enum "Reservation Status";
    begin
        TempReservationEntry.Init();
        TempReservationEntry."Entry No." := 1;
        TempReservationEntry."Serial No." := FixedAsset."No.";
        TempReservationEntry.Quantity := 1;
        TempReservationEntry.Insert(false);

        CreateReservEntry.CreateReservEntryFor(
          Database::"Item Journal Line", ItemJournalLine."Entry Type".AsInteger(),
          ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", 0, ItemJournalLine."Line No.", ItemJournalLine."Qty. per Unit of Measure",
          TempReservationEntry.Quantity, TempReservationEntry.Quantity * ItemJournalLine."Qty. per Unit of Measure", TempReservationEntry);
        CreateReservEntry.CreateEntry(
          ItemJournalLine."Item No.", ItemJournalLine."Variant Code", ItemJournalLine."Location Code", '', 0D, 0D, 0, ReservStatus::Surplus);
    end;

    local procedure UpdateServiceItemLocationAfterTransferProcess(var ItemLedgerEntry: Record "Item Ledger Entry")
    var
        Location: Record Location;
        ServiceItem: Record "Service Item";
    begin
        if ItemLedgerEntry.IsTemporary then
            exit;

        if ItemLedgerEntry."Entry Type" <> ItemLedgerEntry."Entry Type"::Transfer then
            exit;

        if not ItemLedgerEntry.Positive then
            exit;

        if not Location.Get(ItemLedgerEntry."Location Code") then
            exit;

        if Location."Consignment Customer No. INF" = '' then
            exit;

        if not ServiceItem.Get(CopyStr(ItemLedgerEntry."Serial No.", 1, MaxStrLen(ServiceItem."No."))) then
            exit;

        ServiceItem.Validate("Customer No.", Location."Consignment Customer No. INF");

        if Location."Consignment Ship-to Code INF" <> '' then
            ServiceItem.Validate("Ship-to Code", Location."Consignment Ship-to Code INF");
        ServiceItem.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::NoSeriesManagement, OnAfterSetParametersBeforeRun, '', false, false)]
    local procedure OnAfterSetParametersBeforeRun(var TryNoSeriesCode: Code[20]; var TrySeriesDate: Date; var WarningNoSeriesCode: Code[20])
    begin
        if not CommitRequired then
            exit;

        Commit();
    end;



    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", OnAfterInsertEvent, '', true, true)]
    local procedure OnAfterInsert_ILE(var Rec: Record "Item Ledger Entry")
    begin
        UpdateServiceItemLocationAfterTransferProcess(Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create E-Shipment NAV Doc. INF", OnAfterCreateEShipmentLineFromTransferShipment, '', false, false)]
    local procedure "Create E-Shipment NAV Doc. INF_OnAfterCreateEShipmentLineFromTransferShipment"(TransferShipmentHeader: Record "Transfer Shipment Header"; TransferShipmentLine: Record "Transfer Shipment Line"; var EShipmentLine: Record "E-Shipment Line INF")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ServiceItem: Record "Service Item";
    begin
        ItemLedgerEntry.SetRange("Document No.", TransferShipmentLine."Document No.");
        ItemLedgerEntry.SetRange("Document Line No.", TransferShipmentLine."Line No.");
        if not ItemLedgerEntry.FindLast() then
            exit;

        if not ServiceItem.Get(ItemLedgerEntry."Serial No.") then
            exit;

        EShipmentLine.Validate("Sellers Item Identification", ServiceItem."Item No.");
        EShipmentLine.Validate(Name, ServiceItem.Description);
        EShipmentLine.Modify(false);
    end;

    var
        FAConversionSetup: Record "FA Conversion Setup";
        CommitRequired: Boolean;
}
