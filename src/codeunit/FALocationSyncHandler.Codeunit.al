namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;
using Microsoft.Inventory.Location;

/// <summary>
/// Keeps the location of FA Conversion records and their Fixed Assets in sync and makes sure the
/// matching FA Location exists.
/// </summary>
codeunit 60002 "FA Location Sync Handler"
{
    Permissions = tabledata "FA Conversion" = m,
                  tabledata "FA Location" = ri,
                  tabledata "Fixed Asset" = rm,
                  tabledata Location = r;

    [EventSubscriber(ObjectType::Table, Database::"Fixed Asset", OnAfterModifyEvent, '', false, false)]
    local procedure "Fixed Asset_OnAfterModifyEvent"(var Rec: Record "Fixed Asset"; var xRec: Record "Fixed Asset"; RunTrigger: Boolean)
    begin
        if not RunTrigger then
            exit;

        if Rec."FA Location Code" <> xRec."FA Location Code" then
            SyncLocationFields(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"FA Conversion", OnAfterInsertEvent, '', false, false)]
    local procedure "FA Conversion_OnAfterInsertEvent"(var Rec: Record "FA Conversion"; RunTrigger: Boolean)
    begin
        if not RunTrigger then
            exit;

        if Rec."Location Code" <> '' then
            EnsureFALocationExists(Rec."Location Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"FA Conversion", OnAfterModifyEvent, '', false, false)]
    local procedure "FA Conversion_OnAfterModifyEvent"(var Rec: Record "FA Conversion"; var xRec: Record "FA Conversion"; RunTrigger: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
    begin
        if not RunTrigger then
            exit;

        // If location code changed and Fixed Asset exists, update FA Location Code
        if (Rec."Location Code" <> xRec."Location Code") and (Rec."FA No." <> '') then begin
            if Rec."Location Code" <> '' then
                EnsureFALocationExists(Rec."Location Code");

            if FixedAsset.Get(Rec."FA No.") then begin
                FixedAsset.Validate("FA Location Code", Rec."Location Code");
                FixedAsset.Modify(true);
            end;
        end;
    end;

    local procedure SyncLocationFields(var FixedAsset: Record "Fixed Asset")
    var
        FAConversion: Record "FA Conversion";
    begin
        if FixedAsset."FA Location Code" = '' then
            exit;

        // Ensure FA Location exists (similar to existing EnsureFALocationExists logic)
        EnsureFALocationExists(FixedAsset."FA Location Code");

        // Update related FA Conversion records to maintain consistency. ModifyAll never runs
        // OnValidate (no Location table-relation check - an FA Location need not be an inventory
        // Location), exactly like the former assignment + Modify(false) loop.
        FAConversion.SetRange("FA No.", FixedAsset."No.");
        FAConversion.SetFilter("Location Code", '<>%1', FixedAsset."FA Location Code");
        FAConversion.ModifyAll("Location Code", FixedAsset."FA Location Code", false);

        // The Current Location field is a FlowField that looks up from Item Ledger Entry
        // We cannot directly modify it, but we can trigger a recalculation by modifying the record
        // This ensures the UI shows updated information when the user refreshes
        FixedAsset.CalcFields("Current Location", "Current Location Name");
    end;

    local procedure EnsureFALocationExists(LocationCode: Code[10])
    var
        Location: Record Location;
        FALocation: Record "FA Location";
    begin
        if LocationCode = '' then
            exit;

        Location.SetLoadFields(Name);
        if not FALocation.Get(LocationCode) then
            if Location.Get(LocationCode) then begin
                FALocation.Init();
                FALocation.Validate(Code, LocationCode);
                FALocation.Validate(Name, CopyStr(Location.Name, 1, MaxStrLen(FALocation.Name)));
                FALocation.Insert(true);
            end;
    end;
}