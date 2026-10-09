namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Transfer;
using System.Security.User;

/// <summary>
/// Request engine of the FA conversion. It collects the selected posted transfer lines into a request buffer,
/// asks for the acquisition date and the quantity, validates the request before anything is written, and then
/// converts the lines unit by unit through the posting procedures of the FA Conversion Functions codeunit. Each
/// unit is committed by the standard posting; the run stops at the first unit that fails and reports how far it got.
/// </summary>
codeunit 60015 "FA Conversion Request Mgt. INF"
{
    Access = Public;
    Permissions = tabledata "Direct Trans. Header" = r,
                  tabledata "Direct Trans. Line" = r,
                  tabledata "FA Conversion" = r,
                  tabledata "FA Conversion Setup" = r,
                  tabledata "FA Setup" = r,
                  tabledata "Fixed Asset" = r,
                  tabledata "General Ledger Setup" = r,
                  tabledata "Item Ledger Entry" = r,
                  tabledata "Transfer Receipt Header" = r,
                  tabledata "Transfer Receipt Line" = r,
                  tabledata "User Setup" = r;

    /// <summary>
    /// Converts posted transfer receipt lines to fixed assets after the user chose the acquisition date and the
    /// quantity in a dialog. Needs a user interface session. Nothing is written before the dialog was closed with
    /// OK and the request passed validation.
    /// </summary>
    /// <param name="TransferReceiptLine">The lines to convert, filtered or marked as the selection of the page action; an unfiltered record means every line.</param>
    procedure RunForTransferReceiptLines(var TransferReceiptLine: Record "Transfer Receipt Line")
    var
        TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary;
    begin
        CheckUserInterface();
        CollectTransferReceiptLines(TransferReceiptLine, TempFAConvSourceLine);
        RunRequest(TempFAConvSourceLine);
    end;

    /// <summary>
    /// Converts posted direct transfer lines to fixed assets after the user chose the acquisition date and the
    /// quantity in a dialog. Needs a user interface session. Nothing is written before the dialog was closed with
    /// OK and the request passed validation.
    /// </summary>
    /// <param name="DirectTransLine">The lines to convert, filtered or marked as the selection of the page action; an unfiltered record means every line.</param>
    procedure RunForDirectTransferLines(var DirectTransLine: Record "Direct Trans. Line")
    var
        TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary;
    begin
        CheckUserInterface();
        CollectDirectTransferLines(DirectTransLine, TempFAConvSourceLine);
        RunRequest(TempFAConvSourceLine);
    end;

    /// <summary>
    /// Replaces the content of the request buffer with one row per posted transfer receipt line of the record set,
    /// with the received, converted, open and convertible quantities of each line. Reads only; the filters and
    /// marks of the record are unchanged, its position and auto-calculated fields may change.
    /// </summary>
    /// <param name="TransferReceiptLine">The lines to collect, filtered or marked; an unfiltered record means every line.</param>
    /// <param name="TempFAConvSourceLine">Receives the request rows in the iteration order of the record.</param>
    procedure CollectTransferReceiptLines(var TransferReceiptLine: Record "Transfer Receipt Line"; var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary)
    begin
        TempFAConvSourceLine.Reset();
        TempFAConvSourceLine.DeleteAll(false);

        TransferReceiptLine.SetAutoCalcFields("FA Converted Qty. INF");
        if TransferReceiptLine.FindSet() then
            repeat
                TempFAConvSourceLine.InitFromTransferReceiptLine(TransferReceiptLine);
                TempFAConvSourceLine.SetDocumentPostingDate(GetTransferReceiptPostingDate(TransferReceiptLine."Document No."));
                RefreshQuantities(TempFAConvSourceLine, TransferReceiptLine."Quantity (Base)", TransferReceiptLine."FA Converted Qty. INF");
                TempFAConvSourceLine.Insert(false);
            until TransferReceiptLine.Next() = 0;
    end;

    /// <summary>
    /// Replaces the content of the request buffer with one row per posted direct transfer line of the record set,
    /// with the received, converted, open and convertible quantities of each line. Reads only; the filters and
    /// marks of the record are unchanged, its position and auto-calculated fields may change.
    /// </summary>
    /// <param name="DirectTransLine">The lines to collect, filtered or marked; an unfiltered record means every line.</param>
    /// <param name="TempFAConvSourceLine">Receives the request rows in the iteration order of the record.</param>
    procedure CollectDirectTransferLines(var DirectTransLine: Record "Direct Trans. Line"; var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary)
    begin
        TempFAConvSourceLine.Reset();
        TempFAConvSourceLine.DeleteAll(false);

        DirectTransLine.SetAutoCalcFields("FA Converted Qty. INF");
        if DirectTransLine.FindSet() then
            repeat
                TempFAConvSourceLine.InitFromDirectTransLine(DirectTransLine);
                TempFAConvSourceLine.SetDocumentPostingDate(GetDirectTransferPostingDate(DirectTransLine."Document No."));
                RefreshQuantities(TempFAConvSourceLine, DirectTransLine."Quantity (Base)", DirectTransLine."FA Converted Qty. INF");
                TempFAConvSourceLine.Insert(false);
            until DirectTransLine.Next() = 0;
    end;

    /// <summary>
    /// Validates a conversion request before anything is written: the buffer has rows, the acquisition date passes
    /// the date rules, and the quantity passes the quantity rules for every row. It resolves the number of units to
    /// convert from each row; while General Ledger Setup posts general journals with the job queue, the request may
    /// convert one unit only. The first violation raises an error.
    /// </summary>
    /// <param name="TempFAConvSourceLine">The request buffer filled by a Collect procedure; the quantity to convert of every row is set.</param>
    /// <param name="AcquisitionDate">The acquisition date chosen for the fixed assets.</param>
    /// <param name="QuantityMode">All converts every convertible unit of each row; Quantity converts the given quantity from each row.</param>
    /// <param name="QuantityPerLine">The quantity to convert from each row; only used in the mode Quantity.</param>
    procedure ValidateRequest(var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary; AcquisitionDate: Date; QuantityMode: Enum "FA Conv. Quantity Mode INF"; QuantityPerLine: Integer)
    var
        LatestDocumentNo: Code[20];
        LatestDocumentPostingDate: Date;
    begin
        if TempFAConvSourceLine.IsEmpty() then
            Error(NoLinesSelectedErr);

        LatestDocumentPostingDate := TempFAConvSourceLine.GetLatestDocumentPostingDate(LatestDocumentNo);
        ValidateAcquisitionDate(AcquisitionDate, LatestDocumentPostingDate, LatestDocumentNo);
        ValidateQuantity(TempFAConvSourceLine, QuantityMode, QuantityPerLine);
        SetQuantitiesToConvert(TempFAConvSourceLine, QuantityMode, QuantityPerLine);
        CheckOneUnitWithJobQueue(TempFAConvSourceLine);
    end;

    /// <summary>
    /// Converts the posted transfer receipt lines of the record set to fixed assets without any user interface:
    /// collects the lines, validates the request, and converts unit by unit. Each unit is committed by the standard
    /// posting. The run stops at the first unit that fails and raises an error that says how far it got.
    /// </summary>
    /// <param name="TransferReceiptLine">The lines to convert, filtered or marked.</param>
    /// <param name="AcquisitionDate">The acquisition date chosen for the fixed assets.</param>
    /// <param name="QuantityMode">All converts every convertible unit of each line; Quantity converts the given quantity from each line.</param>
    /// <param name="QuantityPerLine">The quantity to convert from each line; only used in the mode Quantity.</param>
    /// <returns>The number of fixed assets created.</returns>
    procedure ConvertTransferReceiptLines(var TransferReceiptLine: Record "Transfer Receipt Line"; AcquisitionDate: Date; QuantityMode: Enum "FA Conv. Quantity Mode INF"; QuantityPerLine: Integer): Integer
    var
        TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary;
    begin
        CollectTransferReceiptLines(TransferReceiptLine, TempFAConvSourceLine);
        ValidateRequest(TempFAConvSourceLine, AcquisitionDate, QuantityMode, QuantityPerLine);
        exit(ConvertBufferRows(TempFAConvSourceLine, AcquisitionDate));
    end;

    /// <summary>
    /// Converts the posted direct transfer lines of the record set to fixed assets without any user interface:
    /// collects the lines, validates the request, and converts unit by unit. Each unit is committed by the standard
    /// posting. The run stops at the first unit that fails and raises an error that says how far it got.
    /// </summary>
    /// <param name="DirectTransLine">The lines to convert, filtered or marked.</param>
    /// <param name="AcquisitionDate">The acquisition date chosen for the fixed assets.</param>
    /// <param name="QuantityMode">All converts every convertible unit of each line; Quantity converts the given quantity from each line.</param>
    /// <param name="QuantityPerLine">The quantity to convert from each line; only used in the mode Quantity.</param>
    /// <returns>The number of fixed assets created.</returns>
    procedure ConvertDirectTransferLines(var DirectTransLine: Record "Direct Trans. Line"; AcquisitionDate: Date; QuantityMode: Enum "FA Conv. Quantity Mode INF"; QuantityPerLine: Integer): Integer
    var
        TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary;
    begin
        CollectDirectTransferLines(DirectTransLine, TempFAConvSourceLine);
        ValidateRequest(TempFAConvSourceLine, AcquisitionDate, QuantityMode, QuantityPerLine);
        exit(ConvertBufferRows(TempFAConvSourceLine, AcquisitionDate));
    end;

    /// <summary>
    /// Checks the acquisition date against the rules for the posting dates: it has a value, lies in the allowed
    /// posting range and in the allowed FA posting range, lies in no closed inventory period, is not earlier than the
    /// posting date of the selected source documents, and is a valid VAT date (allowed VAT date range and VAT return
    /// period). The VAT date is checked last because in the warning modes of the VAT period control it asks the user
    /// to confirm; the question is asked only for a date that passes every other rule. The first violation raises an error.
    /// </summary>
    /// <param name="AcquisitionDate">The acquisition date to check.</param>
    /// <param name="EarliestAllowedDate">The latest posting date of the selected source documents; blank when unknown.</param>
    /// <param name="EarliestSourceDocumentNo">The number of the source document that has this posting date; blank when unknown.</param>
    internal procedure ValidateAcquisitionDate(AcquisitionDate: Date; EarliestAllowedDate: Date; EarliestSourceDocumentNo: Code[20])
    begin
        if AcquisitionDate = 0D then
            Error(AcquisitionDateRequiredErr);

        if not IsPostingDateAllowed(AcquisitionDate) then
            Error(NotInAllowedPostingRangeErr, AcquisitionDate);

        if not IsFAPostingDateAllowed(AcquisitionDate) then
            Error(NotInAllowedFAPostingRangeErr, AcquisitionDate);

        CheckInventoryPeriod(AcquisitionDate);

        if AcquisitionDate < EarliestAllowedDate then
            Error(BeforeSourceDocumentErr, AcquisitionDate, EarliestAllowedDate, EarliestSourceDocumentNo);

        // Last: it may ask a question (review finding F3)
        if not IsVATDateAllowed(AcquisitionDate) then
            Error(NotInAllowedVATDateRangeErr, AcquisitionDate);
    end;

    /// <summary>
    /// Checks the requested quantity against the convertible quantity of every row, in entry number order: in the
    /// mode Quantity it must be at least 1, and no row may have nothing left to convert or fewer convertible
    /// units than requested. The first violation raises an error.
    /// </summary>
    /// <param name="TempFAConvSourceLine">The request buffer filled by a Collect procedure.</param>
    /// <param name="QuantityMode">All converts every convertible unit of each row; Quantity converts the given quantity from each row.</param>
    /// <param name="QuantityPerLine">The quantity to convert from each row; only used in the mode Quantity.</param>
    internal procedure ValidateQuantity(var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary; QuantityMode: Enum "FA Conv. Quantity Mode INF"; QuantityPerLine: Integer)
    begin
        if (QuantityMode = QuantityMode::Quantity) and (QuantityPerLine < 1) then
            Error(QuantityMustBePositiveErr);

        if TempFAConvSourceLine.FindSet() then
            repeat
                ValidateRowQuantity(TempFAConvSourceLine, QuantityMode, QuantityPerLine);
            until TempFAConvSourceLine.Next() = 0;
    end;

    local procedure CheckUserInterface()
    begin
        if not GuiAllowed() then
            Error(UserInterfaceRequiredErr);
    end;

    local procedure RunRequest(var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary)
    var
        FAConversionRequest: Page "FA Conversion Request INF";
        QuantityMode: Enum "FA Conv. Quantity Mode INF";
        AcquisitionDate: Date;
        QuantityPerLine: Integer;
        ConvertedUnits: Integer;
    begin
        if TempFAConvSourceLine.IsEmpty() then
            Error(NoLinesSelectedErr);

        FAConversionRequest.SetSourceLines(TempFAConvSourceLine);
        if not (FAConversionRequest.RunModal() in [Action::OK, Action::LookupOK]) then
            exit;

        FAConversionRequest.GetRequest(AcquisitionDate, QuantityMode, QuantityPerLine);
        ValidateRequest(TempFAConvSourceLine, AcquisitionDate, QuantityMode, QuantityPerLine);
        ConvertedUnits := ConvertBufferRows(TempFAConvSourceLine, AcquisitionDate);
        Message(ConvertedMsg, ConvertedUnits, AcquisitionDate);
    end;

    local procedure GetTransferReceiptPostingDate(DocumentNo: Code[20]): Date
    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
    begin
        TransferReceiptHeader.SetLoadFields("Posting Date");
        if TransferReceiptHeader.Get(DocumentNo) then
            exit(TransferReceiptHeader."Posting Date");

        exit(0D);
    end;

    local procedure GetDirectTransferPostingDate(DocumentNo: Code[20]): Date
    var
        DirectTransHeader: Record "Direct Trans. Header";
    begin
        DirectTransHeader.SetLoadFields("Posting Date");
        if DirectTransHeader.Get(DocumentNo) then
            exit(DirectTransHeader."Posting Date");

        exit(0D);
    end;

    /// <summary>
    /// Sets the quantities of the current row from the inbound item ledger entries of its source line. Only the free part of
    /// an entry counts as open: its remaining quantity minus what is reserved from it (a sales or transfer order, for example),
    /// because a unit cannot be taken from reserved stock (review finding F2).
    /// </summary>
    /// <param name="TempFAConvSourceLine">The request row; its source document reference, item, variant and location must be set.</param>
    /// <param name="ReceivedBase">The received quantity of the source line in base units.</param>
    /// <param name="ConvertedQuantity">The number of fixed assets already created from the source line.</param>
    local procedure RefreshQuantities(var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary; ReceivedBase: Decimal; ConvertedQuantity: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        FreeQuantity: Decimal;
        OpenInboundQuantity: Decimal;
        OpenSerialCount: Integer;
        SerialTracked: Boolean;
    begin
        ItemLedgerEntry.SetLoadFields("Serial No.", "Remaining Quantity");
        ItemLedgerEntry.SetAutoCalcFields("Reserved Quantity");
        SetInboundEntryFilters(ItemLedgerEntry, TempFAConvSourceLine);
        if ItemLedgerEntry.FindSet() then
            repeat
                FreeQuantity := GetFreeQuantity(ItemLedgerEntry);
                OpenInboundQuantity += FreeQuantity;
                if ItemLedgerEntry."Serial No." <> '' then begin
                    SerialTracked := true;
                    if FreeQuantity >= 1 then
                        OpenSerialCount += 1;
                end;
            until ItemLedgerEntry.Next() = 0;

        TempFAConvSourceLine.SetQuantities(ReceivedBase, ConvertedQuantity, OpenInboundQuantity, OpenSerialCount, SerialTracked);
    end;

    // The part of an inbound entry that a unit can be taken from: its remaining quantity minus the quantity reserved from it
    // ("Reserved Quantity" must be calculated). The posting refuses to apply a unit to an entry whose remaining quantity is
    // reserved (Item Jnl.-Post Line, ReservationPreventsApplication).
    local procedure GetFreeQuantity(var ItemLedgerEntry: Record "Item Ledger Entry"): Decimal
    var
        FreeQuantity: Decimal;
    begin
        FreeQuantity := ItemLedgerEntry."Remaining Quantity" - ItemLedgerEntry."Reserved Quantity";
        if FreeQuantity < 0 then
            exit(0);

        exit(FreeQuantity);
    end;

    local procedure SetInboundEntryFilters(var ItemLedgerEntry: Record "Item Ledger Entry"; var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary)
    begin
        ItemLedgerEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");
        ItemLedgerEntry.SetRange("Document No.", TempFAConvSourceLine."Source Document No.");
        if TempFAConvSourceLine."Source Document Type" = TempFAConvSourceLine."Source Document Type"::"Direct Transfer" then
            ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Direct Transfer")
        else
            ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Transfer Receipt");
        ItemLedgerEntry.SetRange("Document Line No.", TempFAConvSourceLine."Source Document Line No.");
        ItemLedgerEntry.SetRange("Item No.", TempFAConvSourceLine."Item No.");
        ItemLedgerEntry.SetRange("Variant Code", TempFAConvSourceLine."Variant Code");
        ItemLedgerEntry.SetRange("Location Code", TempFAConvSourceLine."Location Code");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetRange(Positive, true);
    end;

    local procedure IsPostingDateAllowed(PostingDate: Date): Boolean
    var
        LocalFAConversionSetup: Record "FA Conversion Setup";
        UserSetupManagement: Codeunit "User Setup Management";
        TemplateName: Code[20];
    begin
        if LocalFAConversionSetup.Get() then
            TemplateName := LocalFAConversionSetup."Gen. Journal Template Name";

        exit(UserSetupManagement.IsPostingDateValidWithGenJnlTemplate(PostingDate, TemplateName));
    end;

    local procedure IsFAPostingDateAllowed(PostingDate: Date): Boolean
    var
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
    begin
        GetFAPostingRange(AllowPostingFrom, AllowPostingTo);
        exit((PostingDate >= AllowPostingFrom) and (PostingDate <= AllowPostingTo));
    end;

    // Replica of the check in FA Jnl.-Check Line (a local procedure of the base application): the FA posting range
    // of the user, otherwise the one of the FA setup; an open end means the end of the calendar.
    local procedure GetFAPostingRange(var AllowPostingFrom: Date; var AllowPostingTo: Date)
    var
        FASetup: Record "FA Setup";
    begin
        GetUserFAPostingRange(AllowPostingFrom, AllowPostingTo);
        if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then
            if FASetup.Get() then begin
                AllowPostingFrom := FASetup."Allow FA Posting From";
                AllowPostingTo := FASetup."Allow FA Posting To";
            end;

        if AllowPostingTo = 0D then
            AllowPostingTo := DMY2Date(31, 12, 9998);
    end;

    local procedure GetUserFAPostingRange(var AllowPostingFrom: Date; var AllowPostingTo: Date)
    var
        UserSetup: Record "User Setup";
    begin
        if UserId() = '' then
            exit;

        UserSetup.SetLoadFields("Allow FA Posting From", "Allow FA Posting To");
        if not UserSetup.Get(CopyStr(UserId(), 1, MaxStrLen(UserSetup."User ID"))) then
            exit;

        AllowPostingFrom := UserSetup."Allow FA Posting From";
        AllowPostingTo := UserSetup."Allow FA Posting To";
    end;

    // The FA acquisition is a purchase line of the general journal, so its posting checks the VAT date, which is the acquisition
    // date (Gen. Jnl.-Check Line.CheckVATDate): the allowed VAT date range of the user or of VAT Setup, and the VAT return
    // period under General Ledger Setup "Control VAT Period". That check runs only after the negative adjustment of the unit was
    // committed, so the same check runs here first (NDIT-6082, review). In the warning modes of the VAT period control it asks
    // the user to confirm, as the posting does; without a user interface the base application takes the default answer (yes).
    // The base application forgets the answer when a G/L posting finishes, so the posting of every unit's acquisition asks again.
    local procedure IsVATDateAllowed(VATDate: Date): Boolean
    var
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
    begin
        exit(VATReportingDateMgt.IsValidDate(VATDate));
    end;

    local procedure CheckInventoryPeriod(PostingDate: Date)
    var
        InventoryPeriod: Record "Inventory Period";
        ClosedPeriodEnd: Date;
    begin
        // IsValidDate overwrites its argument with the ending date of the closed period
        ClosedPeriodEnd := PostingDate;
        if not InventoryPeriod.IsValidDate(ClosedPeriodEnd) then
            InventoryPeriod.ShowError(ClosedPeriodEnd);
    end;

    local procedure ValidateRowQuantity(var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary; QuantityMode: Enum "FA Conv. Quantity Mode INF"; QuantityPerLine: Integer)
    begin
        if TempFAConvSourceLine."Convertible Quantity" < 1 then
            RaiseNothingToConvertError(TempFAConvSourceLine);

        if (QuantityMode = QuantityMode::Quantity) and (QuantityPerLine > TempFAConvSourceLine."Convertible Quantity") then
            Error(QuantityExceedsErr, QuantityPerLine, TempFAConvSourceLine."Convertible Quantity", TempFAConvSourceLine."Source Document No.", TempFAConvSourceLine."Source Document Line No.", TempFAConvSourceLine."Item No.");
    end;

    local procedure RaiseNothingToConvertError(var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary)
    begin
        Error(NothingToConvertErr, TempFAConvSourceLine."Source Document No.", TempFAConvSourceLine."Source Document Line No.", TempFAConvSourceLine."Item No.", TempFAConvSourceLine."Received Quantity (Base)", TempFAConvSourceLine."Converted Quantity", TempFAConvSourceLine."Open Inbound Quantity");
    end;

    local procedure SetQuantitiesToConvert(var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary; QuantityMode: Enum "FA Conv. Quantity Mode INF"; QuantityPerLine: Integer)
    begin
        if TempFAConvSourceLine.FindSet() then
            repeat
                if QuantityMode = QuantityMode::Quantity then
                    TempFAConvSourceLine.SetQuantityToConvert(QuantityPerLine)
                else
                    TempFAConvSourceLine.SetQuantityToConvert(TempFAConvSourceLine."Convertible Quantity");
                TempFAConvSourceLine.Modify(false);
            until TempFAConvSourceLine.Next() = 0;
    end;

    // With General Ledger Setup "Post with Job Queue" the acquisition of a unit is only scheduled: its journal line stays in the
    // journal batch of the FA Conversion Setup until the job queue has posted it. The acquisition of the next unit must empty that
    // batch first, which a scheduled line refuses, so a request of more than one unit would stop at its second unit. It is
    // refused before anything is written (NDIT-6082, review).
    local procedure CheckOneUnitWithJobQueue(var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        UnitsRequested: Integer;
    begin
        UnitsRequested := GetUnitsRequested(TempFAConvSourceLine);
        if UnitsRequested <= 1 then
            exit;

        // The setup field and table are named by their captions, so the message shows the names the user sees in the session
        // language (review finding F6)
        if IsPostWithJobQueue() then
            Error(OneUnitWithJobQueueErr, UnitsRequested, GeneralLedgerSetup.FieldCaption("Post with Job Queue"), GeneralLedgerSetup.TableCaption());
    end;

    local procedure ConvertBufferRows(var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary; AcquisitionDate: Date): Integer
    var
        TotalConverted: Integer;
        UnitsRequested: Integer;
    begin
        UnitsRequested := GetUnitsRequested(TempFAConvSourceLine);
        if TempFAConvSourceLine.FindSet() then
            repeat
                ConvertRow(TempFAConvSourceLine, AcquisitionDate, UnitsRequested, TotalConverted);
            until TempFAConvSourceLine.Next() = 0;

        exit(TotalConverted);
    end;

    local procedure GetUnitsRequested(var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary): Integer
    var
        UnitsRequested: Integer;
    begin
        if TempFAConvSourceLine.FindSet() then
            repeat
                UnitsRequested += TempFAConvSourceLine."Quantity to Convert";
            until TempFAConvSourceLine.Next() = 0;

        exit(UnitsRequested);
    end;

    // Converts the requested units of the current row one at a time. The first unit that fails ends the whole
    // request: the units before it stay (the standard posting committed them), the error rolls back the rest.
    local procedure ConvertRow(var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary; AcquisitionDate: Date; UnitsRequested: Integer; var TotalConverted: Integer)
    var
        RowConverted: Integer;
    begin
        LastFAConversionNo := '';
        RowConverted := 0;
        while RowConverted < TempFAConvSourceLine."Quantity to Convert" do begin
            ResetUnitState();
            ClearLastError();
            if not TryConvertUnit(TempFAConvSourceLine, AcquisitionDate) then
                RaiseStopError(TempFAConvSourceLine, TotalConverted, UnitsRequested, GetLastErrorText());

            RowConverted += 1;
            TotalConverted += 1;
        end;

        TempFAConvSourceLine.SetResult(RowConverted, LastFAConversionNo);
        TempFAConvSourceLine.Modify(false);
    end;

    local procedure ResetUnitState()
    begin
        CurrentStepName := '';
        CurrentFANo := '';
        TransferItemStepStarted := false;
    end;

    [TryFunction]
    local procedure TryConvertUnit(var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary; AcquisitionDate: Date)
    var
        FAConversion: Record "FA Conversion";
        SerialNo: Code[50];
        SourceEntryNo: Integer;
        AppliesToEntryNo: Integer;
    begin
        CurrentStepName := AvailabilityCheckStepLbl;
        CheckAvailability(TempFAConvSourceLine);
        SourceEntryNo := GetSourceEntryOfUnit(TempFAConvSourceLine, SerialNo, AppliesToEntryNo);

        CurrentStepName := CreateStepLbl;
        FAConversionFunctions.CreateFAConversionFromSourceLine(TempFAConvSourceLine, SerialNo, AcquisitionDate, FAConversion);
        CurrentFANo := FAConversion."FA No.";

        CurrentStepName := NegativeAdjustmentStepLbl;
        FAConversionFunctions.NegativeAdjustmentFromEntry(FAConversion, AppliesToEntryNo, SourceEntryNo);

        CurrentStepName := FAAcquisitionStepLbl;
        FAConversionFunctions.FAAcquisition(FAConversion);
        CheckAcquisitionPosted(FAConversion."No.", FAConversion."FA No.");

        CreateTransferItem(FAConversion."FA No.");
        LastFAConversionNo := FAConversion."No.";
    end;

    // Step 0: the posting of the previous unit committed, so the converted count and the open quantities are read
    // again; a unit whose line has nothing left is refused before anything is created.
    local procedure CheckAvailability(var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary)
    begin
        RefreshQuantities(TempFAConvSourceLine, TempFAConvSourceLine."Received Quantity (Base)", GetConvertedQuantity(TempFAConvSourceLine));
        TempFAConvSourceLine.Modify(false);
        if TempFAConvSourceLine."Convertible Quantity" < 1 then
            RaiseNothingToConvertError(TempFAConvSourceLine);
    end;

    local procedure GetConvertedQuantity(var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary): Integer
    var
        FAConversion: Record "FA Conversion";
    begin
        FAConversion.SetCurrentKey("Source Document Type", "Source Document No.", "Source Document Line No.");
        FAConversion.SetRange("Source Document Type", TempFAConvSourceLine."Source Document Type");
        FAConversion.SetRange("Source Document No.", TempFAConvSourceLine."Source Document No.");
        FAConversion.SetRange("Source Document Line No.", TempFAConvSourceLine."Source Document Line No.");
        exit(FAConversion.Count());
    end;

    // The inbound entry of the line a unit is taken from: the entry with the lowest entry number that still has a free quantity
    // (remaining minus reserved) of at least one unit, for a serial-tracked line the lowest such one with a serial number (the open
    // serial pick); reserved stock is skipped (review finding F2). The unit carries the cost of that entry (NDIT-6082, D27; review
    // finding F1: a serial number too, not the cost of the first open entry at the location). A unit without a serial number is
    // also applied to it (Applies-to Entry): without that the negative adjustment would apply by the costing method to any open
    // entry of the item at the location (FIFO: the oldest), and a unit counted on this line would use up the stock of another
    // received line, which then has nothing left to convert (NDIT-6082, review). A serial number is applied through its own item
    // tracking, and an entry with other item tracking can only be applied through its tracking, so neither gets an entry to apply
    // to. Returns 0 (and a blank serial number) when the line has no such entry.
    local procedure GetSourceEntryOfUnit(var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary; var SerialNo: Code[50]; var AppliesToEntryNo: Integer): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        SerialNo := '';
        AppliesToEntryNo := 0;

        ItemLedgerEntry.SetLoadFields("Serial No.", "Lot No.", "Package No.", "Remaining Quantity");
        ItemLedgerEntry.SetAutoCalcFields("Reserved Quantity");
        SetInboundEntryFilters(ItemLedgerEntry, TempFAConvSourceLine);
        if TempFAConvSourceLine."Serial Tracked" then
            ItemLedgerEntry.SetFilter("Serial No.", '<>%1', '');
        ItemLedgerEntry.SetFilter("Remaining Quantity", '>0');
        if not FindFreeEntry(ItemLedgerEntry) then
            exit(0);

        if TempFAConvSourceLine."Serial Tracked" then
            SerialNo := ItemLedgerEntry."Serial No."
        else
            if not ItemLedgerEntry.TrackingExists() then
                AppliesToEntryNo := ItemLedgerEntry."Entry No.";

        exit(ItemLedgerEntry."Entry No.");
    end;

    // Positions the filtered entries (with "Reserved Quantity" calculated) on the first one in entry number order that has a free
    // quantity of at least one unit.
    local procedure FindFreeEntry(var ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    begin
        if ItemLedgerEntry.FindSet() then
            repeat
                if GetFreeQuantity(ItemLedgerEntry) >= 1 then
                    exit(true);
            until ItemLedgerEntry.Next() = 0;

        exit(false);
    end;

    // FA Conversion Functions.FAAcquisition raises when the posting leaves no new acquisition cost entry (NDIT-6082,
    // D2). This second line of defence reads the conversion again from the database: without an FA acquisition
    // entry the unit did not reach the fixed asset ledger, so it must not go on to the transfer item. With General
    // Ledger Setup "Post with Job Queue" the journal is only enqueued and nothing is posted when this runs, so
    // there is nothing to verify (the same rule as the acquisition check of FA Conversion Functions, NDIT-6082, D20).
    local procedure CheckAcquisitionPosted(FAConversionNo: Code[20]; FANo: Code[20])
    var
        PostedFAConversion: Record "FA Conversion";
    begin
        if IsPostWithJobQueue() then
            exit;

        PostedFAConversion.SetLoadFields("FA Acquisition Entry No.");
        if PostedFAConversion.Get(FAConversionNo) then
            if PostedFAConversion."FA Acquisition Entry No." <> 0 then
                exit;

        Error(FAAcquisitionNotPostedErr, FAConversionNo, FANo);
    end;

    // Gen. Jnl.-Post decides between posting at once and enqueueing the journal from General Ledger Setup
    // "Post with Job Queue" alone; a missing setup counts as posting at once (the posting then raises its own error).
    local procedure IsPostWithJobQueue(): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.SetLoadFields("Post with Job Queue");
        if not GeneralLedgerSetup.Get() then
            exit(false);

        exit(GeneralLedgerSetup."Post with Job Queue");
    end;

    // Step 4: the transfer item is created only when FA transfer and its automatic creation are switched on. The
    // setup is read fresh, like in the conversion of a single receipt line, so a switch takes effect at once.
    local procedure CreateTransferItem(FANo: Code[20])
    var
        FixedAsset: Record "Fixed Asset";
        LocalFAConversionSetup: Record "FA Conversion Setup";
    begin
        if not LocalFAConversionSetup.Get() then
            exit;

        if not (LocalFAConversionSetup."Enable FA Transfer" and LocalFAConversionSetup."Auto Create FA Transfer Item") then
            exit;

        CurrentStepName := FATransferItemStepLbl;
        TransferItemStepStarted := true;
        if not FixedAsset.Get(FANo) then
            Error(FixedAssetNotFoundErr, FANo);

        FATransferFunctions.NewItemForTransfer(FixedAsset);
    end;

    local procedure RaiseStopError(var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary; CompletedUnits: Integer; UnitsRequested: Integer; ErrorText: Text)
    begin
        if TransferItemStepStarted then
            Error(FAConversionStoppedPostedErr, CompletedUnits, UnitsRequested, CompletedUnits + 1, TempFAConvSourceLine."Source Document No.", TempFAConvSourceLine."Source Document Line No.", TempFAConvSourceLine."Item No.", CurrentStepName, ErrorText, CurrentFANo);

        Error(FAConversionStoppedErr, CompletedUnits, UnitsRequested, CompletedUnits + 1, TempFAConvSourceLine."Source Document No.", TempFAConvSourceLine."Source Document Line No.", TempFAConvSourceLine."Item No.", CurrentStepName, ErrorText);
    end;

    var
        FAConversionFunctions: Codeunit "FA Conversion Functions";
        FATransferFunctions: Codeunit "FA Transfer Functions";
        LastFAConversionNo: Code[20];
        CurrentFANo: Code[20];
        CurrentStepName: Text;
        TransferItemStepStarted: Boolean;
        UserInterfaceRequiredErr: Label 'This action requires a user interface session.';
        NoLinesSelectedErr: Label 'No lines are selected.';
        AcquisitionDateRequiredErr: Label 'Acquisition Date must have a value.';
        NotInAllowedPostingRangeErr: Label 'Acquisition date %1 is not within the allowed posting date range.', Comment = '%1 = acquisition date';
        NotInAllowedFAPostingRangeErr: Label 'Acquisition date %1 is not within the allowed FA posting date range.', Comment = '%1 = acquisition date';
        NotInAllowedVATDateRangeErr: Label 'Acquisition date %1 cannot be the VAT date of the FA acquisition: it is not within the allowed VAT date range, or its VAT return period does not allow posting.', Comment = '%1 = acquisition date';
        BeforeSourceDocumentErr: Label 'Acquisition date %1 cannot be earlier than the posting date %2 of document %3.', Comment = '%1 = acquisition date, %2 = posting date of the source document, %3 = source document no.';
        QuantityMustBePositiveErr: Label 'Quantity to convert must be at least 1.';
        QuantityExceedsErr: Label 'Quantity to convert (%1) exceeds the convertible quantity (%2) of %3 %4 (item %5).', Comment = '%1 = quantity per line, %2 = convertible quantity, %3 = source document no., %4 = source document line no., %5 = item no.';
        OneUnitWithJobQueueErr: Label '%1 units were requested, but only one unit can be converted per request while general journals are posted with the job queue (%2 in %3). Convert one unit, and the next one after the job queue has posted its FA acquisition.', Comment = '%1 = number of units requested, %2 = caption of the field Post with Job Queue, %3 = caption of the table General Ledger Setup';
        NothingToConvertErr: Label '%1 %2 (item %3) has no convertible units: received %4, already converted %5, open in inventory and not reserved %6.', Comment = '%1 = source document no., %2 = source document line no., %3 = item no., %4 = received quantity (base), %5 = already converted quantity, %6 = open inbound quantity that is not reserved';
        FAConversionStoppedErr: Label 'FA conversion stopped after %1 of %2 unit(s). Unit %3 (%4 %5, item %6) failed in step "%7": %8', Comment = '%1 = completed units, %2 = requested units, %3 = ordinal of the failing unit, %4 = source document no., %5 = source document line no., %6 = item no., %7 = step name, %8 = error text';
        FAConversionStoppedPostedErr: Label 'FA conversion stopped after %1 of %2 unit(s). Unit %3 (%4 %5, item %6) failed in step "%7": %8 The fixed asset %9 was already created and posted; create its transfer item from the Fixed Asset card.', Comment = '%1 = completed units, %2 = requested units, %3 = ordinal of the failing unit, %4 = source document no., %5 = source document line no., %6 = item no., %7 = step name, %8 = error text, %9 = fixed asset no.';
        FixedAssetNotFoundErr: Label 'Fixed asset %1 does not exist.', Comment = '%1 = fixed asset no.';
        FAAcquisitionNotPostedErr: Label 'The FA acquisition of FA conversion %1 (fixed asset %2) was not posted. Its general journal line is still in the journal batch of the FA Conversion Setup; post it there to see the cause.', Comment = '%1 = FA conversion no., %2 = fixed asset no.';
        AvailabilityCheckStepLbl: Label 'Availability Check';
        CreateStepLbl: Label 'Create';
        NegativeAdjustmentStepLbl: Label 'Negative Adjustment';
        FAAcquisitionStepLbl: Label 'FA Acquisition';
        FATransferItemStepLbl: Label 'FA Transfer Item';
        ConvertedMsg: Label '%1 fixed asset(s) were created with acquisition date %2.', Comment = '%1 = number of fixed assets created, %2 = acquisition date';
}
