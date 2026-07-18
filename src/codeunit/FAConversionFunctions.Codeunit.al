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

codeunit 60000 "FA Conversion Functions"
{
    SingleInstance = true;
    Access = Public;
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
        Item.Get(ItemVariant."Item No.");

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
        FADepreciationBook: Record "FA Depreciation Book";
        //NoSeriesManagement: Codeunit NoSeriesManagement;
        NoSeries: Codeunit "No. Series";
    begin
        FAConversionSetup.GetRecordOnce();
        FAConversionSetup.TestField("Depreciation Book Code");

        FixedAsset.Init();
        //NoSeriesManagement.InitSeries(Item."FA No. Series", FixedAsset."No. Series", 0D, FixedAsset."No.", FixedAsset."No. Series");
        FixedAsset."No. Series" := Item."FA No. Series";
        FixedAsset."No." := NoSeries.GetNextNo(Item."FA No. Series", WorkDate());
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
        if not TryNegativeAdjustment(FAConversion, SkipCosting) then
            Error(ErrorHandlingLbl, GetLastErrorText());
    end;

    /// <summary>
    /// Attempts to post a negative inventory adjustment for the FA conversion item.
    /// </summary>
    /// <param name="FAConversion">The FA Conversion record to process.</param>
    /// <param name="SkipCosting">Whether to skip cost adjustment and posting to GL.</param>
    [TryFunction]
    procedure TryNegativeAdjustment(var FAConversion: Record "FA Conversion"; SkipCosting: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        FixedAsset: Record "Fixed Asset";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        FAConversion.TestField("Location Code");
        FAConversion.TestField("Posting Date");

        Item.Get(FAConversion."Item No.");

        FAConversionSetup.GetRecordOnce();
        FAConversionSetup.TestField("Item Journal Template Name");
        FAConversionSetup.TestField("Item Journal Batch Name");

        ItemJournalLine.SetRange("Journal Template Name", FAConversionSetup."Item Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", FAConversionSetup."Item Journal Batch Name");
        ItemJournalLine.DeleteAll(true);

        ItemJournalLine.Init();
        ItemJournalLine."Journal Template Name" := FAConversionSetup."Item Journal Template Name";
        ItemJournalLine."Journal Batch Name" := FAConversionSetup."Item Journal Batch Name";
        ItemJournalLine."Line No." := 10000;
        ItemJournalLine.SetUpNewLine(ItemJournalLine);
        ItemJournalLine.Insert(true);
        ItemJournalLine.Validate("Posting Date", FAConversion."Posting Date");
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::"Negative Adjmt.");
        ItemJournalLine.Validate("Item No.", FAConversion."Item No.");
        ItemJournalLine.Validate("Variant Code", FAConversion."Variant Code");
        ItemJournalLine.Validate(Quantity, 1);
        ItemJournalLine.Validate("Location Code", FAConversion."Location Code");
        ItemJournalLine.Validate("Gen. Bus. Posting Group", Item."FA Conv. Gen. Bus. Post. Group");
        ItemJournalLine.Validate("Unit Cost", GetUnitCostFromItemJnlLine(ItemJournalLine));
        ItemJournalLine.Modify(true);

        CreateReservationEntry(ItemJournalLine, FAConversion);

        ItemJnlPostBatch.SetSuppressCommit(true);
        ItemJnlPostBatch.Run(ItemJournalLine);
        //Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJournalLine);

        FAConversion."Negative Adjmt. ILE Entry No." := GlobalILENo;
        FAConversion.Modify(true);

        FixedAsset.Get(FAConversion."FA No.");
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
    local procedure OnBeforeCode(var ItemJournalLine: Record "Item Journal Line"; var HideDialog: Boolean; var SuppressCommit: Boolean; var IsHandled: Boolean)
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
        AdjustCostItemEntries.UseRequestPage := false;
        AdjustCostItemEntries.RunModal();

        PostValueEntrytoGL.Reset();
        PostValueEntrytoGL.SetRange("Item No.", FAConversion."Item No.");
        PostInventoryCosttoGL.SetTableView(PostValueEntrytoGL);
        PostInventoryCosttoGL.UseRequestPage := false;
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
        if not TryFAAcquisition(FAConversion) then
            Error(ErrorHandlingLbl, GetLastErrorText());
    end;

    /// <summary>
    /// Attempts to post Fixed Asset acquisition entry through General Journal.
    /// </summary>
    /// <param name="FAConversion">The FA Conversion record to process for acquisition.</param>
    [TryFunction]
    procedure TryFAAcquisition(var FAConversion: Record "FA Conversion")
    var
        GenJournalLine: Record "Gen. Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        GeneralPostingSetup: Record "General Posting Setup";
        ServiceItemGroup: Record "Service Item Group";
    begin
        FAConversionSetup.GetRecordOnce();

        FAConversion.TestField("Negative Adjmt. ILE Entry No.");
        FAConversion.TestField("Posting Date");

        Item.Get(FAConversion."Item No.");
        Item.TestField("FA Conv. Gen. Bus. Post. Group");

        if ServiceItemGroup.Get(Item."Service Item Group") and ServiceItemGroup."Create Service Item" then
            CreateServiceItemFromFAConversion(FAConversion);

        FAConversionSetup.GetRecordOnce();
        FAConversionSetup.TestField("Gen. Journal Template Name");
        FAConversionSetup.TestField("Gen. Journal Batch Name");

        ItemLedgerEntry.Get(FAConversion."Negative Adjmt. ILE Entry No.");
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");

        GeneralPostingSetup.Get(Item."FA Conv. Gen. Bus. Post. Group", Item."Gen. Prod. Posting Group");
        GeneralPostingSetup.TestField("Inventory Adjmt. Account");

        GenJournalLine.SetRange("Journal Template Name", FAConversionSetup."Gen. Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", FAConversionSetup."Gen. Journal Batch Name");
        GenJournalLine.DeleteAll(true);

        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := FAConversionSetup."Gen. Journal Template Name";
        GenJournalLine."Journal Batch Name" := FAConversionSetup."Gen. Journal Batch Name";
        GenJournalLine."Line No." := 10000;
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

        GlobalFAConversion := FAConversion;
        GenJournalLine.SendToPosting(Codeunit::"Gen. Jnl.-Post");

        OnAfterFAAcquisitionPosted(GlobalFAConversion);

        Clear(GlobalFAConversion);
    end;

    local procedure ApplyDepreciationProfile(Item: Record Item; FAConversion: Record "FA Conversion"; var FADepreciationBook: Record "FA Depreciation Book")
    var
        DepreciationProfile: Record "FA Depreciation Profile";
        LifeFormula: DateFormula;
        StartDate: Date;
        EndDate: Date;
        YearCount: Decimal;
        LifeFormulaTok: Label '%1Y', Locked = true, Comment = '%1 = number of depreciation years';
    begin
        StartDate := GetDepreciationStartDate(FAConversion);
        if StartDate = 0D then
            exit;

        // If Ömür Yılı is provided on the Item Card, copy it to the FA Depreciation Book and
        // explicitly compute the Depreciation Ending Date from the life-years formula below.
        if Item."FA Life Years INF" <> 0 then begin
            FADepreciationBook.Validate("Depreciation Starting Date", StartDate);
            FADepreciationBook.Validate("No. of Depreciation Years", Item."FA Life Years INF");

            // Make ending date explicit so the depreciation book shows the expected value.
            Evaluate(LifeFormula, StrSubstNo(LifeFormulaTok, Item."FA Life Years INF"));
            EndDate := CalcDate(LifeFormula, StartDate);
            if EndDate <> 0D then
                EndDate := EndDate - 1;
            if EndDate <> 0D then
                FADepreciationBook.Validate("Depreciation Ending Date", EndDate);

            FADepreciationBook.Modify(true);
            exit;
        end;

        if Item."FA Depr. Profile Code INF" = '' then
            exit;

        if not DepreciationProfile.Get(Item."FA Depr. Profile Code INF") then
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
    /// Creates a Service Item based on the FA Conversion data.
    /// </summary>
    /// <param name="FAConversion">The FA Conversion record to create Service Item from.</param>
    procedure CreateServiceItemFromFAConversion(FAConversion: Record "FA Conversion")
    var
        ServItem: Record "Service Item";
        ServMgtSetup: Record "Service Mgt. Setup";
        NoSeries: Codeunit "No. Series";
    begin
        ServItem.Init();
        ServMgtSetup.Get();
        ServMgtSetup.TestField("Service Item Nos.");
        ServItem."No. Series" := ServMgtSetup."Service Item Nos.";
        ServItem."No." := NoSeries.GetNextNo(ServItem."No. Series");
        ServItem.Insert(true);
        //ServItem.OmitAssignResSkills(true);
        ServItem.Validate("Item No.", FAConversion."Item No.");
        //ServItem.OmitAssignResSkills(false);
        ServItem."Variant Code" := FAConversion."Variant Code";
        ServItem.Validate("Serial No.", FAConversion."Serial No.");
        ServItem.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post", OnBeforeCode, '', false, false)]
    local procedure OnBeforeCode2(var GenJournalLine: Record "Gen. Journal Line"; var HideDialog: Boolean)
    begin
        HideDialog := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post", OnBeforeShowPostResultMessage, '', false, false)]
    local procedure OnBeforeShowPostResultMessage(var GenJnlLine: Record "Gen. Journal Line"; TempJnlBatchName: Code[10]; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Insert Ledger Entry", OnBeforeInsertRegister, '', false, false)]
    local procedure OnBeforeInsertRegister(var Sender: Codeunit "FA Insert Ledger Entry"; var FALedgerEntry: Record "FA Ledger Entry"; var FALedgerEntry2: Record "FA Ledger Entry"; var NextEntryNo: Integer)
    begin
        if GlobalFAConversion."Item No." = '' then
            exit;

        GlobalFAConversion."FA Acquisition Entry No." := FALedgerEntry."Entry No.";
        GlobalFAConversion.Modify(false);
    end;


    [EventSubscriber(ObjectType::Report, Report::"Adjust Cost - Item Entries", OnBeforePreReport, '', false, false)]
    local procedure OnBeforePreReport_AdjustCostItemEntries(var Sender: Report "Adjust Cost - Item Entries"; ItemNoFilter: Text[250];
                                                                            ItemCategoryFilter: Text[250];
                                                                            PostToGL: Boolean;

    var
        Item: Record Item)
    begin
        if GlobalFAConversion."Item No." = '' then
            exit;

        Item.Get(GlobalFAConversion."Item No.");
    end;

    [EventSubscriber(ObjectType::Report, Report::"Post Inventory Cost to G/L INF", OnBeforePreReport, '', false, false)]
    local procedure OnBeforePreReport(var Sender: Report "Post Inventory Cost to G/L INF";

    var
        Item: Record Item;

    var
        ItemValueEntry: Record "Value Entry";

    var
        PostValueEntryToGL: Record "Post Value Entry to G/L")
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
        Item.Get(TransferReceiptLine."Item No.");

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
        // auto-create toggle are both enabled in setup (NDIT-5968). Read fresh (not via
        // GetRecordOnce/the global setup var) so toggling the master switch takes effect
        // without recycling the session. When disabled, the user can still create the
        // transfer item manually via the Create FA Transfer Item action on the Fixed Asset
        // card (guarded by the same master switch).
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
    local procedure OnAfterInsertItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; var ItemLedgEntryNo: Integer; var ValueEntryNo: Integer; var ItemApplnEntryNo: Integer; GlobalValueEntry: Record "Value Entry"; TransferItem: Boolean; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L"; var OldItemLedgerEntry: Record "Item Ledger Entry")
    begin
        GlobalILENo := ItemLedgerEntry."Entry No.";
    end;



    local procedure GetDefaultLocationCode(): Code[10]
    var
        Location: Record Location;
        LocalFAConversionSetup: Record "FA Conversion Setup";
    begin
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
            FALocation.Code := LocationCode;
            FALocation.Name := LocationCode; // Use code as default name
            FALocation.Insert(true);
        end;
    end;


    [IntegrationEvent(false, false)]
    local procedure OnAfterFAAcquisitionPosted(var FAConversion: Record "FA Conversion")
    begin
    end;



    var
        FAConversionSetup: Record "FA Conversion Setup";
        GlobalFAConversion: Record "FA Conversion";
        GlobalILENo: Integer;
}
