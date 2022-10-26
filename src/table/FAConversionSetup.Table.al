table 60000 "FA Conversion Setup"
{
    DataClassification = CustomerContent;
    Caption = 'FA Conversion Setup';
    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            NotBlank = false;
        }

        field(2; "Item Journal Template Name"; Code[10])
        {
            Caption = 'Item Journal Template Name';
            TableRelation = "Item Journal Template".Name;
        }
        field(3; "Item Journal Batch Name"; Code[10])
        {
            Caption = 'Item Journal Batch Name';
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Item Journal Template Name"));
        }
        field(4; "FA Conversion No. Series"; Code[20])
        {
            Caption = 'FA Conversion No. Series';
            TableRelation = "No. Series".Code;
        }
        field(5; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";
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