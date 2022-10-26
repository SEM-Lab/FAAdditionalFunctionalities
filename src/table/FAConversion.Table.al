table 60001 "FA Conversion"
{
    DataClassification = CustomerContent;
    Caption = 'FA Conversion';
    DrillDownPageId = "FA Conversion List";
    LookupPageId = "FA Conversion List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            trigger OnValidate()
            var
                FAConversionSetup: Record "FA Conversion Setup";
                NoSeriesManagement: Codeunit NoSeriesManagement;
            begin
                if "No." <> xRec."No." then begin
                    FAConversionSetup.Get();
                    NoSeriesManagement.TestManual(FAConversionSetup."FA Conversion No. Series");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(3; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
        }
        field(4; "FA No."; Code[20])
        {
            Caption = 'FA No.';
        }
        field(5; "FA Description"; Text[100])
        {
            Caption = 'FA Description';
        }
        field(6; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location.Code;
        }
        field(7; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }
        field(8; "Negative Adjmt. ILE Entry No."; Integer)
        {
            Caption = 'Negative Adjustment ILE Entry No.';
            Editable = false;
        }
        field(9; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }


        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
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
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        if "No." = '' then begin
            FAConversionSetup.Get();
            FAConversionSetup.TestField("FA Conversion No. Series");
            NoSeriesManagement.InitSeries(FAConversionSetup."FA Conversion No. Series", xRec."No. Series", 0D, "No.", "No. Series");
        end;

        "Posting Date" := WorkDate();
    end;
}
