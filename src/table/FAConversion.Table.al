namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;

/// <summary>
/// One item-to-fixed-asset conversion: the source item/variant and serial number, the created Fixed
/// Asset, and the entry numbers of the posted negative adjustment and FA acquisition.
/// </summary>
table 60001 "FA Conversion"
{
    DataClassification = CustomerContent;
    Caption = 'FA Conversion';
    DrillDownPageId = "FA Conversion List";
    LookupPageId = "FA Conversion List";
    Access = Public;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the value of the No. field.';
            trigger OnValidate()
            var
                FAConversionSetup: Record "FA Conversion Setup";
                //NoSeries: Codeunit NoSeriesManagement;
                NoSeries: Codeunit "No. Series";
            begin
                if "No." <> xRec."No." then begin
                    FAConversionSetup.GetRecordOnce();
                    NoSeries.TestManual(FAConversionSetup."FA Conversion No. Series");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the value of the Item No. field.';
        }
        field(3; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
            ToolTip = 'Specifies the value of the Item Description field.';
        }
        field(4; "FA No."; Code[20])
        {
            Caption = 'FA No.';
            ToolTip = 'Specifies the value of the FA No. field.';
        }
        field(5; "FA Description"; Text[100])
        {
            Caption = 'FA Description';
            ToolTip = 'Specifies the value of the FA Description field.';
        }
        field(6; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the value of the Location Code field.';
            TableRelation = Location.Code;
        }
        field(7; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            ToolTip = 'Specifies the value of the Serial No. field.';
            TableRelation = "Item Ledger Entry"."Serial No." where("Item No." = field("Item No."), Open = const(true), "Location Code" = field("Location Code"), "Variant Code" = field("Variant Code"));
            ValidateTableRelation = false;
        }
        field(8; "Negative Adjmt. ILE Entry No."; Integer)
        {
            Caption = 'Negative Adjustment ILE Entry No.';
            ToolTip = 'Specifies the value of the Negative Adjustment ILE Entry No. field.';
            Editable = false;
        }
        field(9; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the acquisition date used as the posting date of the negative adjustment and of the FA acquisition; depreciation starts on 1 January of its year.';

            trigger OnValidate()
            var
                FAConversionFunctions: Codeunit "FA Conversion Functions";
            begin
                if ("FA No." <> '') and ("Negative Adjmt. ILE Entry No." = 0) and ("FA Acquisition Entry No." = 0) then
                    FAConversionFunctions.RecalculateDepreciationDates(Rec);
            end;
        }
        field(10; "FA Acquisition Entry No."; Integer)
        {
            Caption = 'FA Acquisition Entry No.';
            ToolTip = 'Specifies the value of the FA Acquisition Entry No. field.';
            Editable = false;
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the value of the Variant Code field.';
            Editable = false;
        }
        field(12; "E-Book Description INF"; Text[100])
        {
            Caption = 'E-Book Description';
            ToolTip = 'Specifies the value of the E-Book Description field.';
        }
        // field(13; "GIB Document Desc. INF"; Text[100])
        // {
        //     Caption = 'GIB Document Desc.';
        //     ToolTip = 'Specifies the value of the GIB Document Desc. field.';
        // }
        // field(14; "GIB Document Type INF"; Enum "GIB Document Type INF")
        // {
        //     Caption = 'GIB Document Type';
        //     ToolTip = 'Specifies the value of the GIB Document Type field.';
        // }
        field(20; "Source Document Type"; Enum "FA Conv. Source Doc. Type INF")
        {
            Caption = 'Source Document Type';
            ToolTip = 'Specifies the type of the posted transfer document that the item was converted from.';
            Editable = false;
        }
        field(21; "Source Document No."; Code[20])
        {
            Caption = 'Source Document No.';
            ToolTip = 'Specifies the number of the posted transfer document that the item was converted from.';
            Editable = false;
            TableRelation = if ("Source Document Type" = const("Transfer Receipt")) "Transfer Receipt Header"."No."
            else
            if ("Source Document Type" = const("Direct Transfer")) "Direct Trans. Header"."No.";
        }
        field(22; "Source Document Line No."; Integer)
        {
            Caption = 'Source Document Line No.';
            ToolTip = 'Specifies the line number of the posted transfer document that the item was converted from.';
            Editable = false;
        }
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            ToolTip = 'Specifies the value of the No. Series field.';
            TableRelation = "No. Series";
            AllowInCustomizations = Never;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(SourceDoc; "Source Document Type", "Source Document No.", "Source Document Line No.")
        {
        }
    }

    trigger OnInsert()
    var
        //FAConversionSetup: Record "FA Conversion Setup";
        //NoSeries: Codeunit NoSeriesManagement;
        NoSeries: Codeunit "No. Series";
    begin
        FAConversionSetup.GetRecordOnce();

        if "No." = '' then begin
            //FAConversionSetup.Get();
            FAConversionSetup.TestField("FA Conversion No. Series");
            //NoSeriesManagement.InitSeries(FAConversionSetup."FA Conversion No. Series", xRec."No. Series", 0D, "No.", "No. Series");
            Rec.Validate("No. Series", FAConversionSetup."FA Conversion No. Series");
            // Direct assignment on purpose: the field OnValidate (TestManual) must not run for series-assigned numbers.
            "No." := NoSeries.GetNextNo(FAConversionSetup."FA Conversion No. Series", WorkDate());
        end;

        // Default to the operation day. Kept intentionally consistent with the transfer-receipt
        // conversion flow (see FA Conversion Functions.CreateFAConversionFromTransferReceiptLine, NDIT-5968).
        "Posting Date" := WorkDate();
        Rec.Validate("E-Book Description INF", FAConversionSetup."E-Book Description INF");
    end;

    trigger OnDelete()
    var
        CannotDeletePostedConversionErr: Label 'Cannot delete FA Conversion %1 because it has already been posted. Reverse the related entries first.', Comment = '%1 = FA Conversion No.';
    begin
        if (Rec."Negative Adjmt. ILE Entry No." <> 0) or (Rec."FA Acquisition Entry No." <> 0) then
            Error(CannotDeletePostedConversionErr, Rec."No.");
    end;

    var
        FAConversionSetup: Record "FA Conversion Setup";
}
