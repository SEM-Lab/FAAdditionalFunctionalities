# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Microsoft Business Central AL extension called "Fixed Asset Additional Functionalities" that provides functionality to convert items to fixed assets and handle fixed asset transfers. The extension is published by İnfotek Yazılım ve Donanım A.Ş. and targets Business Central version 26.0 (Platform 24.0, Runtime 15.2).

## Development Commands

### Building and Compilation
- **VS Code (Recommended)**: `Ctrl+Shift+P` → `AL: Publish` to compile and deploy to configured sandbox
- **PowerShell Script**: Run `.\compile.ps1` for command-line compilation using AL compiler
- **AL Compiler Direct**: `al compile /project:"." /out:"./out"` (requires AL compiler in PATH)
- Compiled `.app` files are generated in the `out/` directory

### Code Quality and Linting
- **Linting**: Uses LinterCop with custom rules defined in `LinterCop.ruleset.json`
- Disabled rules: LC0010 (cyclomatic complexity), LC0068 (permission access), LC0084/LC0023/LC0091 (Get method returns)
- Follow AL coding standards and Business Central best practices

### Debugging and Testing
- **Active Environment**: ERRA_DEV (tenant: 8beae494-639b-461e-9d2e-ad58f9467cf9, environment: ERRA270825)
- **Default Startup**: Page 60004 (FA Conversion List)
- Launch with F5 in VS Code to deploy and debug

## Architecture Overview

### Core Components

#### Tables
- **FA Conversion (60001)**: Main transaction table for item-to-fixed-asset conversions
- **FA Conversion Setup (60000)**: Configuration table with singleton pattern for setup data

#### Codeunits
- **FA Conversion Functions (60000)**: Core business logic for converting items to fixed assets (SingleInstance = true)
- **FA Transfer Functions (60001)**: Handles fixed asset transfers and resource creation
- **FA Location Sync Handler (60002)**: Manages bidirectional synchronization between FA Conversion and Fixed Asset locations

#### Key Features
1. **Item to Fixed Asset Conversion**:
   - Creates fixed assets from items/item variants with serial number tracking
   - Manages inventory adjustments and GL postings through event subscribers
   - Supports e-book descriptions and VAT handling
   - Handles multiple conversions from Transfer Receipt Lines

2. **Fixed Asset Transfer & Location Management**:
   - Creates transfer items with serial number tracking
   - Manages resource cards for fixed assets
   - Bidirectional location synchronization between FA Conversion and Fixed Asset records
   - Integration with service items and consignment management

3. **Transfer Receipt Integration**:
   - Bulk FA creation from Posted Transfer Receipt Lines (PostedTransferReceiptLnsINF.Page.al)
   - FA Location Code automatically inherits from Transfer-to Code
   - Support for creating multiple fixed assets from selected lines

### Design Patterns
- **Singleton Setup Table**: `FA Conversion Setup` uses `GetRecordOnce()` pattern to avoid repeated reads
- **SingleInstance Codeunits**: `FAConversionFunctions` marked as SingleInstance for shared logic
- **Event-Driven Architecture**: Heavy use of event subscribers for standard posting routines
- **CommitRequired Pattern**: Transaction control for posting operations

### Dependencies (from app.json)
- Turkish Localization by İnfotek (v24.4.0.0)
- E-Shipment by İnfotek (v20.4.1.0)
- Consignment Management by İnfotek (v21.1.1.0)
- İnfotek Add-On Infrastructure (v21.2.23.5)

### Object ID Ranges
- **Reserved Range**: 60000-60500 for all custom objects
- **CRITICAL**: Never use IDs outside this range
- All new objects must be within 60000-60500

### Project Structure
- `src/`: Main source code directory containing all AL objects
  - `codeunit/`: FAConversionFunctions, FATransferFunctions, FALocationSyncHandler
  - `table/`: FAConversion, FAConversionSetup
  - `tableextension/`: ItemExtension, ItemVariantExt, FixedAssetExt, ResourceExtension, TransferReceiptLineExt
  - `page/`: FAConversion, FAConversionList, FAConversionSetup, FAConversionWizard, PostedTransferReceiptLnsINF
  - `pageextension/`: ItemCardExtension, ItemVariantsExt, FixedAssetCardExt, FixedAssetListExt
  - `enum/`: WizardStep
  - `permissionset/`: FAAddFuncPerms
- `Translations/`: XLF files for multi-language support (tr-TR translations)
- `.vscode/launch.json`: Sandbox deployment configurations
- `app.json`: Extension manifest with dependencies
- `LinterCop.ruleset.json`: Custom linting rules
- `compile.ps1`: PowerShell compilation script

## Important Development Notes

### Critical Patterns to Follow
- **GetRecordOnce()**: Always use for singleton setup table reads (see FAConversionSetup.Table.al)
- **SingleInstance = true**: Mark shared codeunits appropriately (see FAConversionFunctions.Codeunit.al)
- **Event Subscribers**: Prefer over direct modification; follow existing signatures in codeunits
- **CommitRequired**: Follow transaction patterns for posting operations
- **Item Tracking**: Handle through Reservation Entries (see CreateReservationEntry procedures)

### Key Event Subscribers
- **OnAfterInsertItemJnlLine**: Handles GL account assignments for FA conversions
- **OnAfterPostGenJnlLine**: Creates FA Ledger Entries for acquisitions
- **OnBeforeTransferReceiptLineInsert**: Sets FA conversion flags
- **FA Location Synchronization**: Bidirectional sync between FA Conversion and Fixed Asset records

### Data Flows

#### Item to FA Conversion Flow
1. User initiates from Item Card/Variants or Transfer Receipt Lines
2. Creates FA Conversion record (automatic numbering via No. Series)
3. Creates Fixed Asset with FA Depreciation Book
4. Posts negative inventory adjustment via Item Journal
5. Posts FA acquisition via General Journal
6. Optional: Creates Service Item and Resource Card

#### Transfer Receipt to FA Flow
1. Select lines from Posted Transfer Receipt Lines page
2. Action: "Create Fixed Assets For Selected Lines"
3. FA Location Code inherits from Transfer-to Code
4. Bulk creates FA Conversion records and Fixed Assets

### Translation Management
- Compile generates `.g.xlf` files in `Translations/`
- Turkish translations in `Fixed Asset Additional Functionalities.tr-TR.xlf`
- Run compilation after caption/message changes to update XLF files