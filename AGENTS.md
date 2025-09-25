# AGENTS.md — Agent-focused guide for this repository

## Project overview

This repository is a Microsoft Dynamics 365 Business Central AL extension named "Fixed Asset Additional Functionalities" (İnfotek). It implements:

- Item-to-Fixed-Asset conversion flows and FA transfer flows.
- Integrations with Turkish localization, e-shipment, consignment, and Infotek add-on infra.

Primary language: AL (Business Central). Target: Platform >= 24.0, App >= 25.0 (see `app.json`).

## Where to look first (high-value files)

- `src/codeunit/FAConversionFunctions.Codeunit.al` — main conversion business logic
- `src/codeunit/FATransferFunctions.Codeunit.al` — transfer / resource-card logic
- `src/table/FAConversion.Table.al` — FA Conversion transaction table
- `src/table/FAConversionSetup.Table.al` — singleton setup table (GetRecordOnce pattern)
- `src/tableextension/ItemExtension.TableExt.al` — item configuration fields used during conversion
- `Translations/` — contains generated `.g.xlf` and language XLF files
- `.vscode/launch.json` — sandbox launch configs for debugging (DIRUI_TEST, YILDIZ_ENV, etc.)
- `LinterCop.ruleset.json` — project linter exceptions and rules

## Quick setup & developer environment

This is an AL extension. Preferred development flow is VS Code with the AL Language extension installed.

1. Open the workspace root in VS Code.
2. Install and enable the Microsoft AL Language extension.
3. In VS Code: use "AL: Download Symbols" to fetch base application symbols for your target sandbox.
4. To deploy/debug: select the desired launch configuration from `.vscode/launch.json` and press F5. This will package and deploy to the configured sandbox.

Notes about compilation outside VS Code:
- The recommended way to build is via the AL Language tooling in VS Code (AL: Package).
- If you need CLI compilation, use `alc.exe` from Microsoft (Business Central SDK) — the location and usage depend on your environment and are not included in this repo.

## Useful commands (PowerShell / VS Code guidance)

- Open project in VS Code and download symbols (via command palette):
  - AL: Download Symbols
- Create package (AL: Package) / build in VS Code (command palette) or press F5 to start debugging.
- Run specific sandbox launch configuration: open `.vscode/launch.json`, choose config (e.g., `DIRUI_TEST`) and press F5.

Translation helper
- After changing captions/messages, compile once to generate `Translations/*.g.xlf` (VS Code AL: Package). Then run the repository's translation sync step (see `Translations/` and the `refreshXlf` helper referenced in code comments). If a `refreshXlf` script is present, run it to merge `.g.xlf` into your language XLFs.

## Project conventions and important patterns

- Object ID range: custom objects live in 60000–60500. Do NOT reuse system or other teams' ranges.
- SingleInstance codeunits for shared logic (example: `FAConversionFunctions.Codeunit.al` uses `SingleInstance = true`).
- Setup tables follow a GetRecordOnce() pattern to avoid repeated reads — follow that when adding setup tables.
- Posting & business flows are implemented via event subscribers; prefer adding subscribers to extend behavior rather than editing standard posting routines.
- Transaction control pattern: code follows CommitRequired / Commit usage to manage DB transactions—mirror this when adding operations that must commit or roll back.
- When adding fields to tables/pages, update XLF files and run a compile to regenerate `.g.xlf` before syncing translations.

## Integration points

- Turkish Localization — check `app.json` dependencies for the exact dependency id/version.
- E‑shipment and consignment logic are integrated via event subscribers and custom table extensions.
- When changing an interface (procedure signature or table structure), search for subscribers across the repo to update consumers.

## Testing guidance

- There are no automated unit tests in the repo by default (AL code typically validated via sandbox flows). Focus on these scenarios during manual testing:
  - Conversion: Item Card → FA Conversion → Fixed Asset creation + depreciation + inventory negative adjustment.
  - Transfer: Create transfer → resource card creation → e-shipment/consignment updates.
- Use different `.vscode` launch configs to test in different sandboxes (see `.vscode/launch.json`).

## Code style & linting

- The repo includes `LinterCop.ruleset.json` with custom rules; do not re-enable disabled rules without review.
- Keep object names, captions, and IDs consistent with existing naming patterns.
- When adding new AL objects, ensure they are within the 60000–60500 ID range and documented in your PR.

## Build & deployment

- Build: use AL Language in VS Code (AL: Package) or F5 for debugging deployment to a sandbox.
- Packaging: AL: Package creates the .app file used for deployment.
- Deployment: use VS Code debug (F5) to publish to the sandbox configured in `.vscode/launch.json` or use your deployment pipeline (CI) if available.

## Pull request & change guidance

- PR should mention changed object IDs, new dependencies (if any), and translation updates.
- Include instructions for QA: which launch config to use, which item/test data to run, and expected results.
- Do not change object ID ranges. If you need a different range, request repository owner approval.

## Debugging & troubleshooting tips

- If UI captions are missing after edits, compile to regenerate `.g.xlf` and run the translation sync.
- If a posting flow behaves differently in a sandbox, search for event subscribers that modify the same posting routine.
- Use `GetRecordOnce()` pattern when reading singleton setup to avoid repeated reads and subtle state bugs.

## Files to update when adding features

- Add new table fields: update `src/table/*.al`, add corresponding `Translations/*.xlf` entries (compile to generate `.g.xlf`, then sync).
- Add codeunit: put in `src/codeunit/`, mark `SingleInstance = true` if used across pages/codeunits.
- Add pages: update `src/page/` and pageextensions in `src/pageextension/` as required.

## Security & secrets

- Do NOT store sandbox credentials or secrets in the repository. Use environment or VS Code secrets/configurations.

## Final notes

- Keep this AGENTS.md updated whenever you change build, translation, or sandbox workflows.
- If anything here is incomplete or you want a more detailed step (for example, an exact `alc.exe` command or a translation helper script location), tell me and I will add it with exact commands.
