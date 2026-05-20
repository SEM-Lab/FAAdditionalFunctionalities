# Rebuild the using block for files whose namespaces were corrected.
$ErrorActionPreference = 'Stop'
$proj = "C:\Users\baran\Dropbox\AL\FA Additional Functionalities"
$enc = New-Object System.Text.UTF8Encoding $false
$nsLine = 'namespace Infotek.FAAdditionalFunctionalities;'

$map = @{
  'FAConversion.Page.al' = @(
    'Microsoft.FixedAssets.FixedAsset','Microsoft.FixedAssets.Ledger',
    'Microsoft.Inventory.Item','Microsoft.Inventory.Ledger')
  'FAConversionFunctions.Codeunit.al' = @(
    'Microsoft.Finance.GeneralLedger.Journal','Microsoft.Finance.GeneralLedger.Posting',
    'Microsoft.Finance.GeneralLedger.Setup','Microsoft.FixedAssets.Depreciation',
    'Microsoft.FixedAssets.FixedAsset','Microsoft.FixedAssets.Ledger','Microsoft.FixedAssets.Setup',
    'Microsoft.Foundation.NoSeries','Microsoft.Inventory.Costing','Microsoft.Inventory.Item',
    'Microsoft.Inventory.Journal','Microsoft.Inventory.Ledger','Microsoft.Inventory.Location',
    'Microsoft.Inventory.Posting','Microsoft.Inventory.Tracking','Microsoft.Inventory.Transfer',
    'Microsoft.Service.Item','Microsoft.Service.Setup')
  'FALocationSyncHandler.Codeunit.al' = @(
    'Microsoft.FixedAssets.FixedAsset','Microsoft.FixedAssets.Setup','Microsoft.Inventory.Location')
  'FATransferFunctions.Codeunit.al' = @(
    'Microsoft.FixedAssets.FixedAsset','Microsoft.FixedAssets.Setup','Microsoft.Inventory.Item',
    'Microsoft.Inventory.Journal','Microsoft.Inventory.Ledger','Microsoft.Inventory.Location',
    'Microsoft.Inventory.Posting','Microsoft.Inventory.Tracking','Microsoft.Inventory.Transfer',
    'Microsoft.Projects.Resources.Resource','Microsoft.Service.Item','System.Utilities')
  'ItemExtension.TableExt.al' = @(
    'Microsoft.Finance.GeneralLedger.Setup','Microsoft.FixedAssets.FixedAsset',
    'Microsoft.FixedAssets.Setup','Microsoft.Foundation.NoSeries','Microsoft.Inventory.Item')
  'FAConversionWizard.Page.al' = @('System.Environment','System.Utilities')
}

Get-ChildItem "$proj\src" -Filter *.al -Recurse | ForEach-Object {
    if (-not $map.ContainsKey($_.Name)) { return }
    $content = [System.IO.File]::ReadAllText($_.FullName)
    $nl = if ($content -match "`r`n") { "`r`n" } else { "`n" }
    $lines = $content -split "`r?`n"
    $i = 1
    while ($i -lt $lines.Count -and ($lines[$i].Trim() -eq '' -or $lines[$i] -match '^using ')) { $i++ }
    $rest = ($lines[$i..($lines.Count - 1)]) -join $nl
    $usings = (($map[$_.Name] | Sort-Object) | ForEach-Object { "using $_;" }) -join $nl
    $new = $nsLine + $nl + $nl + $usings + $nl + $nl + $rest
    [System.IO.File]::WriteAllText($_.FullName, $new, $enc)
    Write-Host ("Rebuilt: {0,-38} {1} usings" -f $_.Name, $map[$_.Name].Count)
}
