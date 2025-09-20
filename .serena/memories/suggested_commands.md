# Development Commands

## Windows PowerShell Commands

### File System Navigation
```powershell
# List directory contents
Get-ChildItem
dir
ls

# Change directory
Set-Location "C:\Users\DGUNDUZ\Dropbox\AL\FA Additional Functionalities"
cd "C:\Users\DGUNDUZ\Dropbox\AL\FA Additional Functionalities"

# Create directory
New-Item -ItemType Directory -Name "NewFolder"
mkdir NewFolder

# Find files
Get-ChildItem -Recurse -Filter "*.al"
```

### Git Operations
```powershell
# Check status
git status

# Add files
git add .
git add "*.al"

# Commit changes
git commit -m "Description of changes"

# Push changes
git push origin master

# Pull latest changes
git pull origin master

# View differences
git diff
git diff --cached
```

### Text Search and Manipulation
```powershell
# Search for text in files
Select-String -Pattern "FAConversion" -Path "*.al" -Recurse
findstr /s /i "FAConversion" *.al

# Replace text in files (use with caution)
(Get-Content file.al) -replace 'oldtext', 'newtext' | Set-Content file.al
```

## Business Central AL Development

### Compilation & Publishing
- **Automatic**: AL extensions compile automatically when published to sandbox
- **Validation**: Use AL Language extension for syntax checking
- **Package**: Generated .app file in project root

### Debugging
- **Launch Configurations**: Use VS Code debugger with predefined environments
- **Breakpoints**: Set in AL code for debugging
- **SQL Debugging**: Enable SQL information debugger in launch.json

### Testing Environments
```json
// Available launch configurations:
"DIRUI_TEST" - Default development environment
"YILDIZ_ENV" - Pera environment  
"DARYO_TEST" - Document attachment testing
"ERRA_DEV" - Development environment
```

## Code Quality Commands

### Linting
- **LinterCop**: Automatic linting with custom ruleset
- **Rules File**: `LinterCop.ruleset.json` in project root
- **Disabled Rules**: LC0010, LC0068, LC0084, LC0023

### Translation Management
```powershell
# Refresh translation files
# Use refreshXlf tool to synchronize .g.xlf with target language files
# Located in Translations/ folder
```

## Build & Deployment

### Package Generation
- **Output**: `output.app` in project root
- **Published App**: `Infotek Yazilim ve Donanim A.S._Fixed Asset Additional Functionalities_26.0.0.0.app`

### Environment Setup
- **Sandbox**: Multiple test environments configured
- **Dependencies**: Ensure all required extensions are installed
- **Permissions**: Generated permission set available

## Utility Commands

### File Operations
```powershell
# Copy files
Copy-Item "source.al" "destination.al"

# Remove files
Remove-Item "file.al"

# Get file info
Get-Item "file.al" | Select-Object Name, Length, LastWriteTime
```

### Archive Operations
```powershell
# Create zip archive
Compress-Archive -Path "src" -DestinationPath "backup.zip"

# Extract zip archive
Expand-Archive -Path "backup.zip" -DestinationPath "extracted"
```

## Development Workflow

1. **Code Changes**: Edit AL files in `src/` directory
2. **Syntax Check**: AL extension validates syntax automatically
3. **Publish**: Use VS Code debugger to publish to sandbox
4. **Test**: Verify functionality in Business Central
5. **Commit**: Use git for version control
6. **Deploy**: Generate .app file for production deployment