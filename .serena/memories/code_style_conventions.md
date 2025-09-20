# Code Style and Conventions

## AL Language Standards
- Use modern AL syntax with `NoImplicitWith` feature
- Follow Business Central best practices
- Use meaningful object names and descriptions
- Implement proper error handling and validation

## Object ID Ranges
- **Range**: 60000-60500 for all custom objects
- **Pattern**: Tables (60000+), Codeunits (60000+), Pages (60000+)
- **Extensions**: Use consistent numbering within the range

## Naming Conventions
```al
// Object naming
codeunit 60000 "FA Conversion Functions"
table 60001 "FA Conversion"
page 60005 "FA Conversion Wizard"

// Variable naming
var
    FAConversion: Record "FA Conversion";
    ConversionFunctions: Codeunit "FA Conversion Functions";
```

## Code Patterns

### Singleton Setup Tables
```al
procedure GetRecordOnce()
begin
    if RecordHasBeenRead then
        exit;
    Get();
    RecordHasBeenRead := true;
end;
```

### Event Subscribers
```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post", OnBeforeCode, '', false, false)]
local procedure OnBeforeCode(var ItemJournalLine: Record "Item Journal Line")
begin
    // Suppress dialogs during automated posting
    HideDialog := true;
end;
```

### Reservation Entries for Tracking
```al
CreateReservEntry.CreateReservEntryFor(
    Database::"Item Journal Line", 
    ItemJournalLine."Entry Type".AsInteger(),
    // ... parameters
);
```

## LinterCop Rules
- **LC0010**: Disabled (Cyclomatic complexity)
- **LC0068**: Disabled (Missing tabledata permissions)
- **LC0084**: Disabled (Get method return value usage)
- **LC0023**: Disabled (Get method return value usage)

## Documentation
- Use clear object descriptions
- Document complex business logic
- Include comments for event subscribers and integrations
- Maintain translation files for multi-language support

## Error Handling
- Use proper validation before operations
- Implement try-catch blocks where appropriate
- Provide meaningful error messages to users
- Handle edge cases in business processes