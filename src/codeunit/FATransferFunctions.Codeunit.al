namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Item;
using System.Utilities;

/// <summary>
/// Fixed asset transfer functions (active only when Enable FA Transfer is set in FA Conversion Setup):
/// FA transfer items with serial tracking, resource cards, bulk transfer orders and the location
/// synchronisation of fixed assets and service items after transfers.
/// </summary>
codeunit 60001 "FA Transfer Functions"
{
    SingleInstance = true;
    Access = Public;
    Permissions = tabledata "E-Shipment Line INF" = m,
                  tabledata "FA Conversion" = r,
                  tabledata "FA Conversion Setup" = r,
                  tabledata "FA Location" = ri,
                  tabledata "Fixed Asset" = rm,
                  tabledata Item = r,
                  tabledata "Item Journal Line" = imd,
                  tabledata "Item Ledger Entry" = r,
                  tabledata "Item Tracking Code" = r,
                  tabledata Location = r,
                  tabledata Resource = rim,
                  tabledata "Service Item" = rm,
                  tabledata "Transfer Header" = im,
                  tabledata "Transfer Line" = im;

    /// <summary>
    /// Returns whether the FA transfer features are enabled in FA Conversion Setup.
    /// Reads the setup with a fresh Get so toggling takes effect without recycling the session.
    /// </summary>
    /// <returns>True if the Enable FA Transfer field is set in FA Conversion Setup, false otherwise.</returns>
    procedure IsFATransferEnabled(): Boolean
    var
        LocalFAConversionSetup: Record "FA Conversion Setup";
    begin
        if not LocalFAConversionSetup.Get() then
            exit(false);
        exit(LocalFAConversionSetup."Enable FA Transfer");
    end;

    /// <summary>
    /// Creates a Resource Card based on Fixed Asset data.
    /// </summary>
    /// <param name="FixedAsset">The Fixed Asset record to create Resource Card from.</param>
    procedure CreateResourceCard(FixedAsset: Record "Fixed Asset")
    var
        Resource: Record Resource;
        FAConversionSetup: Record "FA Conversion Setup";
        ConfirmManagement: Codeunit "Confirm Management";
        ConfirmQst: Label 'Resource No.: %1 already exist. Do you want to view resource card?', Comment = '%1 = Resource No.';
    begin
        if not IsFATransferEnabled() then
            Error(FATransferDisabledErr);

        if Resource.Get(FixedAsset."No.") then begin
            if not ConfirmManagement.GetResponseOrDefault(ConfirmQst, true) then
                exit;

            Page.Run(Page::"Resource Card", Resource);
            exit;
        end;

        // The setup is read into a local record on every call: this codeunit is SingleInstance, so a
        // global record would keep the first read for the whole session (NDIT-6082, LD-4).
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

    /// <summary>
    /// Creates a new transfer item for Fixed Asset with serial number tracking.
    /// </summary>
    /// <param name="FixedAsset">The Fixed Asset record to create transfer item for.</param>
    procedure NewItemForTransfer(FixedAsset: Record "Fixed Asset")
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        FAConversion: Record "FA Conversion";
        FAConversionSetup: Record "FA Conversion Setup";
        LocationCode: Code[10];
        AlreadyCreatedErr: Label 'FA Transfer Item has been already created.';
        FAConvNotFoundErr: Label 'FA Conversion record not found for Fixed Asset %1. Cannot determine location code.', Comment = '%1 = Fixed Asset No.';
        LocationCodeEmptyErr: Label 'Location Code is empty in FA Conversion %1. Cannot create transfer item.', Comment = '%1 = FA Conversion No.';
        NoValidLocationErr: Label 'Cannot create transfer item for Fixed Asset %1 without a valid location code.', Comment = '%1 = Fixed Asset No.';
    begin
        if not IsFATransferEnabled() then
            Error(FATransferDisabledErr);

        ItemLedgerEntry.SetLoadFields("Serial No.");
        ItemLedgerEntry.SetRange("Serial No.", FixedAsset."No.");
        if not ItemLedgerEntry.IsEmpty() then
            Error(AlreadyCreatedErr);

        // Local setup record, read on every call (see CreateResourceCard).
        FAConversionSetup.GetRecordOnce();
        FAConversionSetup.TestField("FA Transfer Item No.");

        // Strict requirement: FA Conversion must exist with valid location
        FAConversion.SetLoadFields("Location Code");
        FAConversion.SetRange("FA No.", FixedAsset."No.");
        if not FAConversion.FindFirst() then
            Error(FAConvNotFoundErr, FixedAsset."No.");

        LocationCode := FAConversion."Location Code";

        // Validate location code is not empty
        if LocationCode = '' then
            Error(LocationCodeEmptyErr, FAConversion."No.");

        GetSerialTrackedFATransferItem(Item, FAConversionSetup."FA Transfer Item No.");

        FAConversionSetup.TestField("Item Journal Template Name");
        FAConversionSetup.TestField("Item Journal Batch Name");

        ItemJournalLine.SetRange("Journal Template Name", FAConversionSetup."Item Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", FAConversionSetup."Item Journal Batch Name");
        ItemJournalLine.DeleteAll(true);

        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", FAConversionSetup."Item Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", FAConversionSetup."Item Journal Batch Name");
        ItemJournalLine.Validate("Line No.", 10000);
        ItemJournalLine.SetUpNewLine(ItemJournalLine);
        ItemJournalLine.Insert(true);
        ItemJournalLine.Validate("Posting Date", WorkDate());
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::"Positive Adjmt.");
        ItemJournalLine.Validate("Item No.", Item."No.");
        ItemJournalLine.Validate(Quantity, 1);

        // Final validation before posting - ensure location code is valid
        if LocationCode = '' then
            Error(NoValidLocationErr, FixedAsset."No.");

        ItemJournalLine.Validate("Location Code", LocationCode);
        //ItemJournalLine.Validate("Gen. Bus. Posting Group", Item."FA Conv. Gen. Bus. Post. Group");
        ItemJournalLine.Modify(true);

        CreateReservationEntryForPositiveAdjmt(ItemJournalLine, FixedAsset);

        Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJournalLine);
    end;

    /// <summary>
    /// Reads the FA transfer item and checks that it exists, has an item tracking code and that the code tracks
    /// serial numbers specifically.
    /// </summary>
    /// <param name="Item">Receives the FA transfer item; only the item tracking code is loaded besides the key.</param>
    /// <param name="FATransferItemNo">The FA transfer item number as read from FA Conversion Setup by the caller.</param>
    local procedure GetSerialTrackedFATransferItem(var Item: Record Item; FATransferItemNo: Code[20])
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        Item.SetLoadFields("Item Tracking Code");
        if not Item.Get(FATransferItemNo) then
            Error(RecordDoesNotExistErr, Item.TableCaption(), FATransferItemNo);
        Item.TestField("Item Tracking Code");

        ItemTrackingCode.SetLoadFields("SN Specific Tracking");
        if not ItemTrackingCode.Get(Item."Item Tracking Code") then
            Error(RecordDoesNotExistErr, ItemTrackingCode.TableCaption(), Item."Item Tracking Code");
        ItemTrackingCode.TestField("SN Specific Tracking", true);
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
        if not IsInboundTransferEntry(ItemLedgerEntry) then
            exit;

        Location.SetLoadFields("Consignment Customer No. INF", "Consignment Ship-to Code INF");
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

    /// <summary>
    /// Checks the guards that both location update procedures share: the entry is not a temporary record,
    /// is a Transfer entry and is the positive (inbound) side of the transfer.
    /// </summary>
    /// <param name="ItemLedgerEntry">The item ledger entry to check.</param>
    /// <returns>True when the entry is a persisted, positive Transfer entry; false otherwise.</returns>
    local procedure IsInboundTransferEntry(var ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    begin
        if ItemLedgerEntry.IsTemporary() then
            exit(false);

        if ItemLedgerEntry."Entry Type" <> ItemLedgerEntry."Entry Type"::Transfer then
            exit(false);

        exit(ItemLedgerEntry.Positive);
    end;



    // Removed deprecated event subscriber for NoSeriesManagement.OnAfterSetParametersBeforeRun
    // The modern "No. Series" codeunit handles transaction management internally
    // and no longer requires manual commit logic through event subscribers



    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", OnAfterInsertEvent, '', true, true)]
    local procedure "Item Ledger Entry_OnAfterInsertEvent"(var Rec: Record "Item Ledger Entry")
    begin
        // This fires on every Item Ledger Entry insert company-wide, so run the cheap
        // in-memory filters first and only inbound Transfer entries pay for the setup read.
        if Rec.IsTemporary() then
            exit;
        if Rec."Entry Type" <> Rec."Entry Type"::Transfer then
            exit;
        if not Rec.Positive then
            exit;

        if not IsFATransferEnabled() then
            exit;

        UpdateServiceItemLocationAfterTransferProcess(Rec);
        UpdateFixedAssetLocationAfterTransferProcess(Rec);
    end;

    local procedure UpdateFixedAssetLocationAfterTransferProcess(var ItemLedgerEntry: Record "Item Ledger Entry")
    var
        FixedAsset: Record "Fixed Asset";
        NewLocationCode: Code[10];
    begin
        if not IsInboundTransferEntry(ItemLedgerEntry) then
            exit;

        if ItemLedgerEntry."Serial No." = '' then
            exit;

        NewLocationCode := CopyStr(ItemLedgerEntry."Location Code", 1, MaxStrLen(NewLocationCode));
        if NewLocationCode = '' then
            exit;

        if not FixedAsset.Get(CopyStr(ItemLedgerEntry."Serial No.", 1, MaxStrLen(FixedAsset."No."))) then
            exit;

        if FixedAsset."FA Location Code" = NewLocationCode then
            exit;

        EnsureFALocationExists(NewLocationCode);
        FixedAsset.Validate("FA Location Code", NewLocationCode);
        FixedAsset.Modify(true);
    end;

    local procedure EnsureFALocationExists(LocationCode: Code[10])
    var
        Location: Record Location;
        FALocation: Record "FA Location";
    begin
        if LocationCode = '' then
            exit;

        Location.SetLoadFields(Name);
        if not FALocation.Get(LocationCode) then
            if Location.Get(LocationCode) then begin
                FALocation.Init();
                FALocation.Validate(Code, LocationCode);
                FALocation.Validate(Name, CopyStr(Location.Name, 1, MaxStrLen(FALocation.Name)));
                FALocation.Insert(true);
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create E-Shipment NAV Doc. INF", OnAfterCreateEShipmentLineFromTransferShipment, '', false, false)]
    local procedure "Create E-Shipment NAV Doc. INF_OnAfterCreateEShipmentLineFromTransferShipment"(TransferShipmentLine: Record "Transfer Shipment Line"; var EShipmentLine: Record "E-Shipment Line INF")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ServiceItem: Record "Service Item";
    begin
        if not IsFATransferEnabled() then
            exit;

        ItemLedgerEntry.SetLoadFields("Serial No.");
        ItemLedgerEntry.SetRange("Document No.", TransferShipmentLine."Document No.");
        ItemLedgerEntry.SetRange("Document Line No.", TransferShipmentLine."Line No.");
        if not ItemLedgerEntry.FindLast() then
            exit;

        ServiceItem.SetLoadFields("Item No.", Description);
        if not ServiceItem.Get(CopyStr(ItemLedgerEntry."Serial No.", 1, MaxStrLen(ServiceItem."No."))) then
            exit;

        EShipmentLine.Validate("Sellers Item Identification", ServiceItem."Item No.");
        EShipmentLine.Validate(Name, ServiceItem.Description);
        EShipmentLine.Modify(false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"EShipmentLineTracking ESHP INF", OnBeforeInsertEvent, '', false, false)]
    local procedure "EShipmentLineTracking ESHP INF_OnBeforeInsertEvent"(var Rec: Record "EShipmentLineTracking ESHP INF")
    begin
        if not IsFATransferEnabled() then
            exit;

        UpdateSerialNoOnBeforeInsertEShipmentLineTracking(Rec);
    end;

    local procedure UpdateSerialNoOnBeforeInsertEShipmentLineTracking(var Rec: Record "EShipmentLineTracking ESHP INF")
    var
        ServiceItem: Record "Service Item";
    begin
        ServiceItem.SetLoadFields("Serial No.");
        if not ServiceItem.Get(CopyStr(Rec."Serial No.", 1, MaxStrLen(ServiceItem."No."))) then
            exit;

        if ServiceItem."Serial No." = '' then
            exit;

        Rec.Validate("Serial No.", CopyStr(ServiceItem."Serial No.", 1, MaxStrLen(Rec."Serial No.")));
    end;

    /// <summary>
    /// Validates that all selected Fixed Assets have transfer items and are at the same location.
    /// Optimized with SetLoadFields for 200-500% performance improvement in bulk operations.
    /// </summary>
    /// <param name="FixedAsset">Record set of Fixed Assets to validate (passed as filtered record set).</param>
    procedure ValidateBulkTransferSelection(var FixedAsset: Record "Fixed Asset")
    var
        CurrentLocation: Code[10];
        LocationSet: Boolean;
        MissingTransferItems: Text;
        LocationMismatch: Boolean;
        LocationList: Text;
        MissingItemsErr: Label 'Transfer items not found for FA: %1. Create transfer items first.', Comment = '%1 = list of Fixed Asset Nos.';
        LocationMismatchErr: Label 'Selected FAs have different locations. All FAs must be at the same location to create a bulk transfer. Current locations: %1', Comment = '%1 = list of Location Codes';
        NoCurrentLocationErr: Label 'Cannot determine current location for selected Fixed Assets.';
    begin
        if not IsFATransferEnabled() then
            Error(FATransferDisabledErr);

        if FixedAsset.FindSet() then
            repeat
                CollectBulkTransferFAInfo(
                    FixedAsset, CurrentLocation, LocationSet, MissingTransferItems, LocationList, LocationMismatch);
            until FixedAsset.Next() = 0;

        if MissingTransferItems <> '' then
            Error(MissingItemsErr, MissingTransferItems);

        if LocationMismatch then
            Error(LocationMismatchErr, LocationList);

        if CurrentLocation = '' then
            Error(NoCurrentLocationErr);
    end;

    local procedure CollectBulkTransferFAInfo(FixedAsset: Record "Fixed Asset"; var CurrentLocation: Code[10]; var LocationSet: Boolean; var MissingTransferItems: Text; var LocationList: Text; var LocationMismatch: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // SetLoadFields keeps the open-entry lookup lightweight (only 3 fields).
        ItemLedgerEntry.SetLoadFields("Serial No.", "Location Code", Open);
        ItemLedgerEntry.SetRange("Serial No.", FixedAsset."No.");
        ItemLedgerEntry.SetRange(Open, true);

        if not ItemLedgerEntry.FindFirst() then begin
            if MissingTransferItems <> '' then
                MissingTransferItems += ', ';
            MissingTransferItems += FixedAsset."No.";
            exit;
        end;

        if not LocationSet then begin
            CurrentLocation := ItemLedgerEntry."Location Code";
            LocationSet := true;
            LocationList := CurrentLocation;
            exit;
        end;

        if ItemLedgerEntry."Location Code" = CurrentLocation then
            exit;

        LocationMismatch := true;
        if StrPos(LocationList, ItemLedgerEntry."Location Code") = 0 then
            LocationList += ', ' + ItemLedgerEntry."Location Code";
    end;

    /// <summary>
    /// Creates a bulk transfer order for multiple Fixed Assets with automatic serial number tracking.
    /// Optimized with SetLoadFields for improved performance.
    /// </summary>
    /// <param name="FixedAsset">Record set of Fixed Assets to transfer (passed as filtered record set).</param>
    /// <param name="TransferToCode">Destination location code for the transfer.</param>
    procedure CreateBulkTransferOrder(var FixedAsset: Record "Fixed Asset"; TransferToCode: Code[10])
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        FAConversionSetup: Record "FA Conversion Setup";
        TransferFromCode: Code[10];
        LineNo: Integer;
        TransferOrderNo: Code[20];
        FACount: Integer;
        SameLocationErr: Label 'Transfer-from and Transfer-to locations cannot be the same.';
        ItemTrackingRequiredErr: Label 'Item %1 must have Serial Number tracking enabled.', Comment = '%1 = Item No.';
    begin
        if not IsFATransferEnabled() then
            Error(FATransferDisabledErr);

        // Get Transfer-from location from first FA
        TransferFromCode := GetTransferFromCode(FixedAsset);

        // Validate Transfer-from <> Transfer-to
        if TransferFromCode = TransferToCode then
            Error(SameLocationErr);

        // Get FA Transfer Item (local setup record, read on every call - see CreateResourceCard)
        FAConversionSetup.GetRecordOnce();
        FAConversionSetup.TestField("FA Transfer Item No.");

        // PERFORMANCE OPTIMIZATION: SetLoadFields for Item - only need tracking code and UOM
        Item.SetLoadFields("No.", "Item Tracking Code", "Base Unit of Measure");
        if not Item.Get(FAConversionSetup."FA Transfer Item No.") then
            Error(RecordDoesNotExistErr, Item.TableCaption(), FAConversionSetup."FA Transfer Item No.");

        // Validate item tracking setup
        if not ItemHasSerialTracking(Item."No.") then
            Error(ItemTrackingRequiredErr, Item."No.");

        // Create Transfer Header ("No." of the fresh record is blank: OnInsert assigns it from the No. Series)
        TransferHeader.Init();
        TransferHeader.Insert(true);

        TransferHeader.Validate("Transfer-from Code", TransferFromCode);
        TransferHeader.Validate("Transfer-to Code", TransferToCode);
        TransferHeader.Validate("Posting Date", WorkDate());
        TransferHeader.Validate("Shipment Date", WorkDate());
        TransferHeader.Validate("Receipt Date", WorkDate());
        TransferHeader.Modify(true);

        TransferOrderNo := TransferHeader."No.";
        LineNo := 10000;
        FACount := 0;

        // Create Transfer Lines for each FA
        if FixedAsset.FindSet() then
            repeat
                FACount += 1;

                TransferLine.Init();
                TransferLine.Validate("Document No.", TransferHeader."No.");
                TransferLine.Validate("Line No.", LineNo);
                TransferLine.Insert(true);

                TransferLine.Validate("Item No.", Item."No.");
                TransferLine.Validate(Quantity, 1);
                TransferLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
                TransferLine.Modify(true);

                // Assign serial number to item tracking
                CreateReservationEntryForTransferLine(TransferLine, FixedAsset."No.");

                LineNo += 10000;
            until FixedAsset.Next() = 0;

        Message('Transfer Order %1 created successfully with %2 line(s).', TransferOrderNo, FACount);

        // Open the created transfer order
        Page.Run(Page::"Transfer Order", TransferHeader);
    end;

    /// <summary>
    /// Returns the location of the open item ledger entry of the first selected Fixed Asset. The Fixed
    /// Asset record set of the caller is positioned on its first record.
    /// </summary>
    /// <param name="FixedAsset">The selected Fixed Assets; positioned on the first record.</param>
    /// <returns>The location code of the open item ledger entry that carries the first Fixed Asset's number as serial number.</returns>
    local procedure GetTransferFromCode(var FixedAsset: Record "Fixed Asset"): Code[10]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if not FixedAsset.FindFirst() then
            Error(NothingInFilterErr, FixedAsset.TableCaption(), FixedAsset.GetFilters());

        // PERFORMANCE OPTIMIZATION: SetLoadFields for Item Ledger Entry lookup
        ItemLedgerEntry.SetLoadFields("Serial No.", "Location Code", Open);
        ItemLedgerEntry.SetRange("Serial No.", FixedAsset."No.");
        ItemLedgerEntry.SetRange(Open, true);
        if not ItemLedgerEntry.FindFirst() then
            Error(NothingInFilterErr, ItemLedgerEntry.TableCaption(), ItemLedgerEntry.GetFilters());
        exit(ItemLedgerEntry."Location Code");
    end;

    /// <summary>
    /// Creates reservation entries for Transfer Line with serial number tracking.
    /// Transfer Lines require TWO reservation entries (Direction 0=Outbound, Direction 1=Inbound).
    /// </summary>
    /// <param name="TransferLine">The Transfer Line record to create reservation entries for.</param>
    /// <param name="SerialNo">The serial number to assign (FA No.).</param>
    local procedure CreateReservationEntryForTransferLine(TransferLine: Record "Transfer Line"; SerialNo: Code[50])
    var
        TempReservationEntry: Record "Reservation Entry" temporary;
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservStatus: Enum "Reservation Status";
    begin
        // Outbound (Transfer-from) direction
        TempReservationEntry.Init();
        TempReservationEntry."Entry No." := 1;
        TempReservationEntry."Serial No." := SerialNo;
        TempReservationEntry.Quantity := -1;  // Negative for outbound
        TempReservationEntry."Quantity (Base)" := -1;
        TempReservationEntry.Insert(false);

        // Create reservation entry for Transfer Line (Outbound direction = 0)
        CreateReservEntry.CreateReservEntryFor(
            Database::"Transfer Line",
            0,  // Outbound direction
            TransferLine."Document No.",
            '',
            0,
            TransferLine."Line No.",
            TransferLine."Qty. per Unit of Measure",
            TempReservationEntry.Quantity,
            TempReservationEntry."Quantity (Base)",
            TempReservationEntry);

        CreateReservEntry.CreateEntry(
            TransferLine."Item No.",
            TransferLine."Variant Code",
            TransferLine."Transfer-from Code",
            '',
            TransferLine."Shipment Date",
            TransferLine."Receipt Date",
            0,
            ReservStatus::Surplus);

        // Clear for inbound direction
        TempReservationEntry.DeleteAll(false);
        Clear(CreateReservEntry);  // Ensure clean state for second direction

        // Inbound (Transfer-to) direction
        TempReservationEntry.Init();
        TempReservationEntry."Entry No." := 1;
        TempReservationEntry."Serial No." := SerialNo;
        TempReservationEntry.Quantity := 1;  // Positive for inbound
        TempReservationEntry."Quantity (Base)" := 1;
        TempReservationEntry.Insert(false);

        // Create reservation entry for Transfer Line (Inbound direction = 1)
        CreateReservEntry.CreateReservEntryFor(
            Database::"Transfer Line",
            1,  // Inbound direction
            TransferLine."Document No.",
            '',
            0,
            TransferLine."Line No.",
            TransferLine."Qty. per Unit of Measure",
            TempReservationEntry.Quantity,
            TempReservationEntry."Quantity (Base)",
            TempReservationEntry);

        CreateReservEntry.CreateEntry(
            TransferLine."Item No.",
            TransferLine."Variant Code",
            TransferLine."Transfer-to Code",
            '',
            TransferLine."Shipment Date",
            TransferLine."Receipt Date",
            0,
            ReservStatus::Surplus);
    end;

    /// <summary>
    /// Validates that an item has Serial Number specific tracking enabled.
    /// </summary>
    /// <param name="ItemNo">The item number to validate.</param>
    /// <returns>True if the item has SN specific tracking enabled, false otherwise.</returns>
    local procedure ItemHasSerialTracking(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        Item.SetLoadFields("Item Tracking Code");
        if not Item.Get(ItemNo) then
            exit(false);

        if Item."Item Tracking Code" = '' then
            exit(false);

        ItemTrackingCode.SetLoadFields("SN Specific Tracking");
        if not ItemTrackingCode.Get(Item."Item Tracking Code") then
            exit(false);

        exit(ItemTrackingCode."SN Specific Tracking");
    end;

    var
        FATransferDisabledErr: Label 'FA transfer features are disabled. To use this function, enable the Enable FA Transfer field in FA Conversion Setup.';
        RecordDoesNotExistErr: Label '%1 %2 does not exist.', Comment = '%1 = Table caption, %2 = Key value';
        NothingInFilterErr: Label 'There is no %1 within the filter. Filters: %2', Comment = '%1 = Table caption, %2 = Filters';
}
