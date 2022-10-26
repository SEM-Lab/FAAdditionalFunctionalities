codeunit 60000 "FA Conversion Functions"
{
    SingleInstance = true;
    procedure CreateFAConversionFromItemCard(Item: Record Item)
    var
        FAConversion: Record "FA Conversion";
    begin
        Item.TestField("FA No. Series");
        Item.TestField("FA Conv. Gen. Bus. Post. Group");
        Item.TestField("FA Posting Group");

        FAConversion.Init();
        FAConversion.Insert(true);
        FAConversion.Validate("Item No.", Item."No.");
        FAConversion.Validate("Item Description", Item.Description);
        CreateFixedAsset(Item, FAConversion);
        FAConversion.Modify(true);

        Page.Run(Page::"FA Conversion", FAConversion);
    end;

    local procedure CreateFixedAsset(Item: Record Item; var FAConversion: Record "FA Conversion")
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    //FixedAssetCard: Page "Fixed Asset Card";
    begin
        FAConversionSetup.GetRecordOnce();
        FAConversionSetup.TestField("Depreciation Book Code");

        FixedAsset.Init();
        NoSeriesManagement.InitSeries(Item."FA No. Series", FixedAsset."No. Series", 0D, FixedAsset."No.", FixedAsset."No. Series");
        FixedAsset.Insert(true);
        FixedAsset.Validate(Description, Item.Description);
        FixedAsset.Modify(true);

        FADepreciationBook.Init();
        FADepreciationBook.Validate("FA No.", FixedAsset."No.");
        FADepreciationBook.Validate("Depreciation Book Code", FAConversionSetup."Depreciation Book Code");
        FADepreciationBook.Validate("FA Posting Group", Item."FA Posting Group");
        FADepreciationBook.Insert(true);

        FAConversion.Validate("FA No.", FixedAsset."No.");
        FAConversion.Validate("FA Description", FixedAsset.Description);
    end;

    procedure NegativeAdjustment(FAConversion: Record "FA Conversion")
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
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
        ItemJournalLine.Validate(Quantity, 1);
        ItemJournalLine.Validate("Location Code", FAConversion."Location Code");
        ItemJournalLine.Validate("Gen. Bus. Posting Group", Item."FA Conv. Gen. Bus. Post. Group");
        ItemJournalLine.Modify(true);

        Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJournalLine);

        FAConversion."Negative Adjmt. ILE Entry No." := GlobalILENo;
        FAConversion.Modify(true);

        GlobalFAConversion := FAConversion;
        AdjustAndPostInventoryCost(FAConversion);
        Clear(GlobalFAConversion);

    end;

    procedure AdjustAndPostInventoryCost(var FAConversion: Record "FA Conversion")
    begin


        Report.RunModal(Report::"Adjust Cost - Item Entries", false);

        Report.RunModal(Report::"Post Inventory Cost to G/L", false);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Adjust Cost - Item Entries", 'OnBeforePreReport', '', false, false)]
    local procedure OnBeforePreReport_AdjustCostItemEntries(var Sender: Report "Adjust Cost - Item Entries"; ItemNoFilter: Text[250]; ItemCategoryFilter: Text[250]; PostToGL: Boolean; var Item: Record Item);
    begin
        if GlobalFAConversion."Item No." = '' then
            exit;

        Item.Get(GlobalFAConversion."Item No.");
    end;

    [EventSubscriber(ObjectType::Report, Report::"Post Inventory Cost to G/L INF", 'OnBeforePreReport', '', false, false)]
    local procedure OnBeforePreReport(var Sender: Report "Post Inventory Cost to G/L INF"; var Item: Record Item; var ItemValueEntry: Record "Value Entry"; var PostValueEntryToGL: Record "Post Value Entry to G/L");
    var
        PostMethod: Option "per Posting Group","per Entry";
    begin
        if GlobalFAConversion."Item No." = '' then
            exit;

        Sender.InitializeRequest(PostMethod::"per Entry", '', true);
        PostValueEntryToGL.SetFilter("Item No.", GlobalFAConversion."Item No.");
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::NoSeriesManagement, 'OnAfterSetParametersBeforeRun', '', false, false)]
    local procedure OnAfterSetParametersBeforeRun(var TryNoSeriesCode: Code[20]; var TrySeriesDate: Date; var WarningNoSeriesCode: Code[20]);
    begin
        if not CommitRequired then
            exit;

        Commit();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInsertItemLedgEntry', '', false, false)]
    local procedure OnAfterInsertItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; var ItemLedgEntryNo: Integer; var ValueEntryNo: Integer; var ItemApplnEntryNo: Integer; GlobalValueEntry: Record "Value Entry"; TransferItem: Boolean; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L"; var OldItemLedgerEntry: Record "Item Ledger Entry");
    begin
        GlobalILENo := ItemLedgerEntry."Entry No.";
    end;

    var
        FAConversionSetup: Record "FA Conversion Setup";
        GlobalFAConversion: Record "FA Conversion";
        CommitRequired: Boolean;
        GlobalILENo: Integer;
}
