table 60000 "FA Conversion Setup"
{
    DataClassification = CustomerContent;
    Caption = 'FA Conversion Setup';
    Access = Public;
    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            NotBlank = false;
            AllowInCustomizations = Never;
        }

        field(2; "Item Journal Template Name"; Code[10])
        {
            Caption = 'Item Journal Template Name';
            TableRelation = "Item Journal Template".Name;
            ToolTip = 'Specifies the value of the Item Journal Template Name field.';
        }
        field(3; "Item Journal Batch Name"; Code[10])
        {
            Caption = 'Item Journal Batch Name';
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Item Journal Template Name"));
            ToolTip = 'Specifies the value of the Item Journal Batch Name field.';
        }
        field(4; "FA Conversion No. Series"; Code[20])
        {
            Caption = 'FA Conversion No. Series';
            TableRelation = "No. Series".Code;
            ToolTip = 'Specifies the value of the FA Conversion No. Series field.';
        }
        field(5; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";
            ToolTip = 'Specifies the value of the Depreciation Book Code field.';
        }
        field(6; "FA Transfer Item No."; Code[20])
        {
            Caption = 'FA Transfer Item No.';
            TableRelation = Item."No.";
            ToolTip = 'Specifies the value of the FA Transfer Item No. field.';
        }
        field(7; "FA Trans. Pos. Adjmt. Loc."; Code[10])
        {
            Caption = 'FA Trans. Pos. Adjmt. Location Code';
            TableRelation = Location.Code;
            ToolTip = 'Specifies the value of the FA Trans. Pos. Adjmt. Loc. field.';
        }
        field(8; "Gen. Journal Template Name"; Code[10])
        {
            Caption = 'Gen. Journal Template Name';
            TableRelation = "Gen. Journal Template".Name;
            ToolTip = 'Specifies the value of the Gen. Journal Template Name field.';
        }
        field(9; "Gen. Journal Batch Name"; Code[10])
        {
            Caption = 'Gen. Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Gen. Journal Template Name"));
            ToolTip = 'Specifies the value of the Gen. Journal Batch Name field.';
        }
        field(10; "VAT Bus. Posting Group"; Code[10])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group".Code;
            ToolTip = 'Specifies the value of the VAT Bus. Posting Group field.';
        }
        field(11; "VAT Prod. Posting Group"; Code[10])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
            ToolTip = 'Specifies the value of the VAT Prod. Posting Group field.';
        }
        field(12; "Resource Gen. Prod Post. Group"; Code[10])
        {
            Caption = 'Resource Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
            ToolTip = 'Specifies the value of the Resource Gen. Prod. Posting Group field.';
        }
        field(13; "Resource VAT Prod. Post. Group"; Code[10])
        {
            Caption = 'Resource VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
            ToolTip = 'Specifies the value of the Resource VAT Prod. Posting Group field.';
        }


    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        RecordHasBeenRead: Boolean;

    procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;

    procedure InsertIfNotExists()
    begin
        Reset();
        if not Get() then begin
            Init();
            Insert(true);
        end;
    end;
}