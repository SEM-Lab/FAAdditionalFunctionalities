# Fixed Asset Additional Functionalities - Project Overview

## Purpose
This is a Microsoft Business Central AL extension that enables conversion of items to fixed assets and manages fixed asset transfers. Published by İnfotek Yazılım ve Donanım A.Ş., targeting BC versions 25.0+ with Turkish localization support.

## Core Business Processes

### Item to Fixed Asset Conversion
1. User initiates from Item Card or Item Variants page
2. Creates FA Conversion record with automatic numbering
3. Generates Fixed Asset and FA Depreciation Book entries
4. Posts negative adjustment to remove item from inventory
5. Posts FA acquisition to create fixed asset value
6. Optionally creates service items and resource cards

### Fixed Asset Transfer
1. Creates transfer items with serial number tracking
2. Manages resource cards for fixed assets
3. Handles service item integration and consignment management

## Key Components
- **Tables**: FA Conversion (60001), FA Conversion Setup (60000)
- **Codeunits**: FA Conversion Functions (60000), FA Transfer Functions (60001)
- **Pages**: FA Conversion Wizard, Setup, List pages
- **Extensions**: Item Card, Fixed Asset Card, Resource Card extensions

## Dependencies
- Turkish Localization by İnfotek (24.4.0.0)
- E-Shipment by İnfotek (20.4.1.0)
- Consignment Management by İnfotek (21.1.1.0)
- İnfotek Add-On Infrastructure (21.2.23.5)

## Target Environment
- Platform: 24.0.0.0+
- Application: 25.0.0.0+
- Runtime: 14.0
- Target: Cloud