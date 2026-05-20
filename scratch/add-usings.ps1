# Insert using directives after the namespace line in each AL file.
$ErrorActionPreference = 'Stop'
$proj = "C:\Users\baran\Dropbox\AL\FA Additional Functionalities"
$enc = New-Object System.Text.UTF8Encoding $false
$marker = 'namespace Infotek.FAAdditionalFunctionalities;'

$map = @{
  'DirectTransLine.TableExt.al'        = @('Microsoft.Inventory.Transfer','Microsoft.Inventory.Ledger','Microsoft.Inventory.Item')
  'FAConversion.Page.al'               = @('Microsoft.FixedAssets.FixedAsset','Microsoft.Inventory.Ledger','Microsoft.Inventory.Item')
  'FAConversion.Table.al'              = @('Microsoft.Foundation.NoSeries','Microsoft.Inventory.Location','Microsoft.Inventory.Ledger')
  'FAConversionFunctions.Codeunit.al'  = @('Microsoft.Inventory.Item','Microsoft.Inventory.Location','Microsoft.FixedAssets.FixedAsset','Microsoft.FixedAssets.Depreciation','Microsoft.Foundation.NoSeries','Microsoft.Inventory.Journal','Microsoft.Inventory.Ledger','Microsoft.Inventory.Tracking','Microsoft.Inventory.Costing','Microsoft.Finance.GeneralLedger.Journal','Microsoft.Finance.GeneralLedger.Setup','Microsoft.Service.Item','Microsoft.Service.Setup','Microsoft.Inventory.Posting','Microsoft.Inventory.Transfer')
  'FAConversionSetup.Table.al'         = @('Microsoft.Inventory.Journal','Microsoft.Foundation.NoSeries','Microsoft.FixedAssets.Depreciation','Microsoft.Inventory.Item','Microsoft.Inventory.Location','Microsoft.Finance.GeneralLedger.Journal','Microsoft.Finance.VAT.Setup','Microsoft.Finance.GeneralLedger.Setup')
  'FAConversionWizard.Page.al'         = @('System.Media')
  'FALocationSyncHandler.Codeunit.al'  = @('Microsoft.FixedAssets.FixedAsset','Microsoft.Inventory.Location')
  'FATransferFunctions.Codeunit.al'    = @('Microsoft.FixedAssets.FixedAsset','Microsoft.Projects.Resources.Resource','System.Utilities','Microsoft.Inventory.Item','Microsoft.Inventory.Journal','Microsoft.Inventory.Ledger','Microsoft.Inventory.Tracking','Microsoft.Inventory.Location','Microsoft.Service.Item','Microsoft.Inventory.Transfer')
  'FixedAssetCardExt.PageExt.al'       = @('Microsoft.FixedAssets.FixedAsset','Microsoft.Inventory.Ledger')
  'FixedAssetExt.TableExt.al'          = @('Microsoft.FixedAssets.FixedAsset','Microsoft.Inventory.Ledger','Microsoft.Inventory.Item','Microsoft.Inventory.Location')
  'FixedAssetListExt.PageExt.al'       = @('Microsoft.FixedAssets.FixedAsset','Microsoft.Inventory.Ledger','Microsoft.Inventory.Location')
  'ItemCardExtension.PageExt.al'       = @('Microsoft.Inventory.Item')
  'ItemExtension.TableExt.al'          = @('Microsoft.Inventory.Item','Microsoft.Foundation.NoSeries','Microsoft.Finance.GeneralLedger.Setup','Microsoft.FixedAssets.Posting','Microsoft.FixedAssets.FixedAsset')
  'ItemJournalExtension.PageExt.al'    = @('Microsoft.Inventory.Journal')
  'ItemListExt.PageExt.al'             = @('Microsoft.Inventory.Item')
  'ItemVariantExt.TableExt.al'         = @('Microsoft.Inventory.Item')
  'ItemVariantsExt.PageExt.al'         = @('Microsoft.Inventory.Item')
  'LocationCardExtension.PageExt.al'   = @('Microsoft.Inventory.Location')
  'LocationExtension.TableExt.al'      = @('Microsoft.Inventory.Location')
  'LocationListExtension.PageExt.al'   = @('Microsoft.Inventory.Location')
  'LocationTypeAutomation.Codeunit.al' = @('Microsoft.Inventory.Transfer','Microsoft.Inventory.Location','System.Utilities')
  'PostedDirectTransferLines.Page.al'  = @('Microsoft.Inventory.Transfer','Microsoft.Inventory.Item')
  'PostedDirectTransferSubform.PageExt.al' = @('Microsoft.Inventory.Transfer','Microsoft.Inventory.Item')
  'PstdTransferRcptLnsINF.Page.al'     = @('Microsoft.Inventory.Transfer','Microsoft.Finance.Dimension','Microsoft.Purchases.Document','Microsoft.Inventory.Location')
  'ResourceCardExtension.PageExt.al'   = @('Microsoft.Projects.Resources.Resource','Microsoft.FixedAssets.FixedAsset')
  'ResourceExtension.TableExt.al'      = @('Microsoft.Projects.Resources.Resource','Microsoft.Inventory.Ledger','Microsoft.FixedAssets.FixedAsset')
  'TransferReceiptLineExt.TableExt.al' = @('Microsoft.Inventory.Transfer','Microsoft.Inventory.Ledger','Microsoft.Inventory.Item')
}

$done = 0
Get-ChildItem "$proj\src" -Filter *.al -Recurse | ForEach-Object {
    $name = $_.Name
    if (-not $map.ContainsKey($name)) { return }
    $content = [System.IO.File]::ReadAllText($_.FullName)
    $idx = $content.IndexOf($marker)
    if ($idx -lt 0) { Write-Host "SKIP (no namespace): $name"; return }
    if ($content -match '(?m)^using ') { Write-Host "SKIP (using exists): $name"; return }
    $nl = if ($content -match "`r`n") { "`r`n" } else { "`n" }
    $after = $idx + $marker.Length
    $head = $content.Substring(0, $after)
    $tail = $content.Substring($after)   # starts with nl nl
    $usingBlock = (($map[$name] | Sort-Object) | ForEach-Object { "using $_;" }) -join $nl
    $new = $head + $nl + $nl + $usingBlock + $tail
    [System.IO.File]::WriteAllText($_.FullName, $new, $enc)
    $done++
    Write-Host ("OK  {0,-40} {1} usings" -f $name, $map[$name].Count)
}
Write-Host "--- Added usings to $done files ---"
