tableextension 60001 "Item Extension" extends Item
{
    fields
    {
        field(60000; "FA No. Series"; Code[20])
        {
            Caption = 'FA No. Series';
            TableRelation = "No. Series".Code;
        }
        field(60001; "FA Conv. Gen. Bus. Post. Group"; Code[20])
        {
            Caption = 'FA Conversion Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group".Code;
        }
        field(60002; "FA Posting Group"; Code[20])
        {
            Caption = 'FA Posting Group';
            TableRelation = "FA Posting Group";
        }

        field(60003; "FA Subclass Code"; Code[10])
        {
            Caption = 'FA Subclass Code';
            TableRelation = "FA Subclass";
        }

    }
}
