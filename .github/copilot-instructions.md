## Fixed Asset Additional Functionalities — AI coding instructions

Purpose: give an AI agent the precise, actionable project knowledge it needs to work productively on this Business Central AL extension.

Keep it short — read referenced files for details. When making code edits, follow existing ID ranges, naming, and patterns.

- Project type: Microsoft Dynamics 365 Business Central AL extension (target App 26.0+, Platform 24.0+). See `app.json` for exact requirements.
- Key folders: `src/codeunit/`, `src/table/`, `src/tableextension/`, `src/page/`, `Translations/`.

### Big Picture Architecture

This extension implements two core business processes in Business Central:

**Conversion Flow**: Item Card → FA Conversion record (table 60001) → Fixed Asset + Depreciation Book + inventory negative adjustment. Creates FA acquisition entries and handles cost adjustments.

**Transfer Flow**: Fixed Asset transfer → transfer items with serial tracking → resource cards → e-shipment/consignment integration. Manages bidirectional location synchronization.

**Key Design Patterns**:
- Event-driven posting: Heavy use of event subscribers to extend standard BC posting routines
- Singleton setup: `FA Conversion Setup` table uses `GetRecordOnce()` pattern
- SingleInstance codeunits: `FAConversionFunctions` and `FATransferFunctions` for shared logic
- Transaction control: `CommitRequired` pattern for posting operations

### Critical Developer Workflows

- **Build/Compile**: Use VS Code AL extension (`AL: Package`) or `.\compile.ps1` PowerShell script. Output goes to `out/` directory.
- **Debug/Deploy**: Use `.vscode/launch.json` configs. Active: `ERRA_DEV` (tenant: 8beae494-639b-461e-9d2e-ad58f9467cf9, environment: ERRA270825)
- **Translation Sync**: After changing captions/messages, compile to generate `Translations/*.g.xlf`, then run translation sync helper
- **Testing**: Manual sandbox validation only - no automated unit tests. Test conversion and transfer scenarios in sandbox.

### Project-Specific Conventions (Follow Exactly)

- **Object ID Range**: 60000–60500 ONLY. Never use IDs outside this range - will break deployment.
- **Setup Table Pattern**: Use `GetRecordOnce()` for singleton reads (see `FAConversionSetup.Table.al`)
- **Codeunit Pattern**: Mark shared logic codeunits as `SingleInstance = true`
- **Event Subscribers**: Prefer over direct modifications; follow existing signatures in `FAConversionFunctions.Codeunit.al`
- **Transaction Pattern**: Use `CommitRequired` for posting operations that must commit/rollback
- **Item Tracking**: Handle via Reservation Entries (see `CreateReservationEntry` procedures)

### Integration Points & Dependencies

- **Required Dependencies**: Turkish Localization (v24.4.0.0), E-Shipment (v20.4.1.0), Consignment Management (v21.1.1.0), İnfotek Add-On Infrastructure (v21.2.23.5)
- **Event Subscribers**: Modify standard posting routines - search for subscribers when changing interfaces
- **Table Extensions**: Add FA conversion fields to standard BC tables (Item, Fixed Asset, Resource, etc.)

### Key Files & What They Contain

- `src/codeunit/FAConversionFunctions.Codeunit.al` — Core conversion logic: Item→FA creation, inventory adjustments, GL postings
- `src/codeunit/FATransferFunctions.Codeunit.al` — Transfer logic: Resource cards, transfer items, location sync
- `src/table/FAConversion.Table.al` — Main transaction table for conversions
- `src/table/FAConversionSetup.Table.al` — Singleton setup table (GetRecordOnce pattern)
- `src/tableextension/ItemExtension.TableExt.al` — FA conversion fields added to Item table
- `Translations/*.g.xlf` — Generated translation files; compile to update, then sync manually

### Common Development Tasks

**Adding New FA Conversion Fields**:
1. Add field to `FAConversion.Table.al` (ID in 60000-60500 range)
2. Add XLF translation entries
3. Compile to generate `.g.xlf`
4. Run translation sync

**Modifying Posting Logic**:
- Use event subscribers in `FAConversionFunctions.Codeunit.al`
- Follow existing `TryFunction`/`[TryFunction]` error handling pattern
- Test in sandbox with real data

**Adding New Objects**:
- Use IDs in 60000-60500 range
- Follow naming patterns from existing objects
- Update translations after adding captions

### Critical Patterns to Follow

- **Error Handling**: Use `[TryFunction]` for posting operations, wrap calls with error handling
- **Reservation Entries**: Always create for serial-tracked items during journal posting
- **Location Sync**: Bidirectional sync between FA Conversion and Fixed Asset location codes
- **Cost Calculation**: Use actual cost from Item Ledger Entries, not standard cost

### Debugging Tips

- **Posting Issues**: Check event subscribers that modify the same posting routine
- **Missing Translations**: Compile to regenerate `.g.xlf` and run translation sync
- **Setup Reads**: Use `GetRecordOnce()` pattern to avoid repeated DB reads and state bugs
- **Serial Tracking**: Verify Reservation Entries are created correctly during adjustments

If you need clarification
- Ask which target sandbox/launch config to use, and whether to update translations or app.json dependencies.

End of file — update or ask for feedback if anything is missing or unclear.
<parameter name="filePath">c:\Users\DGUNDUZ\Dropbox\AL\FA Additional Functionalities\.github\copilot-instructions.md