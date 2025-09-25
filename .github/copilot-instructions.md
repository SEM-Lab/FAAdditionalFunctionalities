## Fixed Asset Additional Functionalities — AI coding instructions

Purpose: give an AI agent the precise, actionable project knowledge it needs to work productively on this Business Central AL extension.

Keep it short — read referenced files for details. When making code edits, follow existing ID ranges, naming, and patterns.

- Project type: Microsoft Dynamics 365 Business Central AL extension (target App 25.0+, Platform 24.0+). See `app.json` for exact requirements.
- Key folders: `src/codeunit/`, `src/table/`, `src/tableextension/`, `src/page/`, `Translations/`.

Important patterns and conventions (examples)
- Object ID range: custom objects use 60000–60500. Example: `FA Conversion Setup (60000)` (`src/table/FAConversionSetup.Table.al`).
- SingleInstance codeunits for shared logic. Example: `src/codeunit/FAConversionFunctions.Codeunit.al` uses `SingleInstance = true`.
- Singleton setup tables use GetRecordOnce() pattern to avoid repeated reads (see `FAConversionSetup.Table.al`).
- Posting flows are event-driven: code heavily uses event subscribers (see `FAConversionFunctions.Codeunit.al` and `FATransferFunctions.Codeunit.al`). Follow existing event signatures.

Data flows to note
- Conversion flow: Item Card → FA Conversion record (table 60001) → create Fixed Asset + Depreciation Book + inventory negative adjustment. See `src/codeunit/FAConversionFunctions.Codeunit.al`.
- Transfer flow: FA transfer creates transfer items and resource cards, integrates with e-shipment and consignment routines (`src/codeunit/FATransferFunctions.Codeunit.al`).

Developer workflows
- Build/compile: use AL Language tooling (VS Code AL extension). The repository includes `Translations/*.g.xlf` produced by AL compilation. Use `refreshXlf` helper (script/tool) to sync translations when needed (see `Translations/Fixed Asset Additional Functionalities.g.xlf`).
- Launch configurations: sandbox targets are present in `.vscode/launch.json` (examples: DIRUI_TEST, YILDIZ_ENV). Use those for debugging and UI flows.

Project-specific coding rules
- Don't change object ID ranges. New objects must be in 60000–60500.
- Use existing CommitRequired pattern for transactions and follow Commit/rollback behavior in codeunits.
- Respect custom LinterCop rules (see `LinterCop.ruleset.json`); some rules are intentionally disabled for historical reasons.

Integration & dependencies
- Turkish Localization dependency required (check `app.json` dependencies). Keep dependency versions in sync with app.json.
- Integration points: e-shipment, consignment, and Infotek add-on infra — these are implemented via event subscribers and custom table extensions. When changing interfaces, search for subscribers across the repo.

Where to look first (high-value files)
- `src/codeunit/FAConversionFunctions.Codeunit.al` — main business logic for conversion
- `src/codeunit/FATransferFunctions.Codeunit.al` — transfer and resource-card logic
- `src/table/FAConversion.Table.al` and `src/table/FAConversionSetup.Table.al` — core tables and setup pattern
- `src/tableextension/ItemExtension.TableExt.al` — required item configuration fields used during conversion
- `Translations/*.g.xlf` — generated translation units; run `refreshXlf` when editing captions/messages.

Edit guidance for agents
- When adding new fields, also add XLF entries (run a compilation to generate `.g.xlf` then `refreshXlf`).
- Use `GetRecordOnce()` for singleton setup reads. Use `SingleInstance` on codeunits that must be shared.
- Prefer event subscribers over direct modification of system posting routines; follow signature and routing patterns already in code.

If you need clarification
- Ask which target sandbox/launch config to use, and whether to update translations or app.json dependencies.

End of file — update or ask for feedback if anything is missing or unclear.
<parameter name="filePath">c:\Users\DGUNDUZ\Dropbox\AL\FA Additional Functionalities\.github\copilot-instructions.md