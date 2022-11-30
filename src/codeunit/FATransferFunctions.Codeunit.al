codeunit 60001 "FA Transfer Functions"
{
    SingleInstance = true;
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
        Resource.Validate("No.", FixedAsset."No.");
        Resource.Insert(true);
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
        AlreadyCreatedErr: Label 'FA Transfer Item has been already created.';
    begin
        ItemLedgerEntry.SetRange("Serial No.", FixedAsset."No.");
        if not ItemLedgerEntry.IsEmpty then
            Error(AlreadyCreatedErr);

        FAConversionSetup.GetRecordOnce();
        FAConversionSetup.TestField("FA Transfer Item No.");
        FAConversionSetup.TestField("FA Trans. Pos. Adjmt. Loc.");

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
        ItemJournalLine.Validate("Location Code", FAConversionSetup."FA Trans. Pos. Adjmt. Loc.");
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
        TempReservationEntry.Insert();

        CreateReservEntry.CreateReservEntryFor(
          Database::"Item Journal Line", ItemJournalLine."Entry Type".AsInteger(),
          ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", 0, ItemJournalLine."Line No.", ItemJournalLine."Qty. per Unit of Measure",
          TempReservationEntry.Quantity, TempReservationEntry.Quantity * ItemJournalLine."Qty. per Unit of Measure", TempReservationEntry);
        CreateReservEntry.CreateEntry(
          ItemJournalLine."Item No.", ItemJournalLine."Variant Code", ItemJournalLine."Location Code", '', 0D, 0D, 0, ReservStatus::Surplus);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::NoSeriesManagement, 'OnAfterSetParametersBeforeRun', '', false, false)]
    local procedure OnAfterSetParametersBeforeRun(var TryNoSeriesCode: Code[20]; var TrySeriesDate: Date; var WarningNoSeriesCode: Code[20]);
    begin
        if not CommitRequired then
            exit;

        Commit();
    end;

    var
        FAConversionSetup: Record "FA Conversion Setup";
        CommitRequired: Boolean;
}
