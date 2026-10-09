namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.Inventory.Transfer;

/// <summary>
/// In-memory request buffer of the FA conversion: one row per selected posted transfer line with its received,
/// already converted, open and convertible quantities and the result of the conversion run. The rows live only
/// for the duration of one request; nothing is stored in the database.
/// </summary>
table 60013 "FA Conv. Source Line INF"
{
    Access = Public;
    Extensible = false;
    TableType = Temporary;
    Caption = 'FA Conversion Source Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AllowInCustomizations = Never;
        }
        field(2; "Source Document Type"; Enum "FA Conv. Source Doc. Type INF")
        {
            Caption = 'Source Document Type';
            AllowInCustomizations = Never;
        }
        field(3; "Source Document No."; Code[20])
        {
            Caption = 'Source Document No.';
            AllowInCustomizations = Never;
        }
        field(4; "Source Document Line No."; Integer)
        {
            Caption = 'Source Document Line No.';
            AllowInCustomizations = Never;
        }
        field(5; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            AllowInCustomizations = Never;
        }
        field(6; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            AllowInCustomizations = Never;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            AllowInCustomizations = Never;
        }
        field(8; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            AllowInCustomizations = Never;
        }
        field(9; "Serial Tracked"; Boolean)
        {
            Caption = 'Serial Tracked';
            AllowInCustomizations = Never;
        }
        field(10; "Received Quantity (Base)"; Decimal)
        {
            Caption = 'Received Quantity (Base)';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
            AllowInCustomizations = Never;
        }
        field(11; "Converted Quantity"; Integer)
        {
            Caption = 'Converted Quantity';
            AllowInCustomizations = Never;
        }
        field(12; "Open Inbound Quantity"; Decimal)
        {
            Caption = 'Open Inbound Quantity';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
            AllowInCustomizations = Never;
        }
        field(13; "Open Serial Count"; Integer)
        {
            Caption = 'Open Serial Count';
            AllowInCustomizations = Never;
        }
        field(14; "Convertible Quantity"; Integer)
        {
            Caption = 'Convertible Quantity';
            AllowInCustomizations = Never;
        }
        field(15; "Document Posting Date"; Date)
        {
            Caption = 'Document Posting Date';
            AllowInCustomizations = Never;
        }
        field(16; "Quantity to Convert"; Integer)
        {
            Caption = 'Quantity to Convert';
            AllowInCustomizations = Never;
        }
        field(17; "Converted This Run"; Integer)
        {
            Caption = 'Converted This Run';
            AllowInCustomizations = Never;
        }
        field(18; "Last FA Conversion No."; Code[20])
        {
            Caption = 'Last FA Conversion No.';
            AllowInCustomizations = Never;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Fills the current row from a posted transfer receipt line: the next entry number, the source document
    /// reference, the item, the variant, the description and the FA location (the transfer-to location of the
    /// line). Every other field gets its initial value. The row is not inserted; the caller inserts it.
    /// </summary>
    /// <param name="TransferReceiptLine">The posted transfer receipt line the row is built from.</param>
    procedure InitFromTransferReceiptLine(TransferReceiptLine: Record "Transfer Receipt Line")
    begin
        Init();
        "Entry No." := GetNextEntryNo();
        "Source Document Type" := "Source Document Type"::"Transfer Receipt";
        "Source Document No." := TransferReceiptLine."Document No.";
        "Source Document Line No." := TransferReceiptLine."Line No.";
        "Item No." := TransferReceiptLine."Item No.";
        "Variant Code" := TransferReceiptLine."Variant Code";
        Description := TransferReceiptLine.Description;
        "Location Code" := TransferReceiptLine."Transfer-to Code";
    end;

    /// <summary>
    /// Fills the current row from a posted direct transfer line: the next entry number, the source document
    /// reference, the item, the variant, the description and the FA location (the transfer-to location of the
    /// line). Every other field gets its initial value. The row is not inserted; the caller inserts it.
    /// </summary>
    /// <param name="DirectTransLine">The posted direct transfer line the row is built from.</param>
    procedure InitFromDirectTransLine(DirectTransLine: Record "Direct Trans. Line")
    begin
        Init();
        "Entry No." := GetNextEntryNo();
        "Source Document Type" := "Source Document Type"::"Direct Transfer";
        "Source Document No." := DirectTransLine."Document No.";
        "Source Document Line No." := DirectTransLine."Line No.";
        "Item No." := DirectTransLine."Item No.";
        "Variant Code" := DirectTransLine."Variant Code";
        Description := DirectTransLine.Description;
        "Location Code" := DirectTransLine."Transfer-to Code";
    end;

    /// <summary>
    /// Sets the posting date of the posted transfer document that the current row belongs to.
    /// </summary>
    /// <param name="DocumentPostingDate">The posting date of the posted document header; blank when the header is missing.</param>
    procedure SetDocumentPostingDate(DocumentPostingDate: Date)
    begin
        "Document Posting Date" := DocumentPostingDate;
    end;

    /// <summary>
    /// Sets the quantities of the current row and calculates its convertible quantity: the number of open serial
    /// numbers for a serial tracked line, otherwise the received base units that are neither converted yet nor
    /// consumed from inventory, rounded down to whole units.
    /// </summary>
    /// <param name="ReceivedBase">The received quantity of the line in base units.</param>
    /// <param name="Converted">The number of fixed assets already created from the line.</param>
    /// <param name="OpenInbound">The remaining quantity of the inbound item ledger entries of the line.</param>
    /// <param name="OpenSerials">The number of inbound entries of the line with a serial number and a remaining quantity.</param>
    /// <param name="SerialTracked">Whether the inbound entries of the line carry serial numbers.</param>
    procedure SetQuantities(ReceivedBase: Decimal; Converted: Integer; OpenInbound: Decimal; OpenSerials: Integer; SerialTracked: Boolean)
    begin
        "Serial Tracked" := SerialTracked;
        "Received Quantity (Base)" := ReceivedBase;
        "Converted Quantity" := Converted;
        "Open Inbound Quantity" := OpenInbound;
        "Open Serial Count" := OpenSerials;
        "Convertible Quantity" := CalculateConvertibleQuantity();
    end;

    /// <summary>
    /// Sets the number of units that the current request converts from the current row.
    /// </summary>
    /// <param name="QuantityToConvert">The number of units to convert from the line.</param>
    procedure SetQuantityToConvert(QuantityToConvert: Integer)
    begin
        "Quantity to Convert" := QuantityToConvert;
    end;

    /// <summary>
    /// Sets the result of the conversion run for the current row.
    /// </summary>
    /// <param name="ConvertedThisRun">The number of fixed assets created from the line in this run.</param>
    /// <param name="LastFAConversionNo">The number of the last FA Conversion created from the line in this run.</param>
    procedure SetResult(ConvertedThisRun: Integer; LastFAConversionNo: Code[20])
    begin
        "Converted This Run" := ConvertedThisRun;
        "Last FA Conversion No." := LastFAConversionNo;
    end;

    /// <summary>
    /// Returns the latest posting date of the posted documents of all rows, whatever filters are set on the record.
    /// </summary>
    /// <param name="LatestDocumentNo">Receives the document number of the first row (in entry number order) that carries the latest posting date; blank for an empty buffer.</param>
    /// <returns>The latest document posting date; blank for an empty buffer.</returns>
    procedure GetLatestDocumentPostingDate(var LatestDocumentNo: Code[20]): Date
    var
        TempAllRows: Record "FA Conv. Source Line INF" temporary;
        LatestPostingDate: Date;
    begin
        LatestDocumentNo := '';
        TempAllRows.Copy(Rec, true);
        TempAllRows.Reset();
        if TempAllRows.FindSet() then begin
            LatestPostingDate := TempAllRows."Document Posting Date";
            LatestDocumentNo := TempAllRows."Source Document No.";
            while TempAllRows.Next() <> 0 do
                if TempAllRows."Document Posting Date" > LatestPostingDate then begin
                    LatestPostingDate := TempAllRows."Document Posting Date";
                    LatestDocumentNo := TempAllRows."Source Document No.";
                end;
        end;

        exit(LatestPostingDate);
    end;

    /// <summary>
    /// Returns the entry number for a new row: one more than the highest entry number in the buffer, whatever
    /// filters are set on the record.
    /// </summary>
    /// <returns>The next free entry number; 1 for an empty buffer.</returns>
    local procedure GetNextEntryNo(): Integer
    var
        TempAllRows: Record "FA Conv. Source Line INF" temporary;
    begin
        TempAllRows.Copy(Rec, true);
        TempAllRows.Reset();
        if TempAllRows.FindLast() then
            exit(TempAllRows."Entry No." + 1);

        exit(1);
    end;

    /// <summary>
    /// Calculates the convertible quantity of the current row from its quantity fields.
    /// </summary>
    /// <returns>The number of units that can still be converted; never negative.</returns>
    local procedure CalculateConvertibleQuantity(): Integer
    var
        ConvertibleUnits: Decimal;
        OpenUnits: Decimal;
    begin
        if "Serial Tracked" then
            exit("Open Serial Count");

        ConvertibleUnits := Round("Received Quantity (Base)", 1, '<') - "Converted Quantity";
        OpenUnits := Round("Open Inbound Quantity", 1, '<');
        if OpenUnits < ConvertibleUnits then
            ConvertibleUnits := OpenUnits;
        if ConvertibleUnits < 0 then
            exit(0);

        exit(ConvertibleUnits);
    end;
}
