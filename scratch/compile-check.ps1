# Canonical AL compile + diagnostic parse for FA Additional Functionalities
# Analyzers: CodeCop + UICop + PerTenantExtensionCop + LinterCop (matches IDE)
$ErrorActionPreference = 'Stop'
$proj = "C:\Users\baran\Dropbox\AL\FA Additional Functionalities"
$ext = Get-ChildItem "$env:USERPROFILE\.vscode\extensions" -Filter 'ms-dynamics-smb.al-*' -Directory |
       Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty FullName
$alc = "$ext\bin\win32\alc.exe"
$a   = "$ext\bin\Analyzers"
$out = "$proj\scratch\verify-cli.app"

$alcArgs = @(
    "/project:`"$proj`"",
    "/packagecachepath:`"$proj\.alpackages`"",
    "/out:`"$out`"",
    "/assemblyprobingpaths:`"$a`""
)
$rs = "$proj\LinterCop.ruleset.json"
if (Test-Path $rs) { $alcArgs += "/ruleset:`"$rs`"" }
$alcArgs += "/analyzer:`"$a\Microsoft.Dynamics.Nav.CodeCop.dll`""
$alcArgs += "/analyzer:`"$a\Microsoft.Dynamics.Nav.UICop.dll`""
$alcArgs += "/analyzer:`"$a\Microsoft.Dynamics.Nav.PerTenantExtensionCop.dll`""
$alcArgs += "/analyzer:`"$a\BusinessCentral.LinterCop.dll`""

if (Test-Path $out) { Remove-Item $out -Force }
Start-Process -FilePath $alc -ArgumentList $alcArgs -NoNewWindow -Wait `
    -RedirectStandardOutput "$proj\scratch\compile-cli.log" `
    -RedirectStandardError  "$proj\scratch\compile-cli.err.log"

$pattern = '^(.+?)\((\d+),(\d+)\):\s+(error|warning|info)\s+([A-Za-z]+\d+):\s+(.+)$'
$diags = Get-Content "$proj\scratch\compile-cli.log" | ForEach-Object {
    if ($_ -match $pattern) {
        [pscustomobject]@{
            File=Split-Path $matches[1] -Leaf; Line=[int]$matches[2]; Col=[int]$matches[3]
            Severity=$matches[4]; Code=$matches[5]; Message=$matches[6]
        }
    }
}
"=== TOTAL: $($diags.Count) diagnostics ==="
"=== BY SEVERITY ==="
$diags | Group-Object Severity | Sort-Object Name | ForEach-Object { "  {0,-8} {1}" -f $_.Name, $_.Count }
"=== BY CODE ==="
$diags | Group-Object Code | Sort-Object Count -Descending | ForEach-Object { "  {0,-8} {1}" -f $_.Name, $_.Count }
"=== DETAIL ==="
$diags | Sort-Object File,Line | ForEach-Object { "  {0,-7} {1,-8} {2}:{3} - {4}" -f $_.Severity,$_.Code,$_.File,$_.Line,$_.Message }
"=== RAW (non-diagnostic lines) ==="
Get-Content "$proj\scratch\compile-cli.log" | Where-Object { $_ -notmatch $pattern -and $_.Trim() -ne '' }
$err = Get-Content "$proj\scratch\compile-cli.err.log" -ErrorAction SilentlyContinue
if ($err) { "=== STDERR ==="; $err }
