codeunit 60000 "FA Conversion Functions"
{
    SingleInstance = true;
    Access = Public;
    procedure CreateFAConversionFromItemCard(Item: Record Item)
    var
        FAConversion: Record "FA Conversion";
    begin
        Item.TestField("FA No. Series");
        Item.TestField("FA Conv. Gen. Bus. Post. Group");
        Item.TestField("FA Posting Group");
        Item.TestField("FA Subclass Code");

        FAConversion.Init();
        FAConversion.Insert(true);
        FAConversion.Validate("Item No.", Item."No.");
        FAConversion.Validate("Item Description", Item.Description);
        CreateFixedAsset(Item, FAConversion);
        FAConversion.Modify(true);

        Page.Run(Page::"FA Conversion", FAConversion);
    end;

    procedure CreateFAConversionFromItemVariant(ItemVariant: Record "Item Variant"; ShowPageAfterCreation: Boolean; LocationCode: Code[10])
    var
        FAConversion: Record "FA Conversion";
        Item: Record Item;
    begin
        Item.Get(ItemVariant."Item No.");

        Item.TestField("FA No. Series");
        Item.TestField("FA Conv. Gen. Bus. Post. Group");
        Item.TestField("FA Posting Group");

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
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        FAConversionSetup.GetRecordOnce();
        FAConversionSetup.TestField("Depreciation Book Code");

        FixedAsset.Init();
        NoSeriesManagement.InitSeries(Item."FA No. Series", FixedAsset."No. Series", 0D, FixedAsset."No.", FixedAsset."No. Series");
        FixedAsset.Insert(true);
        FixedAsset.Validate(Description, FAConversion."Item Description");
        FixedAsset.Validate("Serial No.", FAConversion."Serial No.");
        FixedAsset.Validate("FA Subclass Code", Item."FA Subclass Code");
        FixedAsset.Modify(true);

        FADepreciationBook.Init();
        FADepreciationBook.Validate("FA No.", FixedAsset."No.");
        FADepreciationBook.Validate("Depreciation Book Code", FAConversionSetup."Depreciation Book Code");
        FADepreciationBook.Validate("FA Posting Group", Item."FA Posting Group");
        FADepreciationBook.Insert(true);

        FAConversion.Validate("FA No.", FixedAsset."No.");
        FAConversion.Validate("FA Description", FixedAsset.Description);
    end;

    procedure NegativeAdjustment(var FAConversion: Record "FA Conversion"; SkipCosting: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        FixedAsset: Record "Fixed Asset";
    begin
        FAConversion.TestField("Location Code");
        FAConversion.TestField("Posting Date");

        Item.Get(FAConversion."Item No.");

        FAConversionSetup.GetRecordOnce();
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

        Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJournalLine);

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

    procedure GetUnitCostFromItemJnlLine(var ItemJournalLine: Record "Item Journal Line"): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetAutoCalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetRange("Location Code", ItemJournalLine."Location Code");
        ItemLedgerEntry.SetRange("Item No.", ItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Variant Code", ItemJournalLine."Variant Code");
        if ItemLedgerEntry.FindFirst() then
            if ItemLedgerEntry."Cost Amount (Actual)" <> 0 then
                exit(ItemLedgerEntry."Cost Amount (Actual)" / ItemLedgerEntry.Quantity);

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

    procedure FAAcquisition(var FAConversion: Record "FA Conversion")
    var
        GenJournalLine: Record "Gen. Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        FAConversion.TestField("Negative Adjmt. ILE Entry No.");
        FAConversion.TestField("Posting Date");

        Item.Get(FAConversion."Item No.");
        Item.TestField("FA Conv. Gen. Bus. Post. Group");

        FAConversionSetup.GetRecordOnce();
        FAConversionSetup.TestField("Gen. Journal Template Name");
        FAConversionSetup.TestField("Gen. Journal Batch Name");

        ItemLedgerEntry.Get(FAConversion."Negative Adjmt. ILE Entry No.");
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");

        GeneralPostingSetup.Get(Item."FA Conv. Gen. Bus. Post. Group", Item."Gen. Prod. Posting Group");
        GeneralPostingSetup.TestField("Inventory Adjmt. Account");

        CommitRequired := true;
        GenJournalLine.SetRange("Journal Template Name", FAConversionSetup."Gen. Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", FAConversionSetup."Gen. Journal Batch Name");
        GenJournalLine.DeleteAll(true);

        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := FAConversionSetup."Gen. Journal Template Name";
        GenJournalLine."Journal Batch Name" := FAConversionSetup."Gen. Journal Batch Name";
        GenJournalLine."Line No." := 10000;
        GenJournalLine.SetUpNewLine(GenJournalLine, 0, true);
        CommitRequired := false;
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
        GenJournalLine.Modify(true);

        GlobalFAConversion := FAConversion;
        GenJournalLine.SendToPosting(Codeunit::"Gen. Jnl.-Post");
        Clear(GlobalFAConversion);
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
    local procedure OnBeforePreReport_AdjustCostItemEntries(var Sender: Report "Adjust Cost - Item Entries"; ItemNoFilter: Text[250]; ItemCategoryFilter: Text[250]; PostToGL: Boolean; var Item: Record Item)
    begin
        if GlobalFAConversion."Item No." = '' then
            exit;

        Item.Get(GlobalFAConversion."Item No.");
    end;

    [EventSubscriber(ObjectType::Report, Report::"Post Inventory Cost to G/L INF", OnBeforePreReport, '', false, false)]
    local procedure OnBeforePreReport(var Sender: Report "Post Inventory Cost to G/L INF"; var Item: Record Item; var ItemValueEntry: Record "Value Entry"; var PostValueEntryToGL: Record "Post Value Entry to G/L")
    var
        PostMethod: Option "per Posting Group","per Entry";
    begin
        if GlobalFAConversion."Item No." = '' then
            exit;

        Sender.InitializeRequest(PostMethod::"per Entry", '', true);
        PostValueEntryToGL.SetFilter("Item No.", GlobalFAConversion."Item No.");
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::NoSeriesManagement, OnAfterSetParametersBeforeRun, '', false, false)]
    local procedure OnAfterSetParametersBeforeRun(var TryNoSeriesCode: Code[20]; var TrySeriesDate: Date; var WarningNoSeriesCode: Code[20])
    begin
        if not CommitRequired then
            exit;

        Commit();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", OnAfterInsertItemLedgEntry, '', false, false)]
    local procedure OnAfterInsertItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; var ItemLedgEntryNo: Integer; var ValueEntryNo: Integer; var ItemApplnEntryNo: Integer; GlobalValueEntry: Record "Value Entry"; TransferItem: Boolean; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L"; var OldItemLedgerEntry: Record "Item Ledger Entry")
    begin
        GlobalILENo := ItemLedgerEntry."Entry No.";
    end;

    var
        FAConversionSetup: Record "FA Conversion Setup";
        GlobalFAConversion: Record "FA Conversion";
        CommitRequired: Boolean;
        GlobalILENo: Integer;
}
