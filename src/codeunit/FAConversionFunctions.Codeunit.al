codeunit 60000 "FA Conversion Functions"
{
    procedure NewFAConversionFromItemCard(Item: Record Item)
    begin
        Item.TestField("FA No. Series");
        Item.TestField("FA Conv. Gen. Bus. Post. Group");

        
    end;
}
