namespace Infotek.FAAdditionalFunctionalities;

using System.Upgrade;

/// <summary>
/// Upgrade codeunit for the Fixed Asset Additional Functionalities extension.
/// Backfills setup defaults so tenants that already have the app installed keep their current
/// behavior after new setup fields are introduced (NDIT-5968).
/// </summary>
codeunit 60004 "FA Add Func Upgrade"
{
    Subtype = Upgrade;
    Access = Internal;

    trigger OnUpgradePerCompany()
    begin
        UpgradeAutoCreateFATransferItem();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure OnGetPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(AutoCreateFATransferItemTagTok);
    end;

    /// <summary>
    /// Sets "Auto Create FA Transfer Item" to TRUE on the existing FA Conversion Setup record so
    /// tenants that already run this app keep today's behaviour after the field is introduced.
    /// A newly added Boolean column would otherwise default to false for existing installs.
    /// </summary>
    local procedure UpgradeAutoCreateFATransferItem()
    var
        FAConversionSetup: Record "FA Conversion Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(AutoCreateFATransferItemTagTok) then
            exit;

        if FAConversionSetup.Get() then begin
            FAConversionSetup."Auto Create FA Transfer Item" := true;
            FAConversionSetup.Modify(false);
        end;

        UpgradeTag.SetUpgradeTag(AutoCreateFATransferItemTagTok);
    end;

    var
        AutoCreateFATransferItemTagTok: Label 'INF-FAADDFUNC-AutoCreateFATransferItem-20260714', Locked = true;
}
