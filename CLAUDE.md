# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Microsoft Business Central AL extension called "Fixed Asset Additional Functionalities" that provides functionality to convert items to fixed assets and handle fixed asset transfers. The extension is published by İnfotek Yazılım ve Donanım A.Ş. and targets Business Central version 25.0.

## Development Commands

### Building and Compilation
- Business Central AL extensions are compiled automatically when published to the environment
- Use the AL Language extension for VS Code for syntax validation and IntelliSense
- The extension uses runtime version 14.0 and targets Cloud platform

### Code Quality and Linting
- **Linting**: Uses LinterCop with custom rules defined in `LinterCop.ruleset.json`
- Several rules are disabled (LC0010, LC0068, LC0084, LC0023) for specific business requirements
- Follow AL coding standards and Business Central best practices

### Debugging and Testing
- Use VS Code launch configurations defined in `.vscode/launch.json`
- Multiple sandbox environments are configured for testing:
  - DIRUI_TEST (default startup object: Page 60005)
  - YILDIZ_ENV (Pera environment)
  - DARYO_TEST (Document Attachment testing)
  - ERRA_DEV (Development environment)

## Architecture Overview

### Core Components

#### Tables
- **FA Conversion (60001)**: Main transaction table for item-to-fixed-asset conversions
- **FA Conversion Setup (60000)**: Configuration table with singleton pattern for setup data

#### Codeunits
- **FA Conversion Functions (60000)**: Core business logic for converting items to fixed assets
- **FA Transfer Functions (60001)**: Handles fixed asset transfers and resource creation

#### Key Features
1. **Item to Fixed Asset Conversion**:
   - Creates fixed assets from items/item variants
   - Handles serial number tracking
   - Manages inventory adjustments and GL postings
   - Supports e-book descriptions and VAT handling

2. **Fixed Asset Transfer**:
   - Creates transfer items with serial number tracking
   - Manages resource cards for fixed assets
   - Handles service item integration
   - Supports consignment management

### Design Patterns
- **Singleton Setup Table**: `FA Conversion Setup` uses `GetRecordOnce()` pattern for performance
- **Event Subscribers**: Extensive use of event subscribers to extend standard BC functionality
- **Reservation Entries**: Custom handling of item tracking through reservation entries

### Dependencies
- Turkish Localization by İnfotek
- E-Shipment by İnfotek  
- Consignment Management by İnfotek
- İnfotek Add-On Infrastructure

### Object ID Ranges
- Uses ID range 60000-60500 for all custom objects
- Page objects, table extensions, and codeunits follow this numbering scheme

## Important Development Notes

### AL Language Features
- Uses NoImplicitWith feature for cleaner code
- TranslationFile feature enabled for multi-language support
- Runtime 14.0 with modern AL syntax

### Event Handling
- Multiple event subscribers for extending standard posting routines
- Custom handling of item journal posting, general journal posting, and FA ledger entries
- Integration with e-shipment and consignment functionalities

### Data Flow
1. User initiates conversion from Item Card or Item Variants
2. System creates FA Conversion record with automatic numbering
3. Creates Fixed Asset and FA Depreciation Book entries
4. Posts negative adjustment to remove item from inventory
5. Posts FA acquisition to create fixed asset value
6. Optionally creates service item and resource cards

### Testing Strategy
- Use sandbox environments for development and testing
- Test conversion processes end-to-end with different item configurations
- Validate integration with dependent extensions
- Test multi-language scenarios with Turkish localization