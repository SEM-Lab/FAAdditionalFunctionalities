# Project Structure

## Root Directory Structure
```
FA Additional Functionalities/
├── app.json                    # Extension manifest and dependencies
├── LinterCop.ruleset.json      # Code quality rules
├── output.app                  # Compiled extension package
├── CLAUDE.md                   # Development guidance
├── .vscode/
│   └── launch.json            # Debug configurations
├── src/                       # Source code directory
├── Translations/              # Multi-language support
└── .serena/                   # Serena configuration
```

## Source Code Organization (`src/`)

### Codeunits (`codeunit/`)
- **FAConversionFunctions.Codeunit.al** (60000): Core business logic for item-to-FA conversion
- **FATransferFunctions.Codeunit.al** (60001): Fixed asset transfer functionality

### Pages (`page/`)
- **FAConversion.Page.al**: Main conversion page
- **FAConversionList.Page.al**: List of conversion records
- **FAConversionSetup.Page.al**: Setup configuration page
- **FAConversionWizard.Page.al**: Step-by-step conversion wizard
- **PostedDirectTransferLines.Page.al**: Posted transfer lines
- **PostedTransferReceiptLnsINF.Page.al**: Transfer receipt lines

### Page Extensions (`pageextension/`)
- **FixedAssetCardExt.PageExt.al**: Extends Fixed Asset Card
- **FixedAssetListExt.PageExt.al**: Extends Fixed Asset List
- **ItemCardExtension.PageExt.al**: Extends Item Card (main entry point)
- **ItemJournalExtension.PageExt.al**: Extends Item Journal
- **ItemVariantsExt.PageExt.al**: Extends Item Variants
- **PostedDirectTransferSubform.PageExt.al**: Extends transfer subform
- **ResourceCardExtension.PageExt.al**: Extends Resource Card

### Tables (`table/`)
- **FAConversion.Table.al** (60001): Main transaction table
- **FAConversionSetup.Table.al** (60000): Configuration table

### Table Extensions (`tableextension/`)
- **DirectTransLine.TableExt.al**: Extends Direct Transfer Lines
- **FixedAssetExt.TableExt.al**: Extends Fixed Asset table
- **ItemExtension.TableExt.al**: Extends Item table (adds FA conversion fields)
- **ResourceExtension.TableExt.al**: Extends Resource table
- **TransferReceiptLineExt.TableExt.al**: Extends Transfer Receipt Lines

### Permission Sets (`permissionset/`)
- **GeneratedPermission.PermissionSet.al**: Extension permissions

## Translation Files (`Translations/`)
- **Fixed Asset Additional Functionalities.g.xlf**: Generated translation file
- **Fixed Asset Additional Functionalities22.0.0.0.tr-TR.xlf**: Turkish translations

## Key Integration Points

### Item Card Integration
- **Entry Point**: Item Card page extension
- **Trigger**: "Convert to Fixed Asset" action
- **Fields Added**: FA conversion configuration fields

### Business Logic Flow
1. **Conversion Initiation**: Item Card → FA Conversion Wizard
2. **Data Collection**: Gather item details and conversion parameters
3. **Validation**: Check prerequisites and business rules
4. **Processing**: Create FA records and post transactions
5. **Completion**: Update item status and create service items

### Event-Driven Architecture
- **Event Subscribers**: Extend standard BC posting routines
- **Integration Points**: Item Journal, General Journal, FA Ledger
- **External Systems**: E-Shipment, Consignment Management

## Development Areas

### Core Business Logic
- Conversion algorithms and validation rules
- Posting routines and GL integration
- Serial number tracking and reservation entries

### User Interface
- Conversion wizards and setup pages
- Item card extensions and actions
- List pages and navigation

### Data Model
- Custom tables for conversion tracking
- Table extensions for additional fields
- Relationship management between items and fixed assets

### Integration Layer
- Event subscribers for standard processes
- API interactions with dependent extensions
- Data synchronization across modules