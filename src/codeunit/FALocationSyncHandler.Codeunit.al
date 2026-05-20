namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;
using Microsoft.Inventory.Location;

codeunit 60002 "FA Location Sync Handler"
{
    [EventSubscriber(ObjectType::Table, Database::"Fixed Asset", OnAfterModifyEvent, '', false, false)]
    local procedure OnAfterModifyFixedAsset(var Rec: Record "Fixed Asset"; var xRec: Record "Fixed Asset"; RunTrigger: Boolean)
    begin
        if not RunTrigger then
            exit;

        if Rec."FA Location Code" <> xRec."FA Location Code" then
            SyncLocationFields(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"FA Conversion", OnAfterInsertEvent, '', false, false)]
    local procedure OnAfterInsertFAConversion(var Rec: Record "FA Conversion"; RunTrigger: Boolean)
    begin
        if not RunTrigger then
            exit;

        if Rec."Location Code" <> '' then
            EnsureFALocationExists(Rec."Location Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"FA Conversion", OnAfterModifyEvent, '', false, false)]
    local procedure OnAfterModifyFAConversion(var Rec: Record "FA Conversion"; var xRec: Record "FA Conversion"; RunTrigger: Boolean)
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

        // Update related FA Conversion records to maintain consistency
        FAConversion.SetRange("FA No.", FixedAsset."No.");
        if FAConversion.FindSet(true) then
            repeat
                if FAConversion."Location Code" <> FixedAsset."FA Location Code" then begin
                    FAConversion."Location Code" := FixedAsset."FA Location Code";
                    FAConversion.Modify(false);
                end;
            until FAConversion.Next() = 0;

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

        if not FALocation.Get(LocationCode) then
            if Location.Get(LocationCode) then begin
                FALocation.Init();
                FALocation.Code := LocationCode;
                FALocation.Name := CopyStr(Location.Name, 1, MaxStrLen(FALocation.Name));
                FALocation.Insert(true);
            end;
    end;
}