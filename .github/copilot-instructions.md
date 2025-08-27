# Fixed Asset Additional Functionalities - AI Coding Guidelines

## Project Overview
This is a Microsoft Business Central AL extension that enables conversion of items to fixed assets and manages fixed asset transfers. Published by İnfotek Yazılım ve Donanım A.Ş., targeting BC versions 25.0+ with Turkish localization support.

## Architecture & Data Flow

### Core Business Process
1. **Item to Fixed Asset Conversion** (`src/codeunit/FAConversionFunctions.Codeunit.al`):
   - User initiates from Item Card or Item Variants page
   - Creates FA Conversion record with automatic numbering
   - Generates Fixed Asset and FA Depreciation Book entries
   - Posts negative adjustment to remove item from inventory
   - Posts FA acquisition to create fixed asset value
   - Optionally creates service items and resource cards

2. **Fixed Asset Transfer** (`src/codeunit/FATransferFunctions.Codeunit.al`):
   - Creates transfer items with serial number tracking
   - Manages resource cards for fixed assets
   - Handles service item integration and consignment management

### Key Tables
- **FA Conversion (60001)**: Main transaction table storing conversion details
- **FA Conversion Setup (60000)**: Singleton configuration table using `GetRecordOnce()` pattern

### Integration Points
- **Turkish Localization**: Required dependency for Turkish business processes
- **E-Shipment**: Integration for shipment documentation
- **Consignment Management**: Customer-specific inventory handling
- **İnfotek Add-On Infrastructure**: Core framework dependency

## Development Standards

### Object ID Ranges
- Use ID range **60000-60500** for all custom objects
- Follow pattern: Tables (60000+), Codeunits (60000+), Pages (60000+)

### AL Language Features
```al
// Use modern AL syntax
codeunit 60000 "FA Conversion Functions"
{
    SingleInstance = true;  // For shared business logic
    Access = Public;
    
    // Event subscribers for extending standard BC functionality
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post", OnBeforeCode, '', false, false)]
    local procedure OnBeforeCode(var ItemJournalLine: Record "Item Journal Line")
    begin
        // Suppress dialogs during automated posting
        HideDialog := true;
    end;
}
```

### Code Patterns

#### Singleton Setup Tables
```al
// Use GetRecordOnce() pattern for performance
procedure GetRecordOnce()
begin
    if RecordHasBeenRead then
        exit;
    Get();
    RecordHasBeenRead := true;
end;
```

#### Reservation Entries for Tracking
```al
// Custom serial number tracking through reservation entries
CreateReservEntry.CreateReservEntryFor(
    Database::"Item Journal Line", 
    ItemJournalLine."Entry Type".AsInteger(),
    // ... parameters
);
```

#### Event-Driven Extensions
- Extensive use of event subscribers to extend standard posting routines
- Integration with item journal posting, general journal posting, FA ledger entries
- Custom handling of transfer receipts and e-shipment processes

### Configuration Fields
Items require specific FA conversion fields (`src/tableextension/ItemExtension.TableExt.al`):
- `FA No. Series`: Number series for generated fixed assets
- `FA Conv. Gen. Bus. Post. Group`: Posting group for inventory adjustments
- `FA Posting Group`: Fixed asset posting configuration
- `FA Subclass Code`: Fixed asset classification

## Testing & Debugging

### Sandbox Environments
Multiple test environments configured in `.vscode/launch.json`:
- DIRUI_TEST, YILDIZ_ENV, DARYO_TEST, ERRA_DEV
- Use different startup objects for testing specific features

### End-to-End Testing Scenarios
1. **Conversion Process**: Item Card → FA Conversion → Fixed Asset creation
2. **Transfer Process**: Fixed Asset → Transfer Item → Resource Card creation
3. **Integration Testing**: E-shipment and consignment management workflows

## Localization & Translation

### XLF Translation Files
- Located in `Translations/` folder
- Pattern: `Fixed Asset Additional Functionalities[version].tr-TR.xlf`
- Use `refreshXlf` tool to synchronize with generated `.g.xlf` file

### Multi-language Support
```al
// Runtime supports translation files
"features": [
    "TranslationFile"
]
```

## Code Quality

### LinterCop Configuration
Custom rules disabled in `LinterCop.ruleset.json`:
- LC0010: Cyclomatic complexity
- LC0068: Missing tabledata permissions  
- LC0084/LC0023: Get method return value usage

### Commit Patterns
```al
// Use CommitRequired pattern for transaction control
if not CommitRequired then
    exit;
Commit();
```

## Deployment

### Dependencies (app.json)
```json
"dependencies": [
    {
        "id": "90a4fa8d-fa01-4e48-ae5f-3c7da235e84a",
        "name": "Turkish Localization by İnfotek",
        "version": "24.4.0.0"
    }
    // ... other dependencies
]
```

### Runtime Requirements
- **Platform**: 24.0.0.0+
- **Application**: 25.0.0.0+
- **Runtime**: 14.0
- **Target**: Cloud

## Common Integration Patterns

### Service Item Creation
Automatically creates service items when `Service Item Group."Create Service Item"` is enabled during FA acquisition posting.

### E-Shipment Integration
Custom event subscribers update e-shipment lines with service item information during transfer processes.

### Consignment Management
Updates service item locations based on consignment customer settings during transfer operations.</content>
<parameter name="filePath">c:\Users\DGUNDUZ\Dropbox\AL\FA Additional Functionalities\.github\copilot-instructions.md