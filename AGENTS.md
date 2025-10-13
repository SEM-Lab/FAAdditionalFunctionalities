# AGENTS.md — Agent-focused guide for this repository

## Project Overview

This repository is a Microsoft Dynamics 365 Business Central AL extension named "Fixed Asset Additional Functionalities" (İnfotek). It implements:

- Item-to-Fixed-Asset conversion flows and FA transfer flows.
- Integrations with Turkish localization, e-shipment, consignment, and Infotek add-on infra.

Primary language: AL (Business Central). Target: Platform >= 24.0, App >= 26.0 (see `app.json`).

## Setup Commands

- **Prerequisites**: VS Code with Microsoft AL Language extension installed
- **Download symbols**: In VS Code command palette, run "AL: Download Symbols" to fetch base application symbols for your target sandbox
- **Dependencies**: Check `app.json` for required dependencies (Turkish Localization, E-Shipment, Consignment Management, İnfotek Add-On Infrastructure)

## Development Workflow

- **Start development**: Open workspace root in VS Code, select launch configuration from `.vscode/launch.json`, press F5 to deploy/debug
- **Active launch config**: `ERRA_DEV` (connects to ERRA270825 sandbox environment)
- **Hot reload**: Changes are automatically compiled and deployed when pressing F5 in debug mode
- **Translation workflow**: After changing captions/messages, compile once to generate `Translations/*.g.xlf`, then run translation sync (see `refreshXlf` helper)

## Testing Instructions

- **Manual testing scenarios**:
  - Conversion: Item Card → FA Conversion → Fixed Asset creation + depreciation + inventory negative adjustment
  - Transfer: Create transfer → resource card creation → e-shipment/consignment updates
- **Test environments**: Use different `.vscode` launch configs to test in various sandboxes
- **No automated tests**: AL code validated via sandbox flows, not unit tests

## Code Style

- **Object ID range**: Custom objects use 60000–60500 range
- **SingleInstance codeunits**: Use for shared logic (see `FAConversionFunctions.Codeunit.al`)
- **Setup pattern**: Follow GetRecordOnce() pattern for singleton setup reads
- **Event-driven architecture**: Implement posting flows via event subscribers, not direct modifications
- **Transaction control**: Use CommitRequired/Commit pattern for DB transactions
- **Linting**: Follow `LinterCop.ruleset.json` rules (some intentionally disabled)

## Build and Deployment

- **Build in VS Code**: Use "AL: Package" command or press F5 in debug mode
- **CLI compilation**: Run `compile.ps1` script or use `al compile /project:"." /out:"./out"`
- **Output**: Generates `.app` file for deployment
- **Deployment**: Use VS Code debug (F5) to publish to configured sandbox, or use CI/CD pipeline

## Pull Request Guidelines

- **Title format**: Include changed object IDs, new dependencies, and translation updates
- **Required checks**: Compile successfully, update translations, test in sandbox
- **QA instructions**: Specify launch config, test data, and expected results
- **Object ranges**: Do not change ID ranges (60000–60500); request approval for different ranges

## Additional Notes

### High-Value Files
- `src/codeunit/FAConversionFunctions.Codeunit.al` — main conversion business logic
- `src/codeunit/FATransferFunctions.Codeunit.al` — transfer / resource-card logic
- `src/table/FAConversion.Table.al` — FA Conversion transaction table
- `src/table/FAConversionSetup.Table.al` — singleton setup table (GetRecordOnce pattern)
- `src/tableextension/ItemExtension.TableExt.al` — item configuration fields used during conversion
- `Translations/` — contains generated `.g.xlf` and language XLF files

### Integration Points
- **Turkish Localization**: Check `app.json` dependencies for exact version
- **E-shipment and consignment**: Integrated via event subscribers and custom table extensions
- **Interface changes**: Search for subscribers across repo when modifying procedures or table structures

### Debugging & Troubleshooting
- **Missing captions**: Compile to regenerate `.g.xlf` and run translation sync
- **Posting flow issues**: Check event subscribers that modify the same posting routine
- **Setup reads**: Use GetRecordOnce() pattern to avoid repeated reads and state bugs

### Files to Update When Adding Features
- **New table fields**: Update `src/table/*.al`, add `Translations/*.xlf` entries, compile to generate `.g.xlf`, then sync
- **New codeunit**: Place in `src/codeunit/`, mark `SingleInstance = true` if shared
- **New pages**: Update `src/page/` and pageextensions in `src/pageextension/`

### Security & Secrets
- Do NOT store sandbox credentials or secrets in repository
- Use environment variables or VS Code secrets/configurations

### Final Notes
- Keep this AGENTS.md updated when changing build, translation, or sandbox workflows
- For detailed AL coding guidelines, see instruction files in VS Code user prompts directory
