namespace Infotek.FAAdditionalFunctionalities;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

/// <summary>
/// Table reads used by the page extensions of this app. A page extension cannot declare the Permissions
/// property (compiler error AL0246), so the reads run here, where the object permissions are declared.
/// </summary>
codeunit 60016 "FA Page Functions"
{
    Access = Internal;
    Permissions = tabledata "Fixed Asset" = r,
                  tabledata "Item Variant" = r,
                  tabledata Location = r;

    /// <summary>
    /// Reads a fixed asset.
    /// </summary>
    /// <param name="FixedAssetNo">The number of the fixed asset to read.</param>
    /// <param name="FixedAsset">Receives the fixed asset when it exists.</param>
    /// <returns>True when the fixed asset exists.</returns>
    internal procedure GetFixedAsset(FixedAssetNo: Code[20]; var FixedAsset: Record "Fixed Asset"): Boolean
    begin
        exit(FixedAsset.Get(FixedAssetNo));
    end;

    /// <summary>
    /// Reads an item variant.
    /// </summary>
    /// <param name="ItemNo">The item number of the variant.</param>
    /// <param name="VariantCode">The variant code.</param>
    /// <param name="ItemVariant">Receives the item variant when it exists.</param>
    /// <returns>True when the item variant exists.</returns>
    internal procedure GetItemVariant(ItemNo: Code[20]; VariantCode: Code[10]; var ItemVariant: Record "Item Variant"): Boolean
    begin
        exit(ItemVariant.Get(ItemNo, VariantCode));
    end;

    /// <summary>
    /// Returns the Location Type of a location.
    /// </summary>
    /// <param name="LocationCode">The location code.</param>
    /// <param name="LocationType">Receives the Location Type INF of the location when it exists.</param>
    /// <returns>True when the location exists.</returns>
    internal procedure GetLocationType(LocationCode: Code[10]; var LocationType: Enum "Location Type INF"): Boolean
    var
        Location: Record Location;
    begin
        Location.SetLoadFields("Location Type INF");
        if not Location.Get(LocationCode) then
            exit(false);

        LocationType := Location."Location Type INF";
        exit(true);
    end;
}
