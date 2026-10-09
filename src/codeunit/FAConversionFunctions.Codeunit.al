namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Service.Item;
using Microsoft.Service.Setup;

/// <summary>
/// Converts items, item variants and posted transfer receipt lines into fixed assets: creates the
/// FA Conversion and the Fixed Asset, posts the negative inventory adjustment and the FA acquisition.
/// </summary>
codeunit 60000 "FA Conversion Functions"
{
    SingleInstance = true;
    Access = Public;
    Permissions = tabledata "FA Conversion" = im,
                  tabledata "FA Conversion Setup" = r,
                  tabledata "FA Depreciation Book" = rim,
                  tabledata "FA Depreciation Profile" = r,
                  tabledata "FA Ledger Entry" = r,
                  tabledata "FA Location" = ri,
                  tabledata "Fixed Asset" = rim,
                  tabledata "Gen. Journal Line" = imd,
                  tabledata "General Ledger Setup" = r,
                  tabledata "General Posting Setup" = r,
                  tabledata Item = r,
                  tabledata "Item Journal Batch" = r,
                  tabledata "Item Journal Line" = imd,
                  tabledata "Item Ledger Entry" = r,
                  tabledata Location = r,
                  tabledata "Service Item" = im,
                  tabledata "Service Item Group" = r;

    /// <summary>
    /// Creates a Fixed Asset conversion from an Item Card.
    /// </summary>
    /// <param name="Item">The source item record to convert to Fixed Asset.</param>
    procedure CreateFAConversionFromItemCard(Item: Record Item)
    var
        FAConversion: Record "FA Conversion";
        Location: Record Location;
        DefaultLocationCode: Code[10];
        LocationNotFoundErr: Label 'Location %1 does not exist. Please create the location first or set a valid default location in FA Conversion Setup.', Comment = '%1 = Location Code';
        NoLocationsErr: Label 'No locations are defined in the system. Please create at least one location before proceeding.';
    begin
        Item.TestField("FA No. Series");
        Item.TestField("FA Conv. Gen. Bus. Post. Group");
        Item.TestField("FA Posting Group");
        Item.TestField("FA Subclass Code");
        Item.TestField("FA Life Years INF");

        // Get default location code from setup or item
        DefaultLocationCode := GetDefaultLocationCode();

        Location.SetLoadFields(Code);
        // Validate that the location exists
        if DefaultLocationCode <> '' then
            if not Location.Get(DefaultLocationCode) then
                Error(LocationNotFoundErr, DefaultLocationCode);

        // If no default location found, try to get the first available location
        if DefaultLocationCode = '' then
            if Location.FindFirst() then
                DefaultLocationCode := Location.Code
            else
                Error(NoLocationsErr);

        FAConversion.Init();
        FAConversion.Insert(true);
        FAConversion.Validate("Item No.", Item."No.");
        FAConversion.Validate("Item Description", Item.Description);
        FAConversion.Validate("Location Code", DefaultLocationCode);
        CreateFixedAsset(Item, FAConversion);
        FAConversion.Modify(true);

        Page.Run(Page::"FA Conversion", FAConversion);
    end;

    /// <summary>
    /// Creates a Fixed Asset conversion from an Item Variant.
    /// </summary>
    /// <param name="ItemVariant">The source item variant record to convert to Fixed Asset.</param>
    /// <param name="ShowPageAfterCreation">Whether to display the FA Conversion page after creation.</param>
    /// <param name="LocationCode">The location code to assign to the FA Conversion.</param>
    procedure CreateFAConversionFromItemVariant(ItemVariant: Record "Item Variant"; ShowPageAfterCreation: Boolean; LocationCode: Code[10])
    var
        FAConversion: Record "FA Conversion";
        Item: Record Item;
    begin
        if not Item.Get(ItemVariant."Item No.") then
            Error(RecordDoesNotExistErr, Item.TableCaption(), ItemVariant."Item No.");

        Item.TestField("FA No. Series");
        Item.TestField("FA Conv. Gen. Bus. Post. Group");
        Item.TestField("FA Posting Group");
        Item.TestField("FA Life Years INF");

        FAConversion.Init();
        FAConversion.Insert(true);
        FAConversion.Validate("Item No.", Item."No.");
        FAConversion.Validate("Variant Code", ItemVariant.Code);
        FAConversion.Validate("Item Description", ItemVariant.Description);
        CreateFixedAsset(Item, FAConversion);
        FAConversion.Modify(true);

        if ShowPageAfterCreation then
            Page.Run(Page::"FA Conversion", FAConversion)
        else begin
            FAConversion.Validate("Location Code", LocationCode);
            FAConversion.Modify(true);
            NegativeAdjustment(FAConversion, true);
            FAAcquisition(FAConversion);
        end;
    end;

    local procedure CreateFixedAsset(Item: Record Item; var FAConversion: Record "FA Conversion")
    var
        FixedAsset: Record "Fixed Asset";
        TempFixedAsset: Record "Fixed Asset" temporary;
        FADepreciationBook: Record "FA Depreciation Book";
        FAConversionSetup: Record "FA Conversion Setup";
        NoSeries: Codeunit "No. Series";
    begin
        // The setup is read into a local record on every call: this codeunit is SingleInstance, so a
        // global record would keep the first read for the whole session (NDIT-6082, LD-4).
        FAConversionSetup.GetRecordOnce();
        FAConversionSetup.TestField("Depreciation Book Code");

        // The number comes from the item's FA No. Series, not from FA Setup. The key is built in a
        // temporary buffer so that "No." OnValidate (TestManual on the FA Setup series, clearing
        // "No. Series") does not run - exactly as the former direct assignment.
        TempFixedAsset.Init();
        TempFixedAsset."No. Series" := Item."FA No. Series";
        TempFixedAsset."No." := NoSeries.GetNextNo(Item."FA No. Series", WorkDate());
        FixedAsset := TempFixedAsset;
        FixedAsset.Insert(true);
        FixedAsset.Validate(Description, FAConversion."Item Description");
        FixedAsset.Validate("Serial No.", FAConversion."Serial No.");
        FixedAsset.Validate("FA Subclass Code", Item."FA Subclass Code");

        // Ensure FA Location exists before validation
        EnsureFALocationExists(FAConversion."Location Code");
        FixedAsset.Validate("FA Location Code", FAConversion."Location Code");

        FixedAsset.Modify(true);

        FADepreciationBook.Init();
        FADepreciationBook.Validate("FA No.", FixedAsset."No.");
        FADepreciationBook.Validate("Depreciation Book Code", FAConversionSetup."Depreciation Book Code");
        FADepreciationBook.Validate("FA Posting Group", Item."FA Posting Group");
        FADepreciationBook.Insert(true);
        ApplyDepreciationProfile(Item, FAConversion, FADepreciationBook);

        FAConversion.Validate("FA No.", FixedAsset."No.");
        FAConversion.Validate("FA Description", FixedAsset.Description);
    end;

    /// <summary>
    /// Posts a negative inventory adjustment for the FA conversion item.
    /// </summary>
    /// <param name="FAConversion">The FA Conversion record to process.</param>
    /// <param name="SkipCosting">Whether to skip cost adjustment and posting to GL.</param>
    procedure NegativeAdjustment(var FAConversion: Record "FA Conversion"; SkipCosting: Boolean)
    var
        ErrorHandlingLbl: Label 'Failed to create negative adjustment: %1', Comment = '%1 = Error message';
    begin
        if not TryNegativeAdjustment(FAConversion, SkipCosting) then begin
            // A failure inside the costing leaves the conversion that was handed to the cost subscribers in the
            // SingleInstance global; it must not outlive the failed call (NDIT-6082, LD-7).
            Clear(GlobalFAConversion);
            Error(ErrorHandlingLbl, GetLastErrorText());
        end;
    end;

    /// <summary>
    /// Attempts to post a negative inventory adjustment for the FA conversion item.
    /// </summary>
    /// <param name="FAConversion">The FA Conversion record to process.</param>
    /// <param name="SkipCosting">Whether to skip cost adjustment and posting to GL.</param>
    /// <returns>True when the negative adjustment was posted; false when an error was caught (try method).</returns>
    [TryFunction]
    procedure TryNegativeAdjustment(var FAConversion: Record "FA Conversion"; SkipCosting: Boolean)
    begin
        PostNegativeAdjustment(FAConversion, SkipCosting, 0, 0);
    end;

    /// <summary>
    /// Posts the negative inventory adjustment of one unit of a conversion request, without cost adjustment, taken from the
    /// unit's own inbound item ledger entry: the item journal line carries the unit cost of that entry and, when an entry to
    /// apply to is given, is applied to it. With no entries it is the same as NegativeAdjustment without cost adjustment
    /// (application by the costing method, unit cost of the first open entry at the location).
    /// </summary>
    /// <param name="FAConversion">The FA Conversion of the unit.</param>
    /// <param name="AppliesToEntryNo">The open inbound item ledger entry the unit is applied to; 0 leaves the application to the costing method or, for a serial number, to its item tracking.</param>
    /// <param name="CostEntryNo">The inbound item ledger entry the unit comes from, whose unit cost the unit carries; 0 takes the cost of the first open entry at the location.</param>
    internal procedure NegativeAdjustmentFromEntry(var FAConversion: Record "FA Conversion"; AppliesToEntryNo: Integer; CostEntryNo: Integer)
    var
        ErrorHandlingLbl: Label 'Failed to create negative adjustment: %1', Comment = '%1 = Error message';
    begin
        if not TryNegativeAdjustmentFromEntry(FAConversion, AppliesToEntryNo, CostEntryNo) then begin
            // Same cleanup as NegativeAdjustment: the SingleInstance global must not outlive the failed call (NDIT-6082, LD-7).
            Clear(GlobalFAConversion);
            Error(ErrorHandlingLbl, GetLastErrorText());
        end;
    end;

    [TryFunction]
    local procedure TryNegativeAdjustmentFromEntry(var FAConversion: Record "FA Conversion"; AppliesToEntryNo: Integer; CostEntryNo: Integer)
    begin
        PostNegativeAdjustment(FAConversion, true, AppliesToEntryNo, CostEntryNo);
    end;

    local procedure PostNegativeAdjustment(var FAConversion: Record "FA Conversion"; SkipCosting: Boolean; AppliesToEntryNo: Integer; CostEntryNo: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
        FixedAsset: Record "Fixed Asset";
        FAConversionSetup: Record "FA Conversion Setup";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        NoSeries: Codeunit "No. Series";
    begin
        FAConversion.TestField("Location Code");
        FAConversion.TestField("Posting Date");

        Item.SetLoadFields("FA Conv. Gen. Bus. Post. Group");
        if not Item.Get(FAConversion."Item No.") then
            Error(RecordDoesNotExistErr, Item.TableCaption(), FAConversion."Item No.");

        FAConversionSetup.GetRecordOnce();
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
        ItemJournalLine.Validate("Posting Date", FAConversion."Posting Date");

        // The batch number series is date-bound: SetUpNewLine peeked the number for the operation day. Peek it
        // again for the posting date, otherwise the batch posting refuses a posting date in another series period.
        ItemJournalBatch.SetLoadFields("No. Series");
        if ItemJournalBatch.Get(FAConversionSetup."Item Journal Template Name", FAConversionSetup."Item Journal Batch Name") then
            if ItemJournalBatch."No. Series" <> '' then
                ItemJournalLine.Validate("Document No.", NoSeries.PeekNextNo(ItemJournalBatch."No. Series", FAConversion."Posting Date"));

        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::"Negative Adjmt.");
        ItemJournalLine.Validate("Item No.", FAConversion."Item No.");
        ItemJournalLine.Validate("Variant Code", FAConversion."Variant Code");
        ItemJournalLine.Validate(Quantity, 1);
        ItemJournalLine.Validate("Location Code", FAConversion."Location Code");
        ItemJournalLine.Validate("Gen. Bus. Posting Group", Item."FA Conv. Gen. Bus. Post. Group");
        SetApplicationAndUnitCost(ItemJournalLine, AppliesToEntryNo, CostEntryNo);
        ItemJournalLine.Modify(true);

        CreateReservationEntry(ItemJournalLine, FAConversion);

        ItemJnlPostBatch.SetSuppressCommit(true);
        ItemJnlPostBatch.Run(ItemJournalLine);
        //Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJournalLine);

        FAConversion.Validate("Negative Adjmt. ILE Entry No.", GlobalILENo);
        FAConversion.Modify(true);

        if not FixedAsset.Get(FAConversion."FA No.") then
            Error(RecordDoesNotExistErr, FixedAsset.TableCaption(), FAConversion."FA No.");
        FixedAsset.Validate("Serial No.", FAConversion."Serial No.");
        FixedAsset.Validate("Source Item No.", FAConversion."Item No.");
        FixedAsset.Validate("Source Variant Code", FAConversion."Variant Code");
        FixedAsset.Modify(true);

        if not SkipCosting then begin
            GlobalFAConversion := FAConversion;
            AdjustAndPostInventoryCost(FAConversion);
            Clear(GlobalFAConversion);
        end;
    end;

    // A unit of a conversion request is taken from an inbound entry of its own source line, so that it does not use up the
    // stock of another received line of the item at the location, and it carries the cost of that entry (NDIT-6082, review;
    // D27). A serial number is applied through its item tracking, not through Applies-to Entry, but still carries the cost of
    // its own entry: without it the cost of the first open entry at the location was used, which is another receipt's cost
    // whenever the cost is not adjusted before the acquisition reads it (review finding F1). The request engine gives that entry
    // only when the serial number is applied to it, which needs SN Specific Tracking on the item tracking code (second review,
    // finding 1). Without entries the line applies by the costing method and takes the cost of the first open entry at the
    // location, as it always did.
    local procedure SetApplicationAndUnitCost(var ItemJournalLine: Record "Item Journal Line"; AppliesToEntryNo: Integer; CostEntryNo: Integer)
    begin
        if AppliesToEntryNo <> 0 then
            ItemJournalLine.Validate("Applies-to Entry", AppliesToEntryNo);

        if CostEntryNo = 0 then
            ItemJournalLine.Validate("Unit Cost", GetUnitCostFromItemJnlLine(ItemJournalLine))
        else
            ItemJournalLine.Validate("Unit Cost", GetUnitCostOfEntry(CostEntryNo));
    end;

    local procedure GetUnitCostOfEntry(ItemLedgerEntryNo: Integer): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetLoadFields("Cost Amount (Actual)", Quantity);
        ItemLedgerEntry.SetAutoCalcFields("Cost Amount (Actual)");
        if not ItemLedgerEntry.Get(ItemLedgerEntryNo) then
            Error(RecordDoesNotExistErr, ItemLedgerEntry.TableCaption(), ItemLedgerEntryNo);

        if ItemLedgerEntry.Quantity = 0 then
            exit(0);

        exit(ItemLedgerEntry."Cost Amount (Actual)" / ItemLedgerEntry.Quantity);
    end;

    /// <summary>
    /// Calculates the unit cost from Item Ledger Entries for the journal line.
    /// </summary>
    /// <param name="ItemJournalLine">The Item Journal Line to calculate cost for.</param>
    /// <returns>The calculated unit cost based on actual cost from Item Ledger Entries.</returns>
    procedure GetUnitCostFromItemJnlLine(var ItemJournalLine: Record "Item Journal Line"): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetLoadFields("Cost Amount (Actual)", Quantity);
        ItemLedgerEntry.SetAutoCalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetRange("Location Code", ItemJournalLine."Location Code");
        ItemLedgerEntry.SetRange("Item No.", ItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Variant Code", ItemJournalLine."Variant Code");
        if ItemLedgerEntry.FindFirst() then
            if ItemLedgerEntry."Cost Amount (Actual)" <> 0 then
                exit(ItemLedgerEntry."Cost Amount (Actual)" / ItemLedgerEntry.Quantity);

        exit(0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post", OnBeforeCode, '', false, false)]
    local procedure "Item Jnl.-Post_OnBeforeCode"(var HideDialog: Boolean)
    begin
        HideDialog := true;
    end;



    local procedure CreateReservationEntry(ItemJournalLine: Record "Item Journal Line"; FAConversion: Record "FA Conversion")
    var
        TempReservationEntry: Record "Reservation Entry" temporary;
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservStatus: Enum "Reservation Status";
    begin
        if FAConversion."Serial No." = '' then
            exit;

        TempReservationEntry.Init();
        TempReservationEntry."Entry No." := 1;
        TempReservationEntry."Serial No." := FAConversion."Serial No.";
        TempReservationEntry.Quantity := 1;
        TempReservationEntry.Insert(false);

        CreateReservEntry.CreateReservEntryFor(
          Database::"Item Journal Line", ItemJournalLine."Entry Type".AsInteger(),
          ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", 0, ItemJournalLine."Line No.", ItemJournalLine."Qty. per Unit of Measure",
          TempReservationEntry.Quantity, TempReservationEntry.Quantity * ItemJournalLine."Qty. per Unit of Measure", TempReservationEntry);
        CreateReservEntry.CreateEntry(
          ItemJournalLine."Item No.", ItemJournalLine."Variant Code", ItemJournalLine."Location Code", '', 0D, ItemJournalLine."Posting Date", 0, ReservStatus::Prospect);
    end;

    /// <summary>
    /// Adjusts item costs and posts inventory cost to General Ledger.
    /// </summary>
    /// <param name="FAConversion">The FA Conversion record for which to adjust costs.</param>
    procedure AdjustAndPostInventoryCost(var FAConversion: Record "FA Conversion")
    var
        PostValueEntrytoGL: Record "Post Value Entry to G/L";
        AdjustCostItemEntries: Report "Adjust Cost - Item Entries";
        PostInventoryCosttoGL: Report "Post Inventory Cost to G/L";
    begin

        AdjustCostItemEntries.InitializeRequest(FAConversion."Item No.", '');
        AdjustCostItemEntries.UseRequestPage(false);
        AdjustCostItemEntries.RunModal();

        PostValueEntrytoGL.Reset();
        PostValueEntrytoGL.SetRange("Item No.", FAConversion."Item No.");
        PostInventoryCosttoGL.SetTableView(PostValueEntrytoGL);
        PostInventoryCosttoGL.UseRequestPage(false);
        PostInventoryCosttoGL.InitializeRequest(1, '', true);
        PostInventoryCosttoGL.RunModal();

        //Report.RunModal(Report::"Post Inventory Cost to G/L", false);
    end;

    /// <summary>
    /// Posts Fixed Asset acquisition entry through General Journal.
    /// </summary>
    /// <param name="FAConversion">The FA Conversion record to process for acquisition.</param>
    procedure FAAcquisition(var FAConversion: Record "FA Conversion")
    var
        ErrorHandlingLbl: Label 'Failed to post FA acquisition: %1', Comment = '%1 = Error message';
    begin
        if not TryFAAcquisition(FAConversion) then begin
            // An error between the hand-over of the conversion to the posting subscribers and the end of the
            // try method skips its own cleanup; the SingleInstance global must not outlive the failed call
            // (NDIT-6082, LD-7).
            Clear(GlobalFAConversion);
            Error(ErrorHandlingLbl, GetLastErrorText());
        end;
    end;

    /// <summary>
    /// Attempts to post Fixed Asset acquisition entry through General Journal.
    /// </summary>
    /// <param name="FAConversion">The FA Conversion record to process for acquisition.</param>
    /// <returns>True when the acquisition was posted; false when an error was caught (try method).</returns>
    [TryFunction]
    procedure TryFAAcquisition(var FAConversion: Record "FA Conversion")
    var
        GenJournalLine: Record "Gen. Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        GeneralPostingSetup: Record "General Posting Setup";
        ServiceItemGroup: Record "Service Item Group";
        FAConversionSetup: Record "FA Conversion Setup";
    begin
        FAConversionSetup.GetRecordOnce();

        FAConversion.TestField("Negative Adjmt. ILE Entry No.");
        FAConversion.TestField("Posting Date");

        Item.SetLoadFields("FA Conv. Gen. Bus. Post. Group", "Service Item Group", "Gen. Prod. Posting Group");
        if not Item.Get(FAConversion."Item No.") then
            Error(RecordDoesNotExistErr, Item.TableCaption(), FAConversion."Item No.");
        Item.TestField("FA Conv. Gen. Bus. Post. Group");

        ServiceItemGroup.SetLoadFields("Create Service Item");
        if ServiceItemGroup.Get(Item."Service Item Group") and ServiceItemGroup."Create Service Item" then
            CreateServiceItemFromFAConversion(FAConversion);

        FAConversionSetup.GetRecordOnce();
        FAConversionSetup.TestField("Gen. Journal Template Name");
        FAConversionSetup.TestField("Gen. Journal Batch Name");

        ItemLedgerEntry.SetLoadFields("Entry No.");
        if not ItemLedgerEntry.Get(FAConversion."Negative Adjmt. ILE Entry No.") then
            Error(RecordDoesNotExistErr, ItemLedgerEntry.TableCaption(), FAConversion."Negative Adjmt. ILE Entry No.");
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");

        GeneralPostingSetup.SetLoadFields("Inventory Adjmt. Account");
        if not GeneralPostingSetup.Get(Item."FA Conv. Gen. Bus. Post. Group", Item."Gen. Prod. Posting Group") then
            Error(RecordWithTwoKeysDoesNotExistErr, GeneralPostingSetup.TableCaption(), Item."FA Conv. Gen. Bus. Post. Group", Item."Gen. Prod. Posting Group");
        GeneralPostingSetup.TestField("Inventory Adjmt. Account");

        GenJournalLine.SetRange("Journal Template Name", FAConversionSetup."Gen. Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", FAConversionSetup."Gen. Journal Batch Name");
        GenJournalLine.DeleteAll(true);

        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", FAConversionSetup."Gen. Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", FAConversionSetup."Gen. Journal Batch Name");
        GenJournalLine.Validate("Line No.", 10000);
        GenJournalLine.SetUpNewLine(GenJournalLine, 0, true);
        GenJournalLine.Insert(true);
        GenJournalLine.Validate("Document No.", FAConversion."No.");
        GenJournalLine.Validate("Posting Date", FAConversion."Posting Date");
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"Fixed Asset");
        GenJournalLine.Validate("Account No.", FAConversion."FA No.");
        GenJournalLine.Validate("FA Posting Type", GenJournalLine."FA Posting Type"::"Acquisition Cost");
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Purchase);
        GenJournalLine.Validate("Gen. Bus. Posting Group", Item."FA Conv. Gen. Bus. Post. Group");
        GenJournalLine.Validate("Gen. Prod. Posting Group", Item."Gen. Prod. Posting Group");
        GenJournalLine.Validate(Amount, -1 * ItemLedgerEntry."Cost Amount (Actual)");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GeneralPostingSetup."Inventory Adjmt. Account");
        GenJournalLine.Validate("VAT Bus. Posting Group", FAConversionSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("VAT Prod. Posting Group", FAConversionSetup."VAT Prod. Posting Group");

        if FAConversion."E-Book Description INF" <> '' then
            GenJournalLine.Validate("E-Book Description INF", FAConversion."E-Book Description INF")
        else
            GenJournalLine.Validate("E-Book Description INF", FAConversionSetup."E-Book Description INF");
        GenJournalLine.Modify(true);

        PostAcquisitionJournalLine(GenJournalLine, FAConversion);

        OnAfterFAAcquisitionPosted(GlobalFAConversion);

        Clear(GlobalFAConversion);
    end;

    /// <summary>
    /// Posts the prepared acquisition journal line and checks that the fixed asset really got a new acquisition cost
    /// entry. SendToPosting does not raise when the posting fails: it commits, runs the posting codeunit with its
    /// errors captured and only lists them on the Error Messages page. A posting that left no new entry is therefore
    /// raised here, so that the dependent apps are not told about an acquisition that does not exist (NDIT-6082, D2).
    /// The check applies only when the line is posted synchronously: with General Ledger Setup "Post with Job Queue"
    /// the posting codeunit only schedules the line and nothing is posted yet, so there is nothing to verify and the
    /// call returns as it always did (NDIT-6082, D20).
    /// </summary>
    /// <param name="GenJournalLine">The acquisition journal line, still carrying the journal batch filters.</param>
    /// <param name="FAConversion">The FA Conversion the acquisition belongs to; it is handed to the posting subscribers through the global.</param>
    local procedure PostAcquisitionJournalLine(var GenJournalLine: Record "Gen. Journal Line"; FAConversion: Record "FA Conversion")
    var
        LastAcquisitionEntryNoBefore: Integer;
        PostedSynchronously: Boolean;
        AcquisitionNotPostedErr: Label 'The acquisition of fixed asset %2 for FA Conversion %1 was not posted. Check the errors of the posting, correct the cause and post the FA acquisition again.', Comment = '%1 = FA Conversion No., %2 = Fixed Asset No.';
    begin
        PostedSynchronously := not IsPostWithJobQueue();
        LastAcquisitionEntryNoBefore := GetLastAcquisitionCostEntryNo(FAConversion."FA No.");
        GlobalFAConversion := FAConversion;
        GenJournalLine.SendToPosting(Codeunit::"Gen. Jnl.-Post");

        // Gen. Jnl.-Post only enqueued the line (Job Queue Entry, journal line "Scheduled for Posting"): no entry exists
        // yet and none is expected, so there is nothing to verify and no error (NDIT-6082, D20).
        if not PostedSynchronously then
            exit;

        // The conversion is cleared before the Error: the caller's own cleanup is skipped by it (NDIT-6082, LD-7).
        if GetLastAcquisitionCostEntryNo(FAConversion."FA No.") = LastAcquisitionEntryNoBefore then begin
            Clear(GlobalFAConversion);
            Error(AcquisitionNotPostedErr, FAConversion."No.", FAConversion."FA No.");
        end;
    end;

    /// <summary>
    /// Tells whether the standard journal posting only schedules a general journal line instead of posting it. Gen. Jnl.-Post
    /// decides this from General Ledger Setup "Post with Job Queue" alone, read at the moment it runs.
    /// </summary>
    /// <returns>True when Gen. Jnl.-Post enqueues the line (nothing is posted before the job runs); false when it posts the line at once, or when General Ledger Setup does not exist (the posting then raises its own error, which the check after it reports).</returns>
    local procedure IsPostWithJobQueue(): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.SetLoadFields("Post with Job Queue");
        if not GeneralLedgerSetup.Get() then
            exit(false);

        exit(GeneralLedgerSetup."Post with Job Queue");
    end;

    /// <summary>
    /// Returns the number of the newest acquisition cost entry of a fixed asset, read from the FA ledger.
    /// </summary>
    /// <param name="FANo">The fixed asset to look at.</param>
    /// <returns>The entry number of the newest acquisition cost entry; 0 when the fixed asset has none.</returns>
    local procedure GetLastAcquisitionCostEntryNo(FANo: Code[20]): Integer
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetLoadFields("Entry No.");
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Acquisition Cost");
        if FALedgerEntry.FindLast() then
            exit(FALedgerEntry."Entry No.");

        exit(0);
    end;

    local procedure ApplyDepreciationProfile(Item: Record Item; FAConversion: Record "FA Conversion"; var FADepreciationBook: Record "FA Depreciation Book")
    var
        StartDate: Date;
    begin
        StartDate := GetDepreciationStartDate(FAConversion);
        if StartDate = 0D then
            exit;

        // If Ömür Yılı is provided on the Item Card, copy it to the FA Depreciation Book and
        // explicitly compute the Depreciation Ending Date from the life-years formula.
        if Item."FA Life Years INF" <> 0 then begin
            ApplyLifeYears(Item."FA Life Years INF", StartDate, FADepreciationBook);
            exit;
        end;

        ApplyDepreciationProfileFormula(Item."FA Depr. Profile Code INF", StartDate, FADepreciationBook);
    end;

    local procedure ApplyLifeYears(LifeYears: Integer; StartDate: Date; var FADepreciationBook: Record "FA Depreciation Book")
    var
        LifeFormula: DateFormula;
        EndDate: Date;
        LifeFormulaTok: Label '%1Y', Locked = true, Comment = '%1 = number of depreciation years';
    begin
        FADepreciationBook.Validate("Depreciation Starting Date", StartDate);
        FADepreciationBook.Validate("No. of Depreciation Years", LifeYears);

        // Make ending date explicit so the depreciation book shows the expected value.
        Evaluate(LifeFormula, StrSubstNo(LifeFormulaTok, LifeYears));
        EndDate := CalcDate(LifeFormula, StartDate);
        if EndDate <> 0D then
            EndDate := EndDate - 1;
        if EndDate <> 0D then
            FADepreciationBook.Validate("Depreciation Ending Date", EndDate);

        FADepreciationBook.Modify(true);
    end;

    local procedure ApplyDepreciationProfileFormula(DepreciationProfileCode: Code[20]; StartDate: Date; var FADepreciationBook: Record "FA Depreciation Book")
    var
        DepreciationProfile: Record "FA Depreciation Profile";
        EndDate: Date;
        YearCount: Decimal;
    begin
        if DepreciationProfileCode = '' then
            exit;

        DepreciationProfile.SetLoadFields("Depreciation Life Formula");
        if not DepreciationProfile.Get(DepreciationProfileCode) then
            exit;

        DepreciationProfile.TestField("Depreciation Life Formula");

        EndDate := CalcDate(DepreciationProfile."Depreciation Life Formula", StartDate);
        if EndDate <> 0D then
            EndDate := EndDate - 1;

        YearCount := CalculateYearCount(StartDate, DepreciationProfile."Depreciation Life Formula");

        FADepreciationBook.Validate("Depreciation Starting Date", StartDate);

        if EndDate <> 0D then
            FADepreciationBook.Validate("Depreciation Ending Date", EndDate);

        if YearCount <> 0 then
            FADepreciationBook.Validate("No. of Depreciation Years", YearCount);

        FADepreciationBook.Modify(true);
    end;

    local procedure GetDepreciationStartDate(FAConversion: Record "FA Conversion"): Date
    var
        PostingYear: Integer;
    begin
        if FAConversion."Posting Date" = 0D then
            exit(0D);

        PostingYear := FAConversion."Posting Date".Year();
        exit(DMY2Date(1, 1, PostingYear));
    end;

    local procedure CalculateYearCount(StartDate: Date; LifeFormula: DateFormula): Decimal
    var
        EndDateExclusive: Date;
    begin
        if StartDate = 0D then
            exit(0);

        if Format(LifeFormula) = '' then
            exit(0);

        EndDateExclusive := CalcDate(LifeFormula, StartDate);
        if EndDateExclusive = 0D then
            exit(0);

        exit(EndDateExclusive.Year() - StartDate.Year());
    end;

    /// <summary>
    /// Recalculates the depreciation dates of the fixed asset of an FA Conversion from its posting date: the
    /// depreciation starts on 1 January of the posting date year and ends according to the life years of the item
    /// or to its depreciation profile. Does nothing when the conversion has no fixed asset yet, when the negative
    /// adjustment or the FA acquisition is already posted, or when the item or the depreciation book does not exist.
    /// </summary>
    /// <param name="FAConversion">The FA Conversion whose posting date drives the depreciation dates; it is not modified.</param>
    procedure RecalculateDepreciationDates(var FAConversion: Record "FA Conversion")
    var
        FADepreciationBook: Record "FA Depreciation Book";
        Item: Record Item;
        FAConversionSetup: Record "FA Conversion Setup";
    begin
        if FAConversion."FA No." = '' then
            exit;

        if (FAConversion."Negative Adjmt. ILE Entry No." <> 0) or (FAConversion."FA Acquisition Entry No." <> 0) then
            exit;

        if not Item.Get(FAConversion."Item No.") then
            exit;

        FAConversionSetup.GetRecordOnce();
        if not FADepreciationBook.Get(FAConversion."FA No.", FAConversionSetup."Depreciation Book Code") then
            exit;

        ApplyDepreciationProfile(Item, FAConversion, FADepreciationBook);
    end;

    /// <summary>
    /// Creates a Service Item based on the FA Conversion data.
    /// </summary>
    /// <param name="FAConversion">The FA Conversion record to create Service Item from.</param>
    procedure CreateServiceItemFromFAConversion(FAConversion: Record "FA Conversion")
    var
        ServItem: Record "Service Item";
        TempServItem: Record "Service Item" temporary;
        ServMgtSetup: Record "Service Mgt. Setup";
        NoSeries: Codeunit "No. Series";
    begin
        ServMgtSetup.GetRecordOnce();
        ServMgtSetup.TestField("Service Item Nos.");
        // Key built in a temporary buffer: Service Item "No." OnValidate (TestManual, clearing
        // "No. Series") must not run, and OnInsert must not re-number (it would call AreRelated,
        // which requires "Default Nos."). Identical to the former direct assignment.
        TempServItem.Init();
        TempServItem."No. Series" := ServMgtSetup."Service Item Nos.";
        TempServItem."No." := NoSeries.GetNextNo(TempServItem."No. Series");
        ServItem := TempServItem;
        ServItem.Insert(true);
        //ServItem.OmitAssignResSkills(true);
        ServItem.Validate("Item No.", FAConversion."Item No.");
        //ServItem.OmitAssignResSkills(false);
        // "Variant Code" is deliberately not validated: its TableRelation rejects blocked and
        // service-blocked variants, which this conversion has always accepted (behaviour
        // preservation). The plain assignment goes through the temporary buffer, so neither the
        // OnValidate trigger nor the relation check runs.
        TempServItem := ServItem;
        TempServItem."Variant Code" := FAConversion."Variant Code";
        ServItem := TempServItem;
        ServItem.Validate("Serial No.", FAConversion."Serial No.");
        ServItem.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post", OnBeforeCode, '', false, false)]
    local procedure "Gen. Jnl.-Post_OnBeforeCode"(var HideDialog: Boolean)
    begin
        HideDialog := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post", OnBeforeShowPostResultMessage, '', false, false)]
    local procedure "Gen. Jnl.-Post_OnBeforeShowPostResultMessage"(var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Insert Ledger Entry", OnBeforeInsertRegister, '', false, false)]
    local procedure "FA Insert Ledger Entry_OnBeforeInsertRegister"(var FALedgerEntry: Record "FA Ledger Entry")
    begin
        if GlobalFAConversion."Item No." = '' then
            exit;

        // Every FA ledger entry of the session passes here. Only the entries of the fixed asset being converted
        // belong to the conversion held in the global (NDIT-6082, LD-7: defence against a stale global).
        if FALedgerEntry."FA No." <> GlobalFAConversion."FA No." then
            exit;

        GlobalFAConversion.Validate("FA Acquisition Entry No.", FALedgerEntry."Entry No.");
        GlobalFAConversion.Modify(false);
    end;


    [EventSubscriber(ObjectType::Report, Report::"Adjust Cost - Item Entries", OnBeforePreReport, '', false, false)]
    local procedure "Adjust Cost - Item Entries_OnBeforePreReport"(var Item: Record Item)
    begin
        if GlobalFAConversion."Item No." = '' then
            exit;

        if not Item.Get(GlobalFAConversion."Item No.") then
            Error(RecordDoesNotExistErr, Item.TableCaption(), GlobalFAConversion."Item No.");
    end;

    [EventSubscriber(ObjectType::Report, Report::"Post Inventory Cost to G/L INF", OnBeforePreReport, '', false, false)]
    local procedure "Post Inventory Cost to G/L INF_OnBeforePreReport"(var Sender: Report "Post Inventory Cost to G/L INF"; var PostValueEntryToGL: Record "Post Value Entry to G/L")
    begin
        if GlobalFAConversion."Item No." = '' then
            exit;

        Sender.InitializeRequest(1, '', true); // 1 corresponds to "per Entry"
        PostValueEntryToGL.SetFilter("Item No.", GlobalFAConversion."Item No.");
    end;


    // Removed deprecated event subscriber for NoSeriesManagement.OnAfterSetParametersBeforeRun
    // The modern "No. Series" codeunit handles transaction management internally
    // and no longer requires manual commit logic through event subscribers

    /// <summary>
    /// Creates a Fixed Asset conversion from a Transfer Receipt Line.
    /// </summary>
    /// <param name="TransferReceiptLine">The Transfer Receipt Line to convert to Fixed Asset.</param>
    /// <param name="ShowPageAfterCreation">Whether to display the FA Conversion page after creation.</param>
    procedure CreateFAConversionFromTransferReceiptLine(TransferReceiptLine: Record "Transfer Receipt Line"; ShowPageAfterCreation: Boolean)
    begin
        CreateFAConversionFromTransferReceiptLine(TransferReceiptLine, ShowPageAfterCreation, '');
    end;

    /// <summary>
    /// Creates a Fixed Asset conversion from a Transfer Receipt Line with specific serial number.
    /// </summary>
    /// <param name="TransferReceiptLine">The Transfer Receipt Line to convert to Fixed Asset.</param>
    /// <param name="ShowPageAfterCreation">Whether to display the FA Conversion page after creation.</param>
    /// <param name="SerialNo">The specific serial number to assign to the conversion.</param>
    procedure CreateFAConversionFromTransferReceiptLine(TransferReceiptLine: Record "Transfer Receipt Line"; ShowPageAfterCreation: Boolean; SerialNo: Text[50])
    var
        FAConversion: Record "FA Conversion";
        Item: Record Item;
        UseSerialNo: Text[50];
        CompleteFAFailedErr: Label 'Failed to complete FA Conversion: %1', Comment = '%1 = Error message';
    begin
        if not Item.Get(TransferReceiptLine."Item No.") then
            Error(RecordDoesNotExistErr, Item.TableCaption(), TransferReceiptLine."Item No.");

        Item.TestField("FA No. Series");
        Item.TestField("FA Conv. Gen. Bus. Post. Group");
        Item.TestField("FA Posting Group");
        Item.TestField("FA Life Years INF");

        // Use provided serial number or get from Transfer Receipt Line
        if SerialNo <> '' then
            UseSerialNo := SerialNo
        else
            UseSerialNo := GetSerialNoFromTransferReceiptLine(TransferReceiptLine);

        FAConversion.Init();
        FAConversion.Insert(true);
        FAConversion.Validate("Item No.", Item."No.");
        FAConversion.Validate("Variant Code", TransferReceiptLine."Variant Code");
        FAConversion.Validate("Item Description", TransferReceiptLine.Description);
        FAConversion.Validate("Serial No.", UseSerialNo);
        // Posting Date must be the operation day (WorkDate), NOT the original Transfer Receipt
        // posting date. Using the stale transfer date (e.g. a prior year) forces the item/gen
        // journal into a closed period / wrong No. Series and blocks posting (NDIT-5968).
        FAConversion.Validate("Posting Date", WorkDate());
        // Populate Location Code from Transfer Receipt Line before creating the Fixed Asset
        FAConversion.Validate("Location Code", TransferReceiptLine."Transfer-to Code");
        // Record the receipt line the conversion comes from, so that later requests see this conversion
        FAConversion.Validate("Source Document Type", FAConversion."Source Document Type"::"Transfer Receipt");
        FAConversion.Validate("Source Document No.", TransferReceiptLine."Document No.");
        FAConversion.Validate("Source Document Line No.", TransferReceiptLine."Line No.");
        CreateFixedAsset(Item, FAConversion);
        FAConversion.Modify(true);

        if ShowPageAfterCreation then
            Page.Run(Page::"FA Conversion", FAConversion)
        else
            // All-or-nothing transaction: FA creation + Transfer item creation
            if not TryCreateCompleteFA(FAConversion) then
                Error(CompleteFAFailedErr, GetLastErrorText());
    end;

    /// <summary>
    /// Creates the FA Conversion, the Fixed Asset and its depreciation book for one unit of a source line of a
    /// conversion request. The acquisition date becomes the posting date of the FA Conversion, so the depreciation
    /// starts on 1 January of its year. Nothing is posted and nothing is committed.
    /// </summary>
    /// <param name="TempFAConvSourceLine">The request row, positioned on the source line the unit is converted from.</param>
    /// <param name="SerialNo">The serial number of the unit; blank for a unit without a serial number.</param>
    /// <param name="AcquisitionDate">The acquisition date of the unit.</param>
    /// <param name="FAConversion">Receives the stored FA Conversion with its fixed asset.</param>
    internal procedure CreateFAConversionFromSourceLine(var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary; SerialNo: Code[50]; AcquisitionDate: Date; var FAConversion: Record "FA Conversion")
    var
        Item: Record Item;
    begin
        if not Item.Get(TempFAConvSourceLine."Item No.") then
            Error(RecordDoesNotExistErr, Item.TableCaption(), TempFAConvSourceLine."Item No.");

        Item.TestField("FA No. Series");
        Item.TestField("FA Conv. Gen. Bus. Post. Group");
        Item.TestField("FA Posting Group");
        Item.TestField("FA Life Years INF");

        FAConversion.Init();
        FAConversion.Insert(true);
        FAConversion.Validate("Item No.", Item."No.");
        FAConversion.Validate("Variant Code", TempFAConvSourceLine."Variant Code");
        FAConversion.Validate("Item Description", TempFAConvSourceLine.Description);
        FAConversion.Validate("Serial No.", SerialNo);
        // The acquisition date, not the operation day: the depreciation dates of CreateFixedAsset derive from it
        FAConversion.Validate("Posting Date", AcquisitionDate);
        FAConversion.Validate("Location Code", TempFAConvSourceLine."Location Code");
        FAConversion.Validate("Source Document Type", TempFAConvSourceLine."Source Document Type");
        FAConversion.Validate("Source Document No.", TempFAConvSourceLine."Source Document No.");
        FAConversion.Validate("Source Document Line No.", TempFAConvSourceLine."Source Document Line No.");
        CreateFixedAsset(Item, FAConversion);
        FAConversion.Modify(true);
    end;

    /// <summary>
    /// Retrieves the serial number from Item Ledger Entries for a Transfer Receipt Line.
    /// </summary>
    /// <param name="TransferReceiptLine">The Transfer Receipt Line to get serial number for.</param>
    /// <returns>The serial number found in the associated Item Ledger Entry.</returns>
    procedure GetSerialNoFromTransferReceiptLine(TransferReceiptLine: Record "Transfer Receipt Line"): Text[50]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        NoSerialNoFoundErr: Label 'No serial number found for transfer receipt line %1/%2.', Comment = '%1 = Document No., %2 = Line No.';
    begin
        // Find Item Ledger Entry for the Transfer Receipt Line
        ItemLedgerEntry.SetLoadFields("Serial No.");
        ItemLedgerEntry.SetRange("Document No.", TransferReceiptLine."Document No.");
        ItemLedgerEntry.SetRange("Document Line No.", TransferReceiptLine."Line No.");
        ItemLedgerEntry.SetRange("Item No.", TransferReceiptLine."Item No.");
        ItemLedgerEntry.SetRange("Variant Code", TransferReceiptLine."Variant Code");
        ItemLedgerEntry.SetRange("Location Code", TransferReceiptLine."Transfer-to Code");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.SetFilter("Remaining Quantity", '>0'); // Receipt entry

        if not ItemLedgerEntry.FindFirst() then
            Error(NoSerialNoFoundErr, TransferReceiptLine."Document No.", TransferReceiptLine."Line No.");

        exit(ItemLedgerEntry."Serial No.");
    end;

    /// <summary>
    /// Retrieves all serial numbers from Item Ledger Entries for a Transfer Receipt Line.
    /// </summary>
    /// <param name="TransferReceiptLine">The Transfer Receipt Line to get serial numbers for.</param>
    /// <param name="SerialNoList">List to populate with found serial numbers.</param>
    procedure GetSerialNosFromTransferReceiptLine(TransferReceiptLine: Record "Transfer Receipt Line"; var SerialNoList: List of [Text[50]])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Clear the list
        Clear(SerialNoList);

        // Find all Item Ledger Entries for the Transfer Receipt Line
        ItemLedgerEntry.SetLoadFields("Serial No.", "Remaining Quantity");
        ItemLedgerEntry.SetRange("Document No.", TransferReceiptLine."Document No.");
        ItemLedgerEntry.SetRange("Document Line No.", TransferReceiptLine."Line No.");
        ItemLedgerEntry.SetRange("Item No.", TransferReceiptLine."Item No.");
        ItemLedgerEntry.SetRange("Variant Code", TransferReceiptLine."Variant Code");
        ItemLedgerEntry.SetRange("Location Code", TransferReceiptLine."Transfer-to Code");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetRange(Positive, true); // Receipt entries only
        ItemLedgerEntry.SetFilter("Remaining Quantity", '>0'); // Only entries with remaining quantity

        if ItemLedgerEntry.FindSet() then
            repeat
                if (ItemLedgerEntry."Serial No." <> '') and (ItemLedgerEntry."Remaining Quantity" > 0) then
                    SerialNoList.Add(ItemLedgerEntry."Serial No.");
            until ItemLedgerEntry.Next() = 0;
    end;

    /// <summary>
    /// Creates multiple Fixed Asset conversions from a single Transfer Receipt Line based on serial numbers or quantity.
    /// </summary>
    /// <param name="TransferReceiptLine">The Transfer Receipt Line to create multiple FA conversions from.</param>
    procedure CreateMultipleFAConversionsFromTransferReceiptLine(TransferReceiptLine: Record "Transfer Receipt Line")
    var
        SerialNoList: List of [Text[50]];
        SerialNo: Text[50];
        i: Integer;
        QtyToProcess: Decimal;
    begin
        // Get all serial numbers for this transfer receipt line
        GetSerialNosFromTransferReceiptLine(TransferReceiptLine, SerialNoList);

        if SerialNoList.Count() > 0 then
            foreach SerialNo in SerialNoList do
                CreateFAConversionFromTransferReceiptLine(TransferReceiptLine, false, SerialNo)
        else begin
            // If no serial numbers, create FA Conversions based on quantity
            QtyToProcess := TransferReceiptLine.Quantity;
            for i := 1 to QtyToProcess do
                CreateFAConversionFromTransferReceiptLine(TransferReceiptLine, false, '');
        end;
    end;

    /// <summary>
    /// Attempts to create the complete FA (and, when enabled in FA Conversion Setup, the transfer
    /// item) in a single transaction. All operations succeed or all fail together (all-or-nothing).
    /// </summary>
    /// <param name="FAConversion">The FA Conversion record to process.</param>
    /// <returns>True when every step succeeded; false when an error was caught (try method).</returns>
    [TryFunction]
    local procedure TryCreateCompleteFA(var FAConversion: Record "FA Conversion")
    var
        FixedAsset: Record "Fixed Asset";
        LocalFAConversionSetup: Record "FA Conversion Setup";
        FATransferFunctions: Codeunit "FA Transfer Functions";
        FANotFoundErr: Label 'Fixed Asset %1 not found after creation.', Comment = '%1 = Fixed Asset No.';
    begin
        // Step 1: Post negative adjustment (remove from inventory)
        NegativeAdjustment(FAConversion, true);

        // Step 2: Post FA acquisition
        FAAcquisition(FAConversion);

        // Step 3: Create transfer item, only when the FA Transfer master switch and the
        // auto-create toggle are both enabled in setup (NDIT-5968). Read at this very step
        // with a plain Get, so toggling the master switch takes effect immediately. When
        // disabled, the user can still create the transfer item manually via the Create FA
        // Transfer Item action on the Fixed Asset card (guarded by the same master switch).
        if LocalFAConversionSetup.Get() then
            if LocalFAConversionSetup."Enable FA Transfer" and LocalFAConversionSetup."Auto Create FA Transfer Item" then begin
                if not FixedAsset.Get(FAConversion."FA No.") then
                    Error(FANotFoundErr, FAConversion."FA No.");

                // This will error if location is missing or transfer item creation fails
                FATransferFunctions.NewItemForTransfer(FixedAsset);
            end;

        // If we reach here, all steps succeeded
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", OnAfterInsertItemLedgEntry, '', false, false)]
    local procedure "Item Jnl.-Post Line_OnAfterInsertItemLedgEntry"(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        GlobalILENo := ItemLedgerEntry."Entry No.";
    end;



    local procedure GetDefaultLocationCode(): Code[10]
    var
        Location: Record Location;
        LocalFAConversionSetup: Record "FA Conversion Setup";
    begin
        Location.SetLoadFields(Code);
        // First try to get from FA Conversion Setup
        LocalFAConversionSetup.GetRecordOnce();
        if LocalFAConversionSetup."FA Trans. Pos. Adjmt. Loc." <> '' then
            if Location.Get(LocalFAConversionSetup."FA Trans. Pos. Adjmt. Loc.") then
                exit(LocalFAConversionSetup."FA Trans. Pos. Adjmt. Loc.");

        // If no default location in setup, try to get the first available location
        if Location.FindFirst() then
            exit(Location.Code);

        // If no locations exist, return empty (will be handled by validation)
        exit('');
    end;

    local procedure EnsureFALocationExists(LocationCode: Code[10])
    var
        FALocation: Record "FA Location";
    begin
        if LocationCode = '' then
            exit;

        if not FALocation.Get(LocationCode) then begin
            FALocation.Init();
            FALocation.Validate(Code, LocationCode);
            FALocation.Validate(Name, LocationCode); // Use code as default name
            FALocation.Insert(true);
        end;
    end;


    /// <summary>
    /// Raised after the FA acquisition of an FA Conversion has been posted through the general journal,
    /// inside the same transaction and before the conversion's global state is cleared. It is not raised
    /// when the posting did not produce the acquisition: the FA acquisition then raises an error instead.
    /// With General Ledger Setup "Post with Job Queue" the journal line is only scheduled: the event is raised
    /// right after it was scheduled, before any acquisition exists, with the conversion as it was handed in
    /// (this call does not stamp FA Acquisition Entry No.).
    /// </summary>
    /// <param name="FAConversion">The FA Conversion whose acquisition was posted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFAAcquisitionPosted(var FAConversion: Record "FA Conversion")
    begin
    end;



    var
        GlobalFAConversion: Record "FA Conversion";
        GlobalILENo: Integer;
        RecordDoesNotExistErr: Label '%1 %2 does not exist.', Comment = '%1 = Table caption, %2 = Key value';
        RecordWithTwoKeysDoesNotExistErr: Label '%1 %2, %3 does not exist.', Comment = '%1 = Table caption, %2 = First key value, %3 = Second key value';
}
