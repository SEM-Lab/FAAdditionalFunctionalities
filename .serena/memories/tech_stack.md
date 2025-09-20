# Technology Stack

## Primary Language
- **AL (Application Language)**: Microsoft's proprietary language for Business Central extensions
- Runtime version: 14.0
- Features: NoImplicitWith, TranslationFile

## Development Environment
- **Visual Studio Code** with AL Language extension
- **Business Central AL Compiler**
- **LinterCop** for code quality (with custom ruleset)

## Platform & Target
- **Microsoft Business Central**: ERP system
- **Target**: Cloud deployment
- **Platform**: 24.0.0.0+
- **Application**: 25.0.0.0+

## Dependencies & Integrations
- **Turkish Localization**: Regional compliance and language support
- **E-Shipment**: Shipping documentation integration
- **Consignment Management**: Customer-specific inventory handling
- **İnfotek Add-On Infrastructure**: Core framework components

## Development Tools
- **VS Code Launch Configurations**: Multiple sandbox environments for testing
- **AL Object Designer**: For creating and managing AL objects
- **Symbol References**: For navigating code dependencies
- **Translation Files**: XLF format for multi-language support

## Build & Deployment
- **AL Compiler**: Automatic compilation on publish
- **App Package**: .app file generation
- **Sandbox Environments**: DIRUI_TEST, YILDIZ_ENV, DARYO_TEST, ERRA_DEV