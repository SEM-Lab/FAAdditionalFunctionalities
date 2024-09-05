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
                    FAConversionSetup.Get();
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
            ToolTip = 'Specifies the value of the Posting Date field.';
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
    }

    trigger OnInsert()
    var
        FAConversionSetup: Record "FA Conversion Setup";
        //NoSeries: Codeunit NoSeriesManagement;
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            FAConversionSetup.Get();
            FAConversionSetup.TestField("FA Conversion No. Series");
            //NoSeriesManagement.InitSeries(FAConversionSetup."FA Conversion No. Series", xRec."No. Series", 0D, "No.", "No. Series");
            Rec."No. Series" := FAConversionSetup."FA Conversion No. Series";
            Rec."No." := NoSeries.GetNextNo(FAConversionSetup."FA Conversion No. Series", WorkDate());
        end;

        "Posting Date" := WorkDate();
    end;
}
