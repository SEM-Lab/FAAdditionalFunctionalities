# AL Compilation Script for Fixed Asset Additional Functionalities
# This script compiles the AL project using the working al compile command

# Set the project directory
$ProjectPath = "C:\Users\DGUNDUZ\Dropbox\AL\FA Additional Functionalities"

# Change to project directory
Set-Location $ProjectPath

# Create output directory if it doesn't exist
if (!(Test-Path "out")) {
    New-Item -ItemType Directory -Name "out" -Force
}

# Run the working AL compile command
Write-Host "Starting AL compilation..." -ForegroundColor Green
Write-Host "Project: $ProjectPath" -ForegroundColor Yellow

# The working command that successfully compiled:
# ----------------- al compile parameters documentation -----------------
# The command below runs the AL compiler for Business Central AL projects.
# Documented parameters used in this project:
#   /project:"."    - Specifies the AL project folder to compile. Here "."
#                     means the current directory where `app.json` lives.
#                     You can also pass an absolute path, e.g. /project:"C:\path\to\project".
#   /out:"./out"    - Specifies the output folder or output file for the
#                     compiled package. When a folder is given (relative or
#                     absolute) the compiler will place the generated .app
#                     file into that folder. If you prefer to name the
#                     output file explicitly, pass a file path like
#                     /out:"./out/MyApp.app".
#
# Other notes:
#   - The AL compiler exits with a non-zero exit code when compilation
#     fails; the script checks `$LASTEXITCODE` to determine success/failure.
#   - Using relative paths is convenient for local development, but using
#     absolute paths avoids ambiguity when run from other working directories.
#   - Additional compiler flags (not used here) include `/packagecache` and
#     `/no-symbols` for advanced scenarios.
# ----------------------------------------------------------------------
al compile /project:"." /out:"./out"

# Check compilation result
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Compilation completed successfully!" -ForegroundColor Green
    Write-Host "Output location: $ProjectPath\out" -ForegroundColor Cyan
} else {
    Write-Host "❌ Compilation failed with exit code: $LASTEXITCODE" -ForegroundColor Red
}

# List output files if any
if (Test-Path "out" -PathType Container) {
    $OutputFiles = Get-ChildItem "out" -File
    if ($OutputFiles.Count -gt 0) {
        Write-Host "Generated files:" -ForegroundColor Cyan
        $OutputFiles | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor White }
    } else {
        Write-Host "No output files generated (compilation may have completed without creating .app file)" -ForegroundColor Yellow
    }
}

Write-Host "Compilation script completed." -ForegroundColor Green