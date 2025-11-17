# PRD: Bulk Fixed Asset Transfer Orders

## Overview
Implement functionality to create bulk transfer orders from the Fixed Asset List page. This feature allows users to select multiple fixed assets with existing transfer items and create a single transfer order with automatic serial number tracking assignment.

**Status**: Ready for Implementation
**Priority**: Medium
**Estimated Effort**: 4-5 days
**Dependencies**: FA Transfer Item functionality (already implemented)

---

## Business Requirements

### Core Functionality
1. **Multi-Selection**: Users can select multiple Fixed Assets from the list
2. **Pre-Validation**: System verifies all selected FAs have transfer items created
3. **Location Validation**: All selected FAs must share the same current location (Transfer-from Code)
4. **User Prompt**: System prompts user to select Transfer-to Location Code
5. **Automatic Creation**: Creates Transfer Order with all selected items as lines
6. **Serial Number Assignment**: Automatically assigns serial numbers to Item Tracking for each line

### Business Rules
- Only FAs with existing transfer items (Item Ledger Entries with Serial No. = FA No.) can be included
- All selected FAs must have the same Current Location (this becomes Transfer-from Code)
- Transfer-from Code and Transfer-to Code must be different
- Each FA's transfer item must have Item Tracking Code with SN Specific Tracking enabled
- System creates ONE transfer order for all selected FAs

---

## User Experience Flow

### Happy Path
1. User navigates to Fixed Asset List page
2. User selects multiple Fixed Assets (using Ctrl+Click or Shift+Click)
3. User clicks "Create Bulk Transfer Order" action
4. System validates:
   - All selected FAs have transfer items created
   - All selected FAs have the same Current Location
5. System prompts user with Location lookup page: "Select Transfer-to Location"
6. User selects destination location
7. System creates Transfer Order and displays confirmation message
8. User can click notification to navigate to created Transfer Order

### Error Scenarios
1. **No Transfer Items**: Error message "Transfer items not found for FA: [FA No. list]. Create transfer items first."
2. **Mixed Locations**: Error message "Selected FAs have different locations. All FAs must be at the same location to create a bulk transfer. Current locations: [location list]"
3. **Same Location**: Error message "Transfer-from and Transfer-to locations cannot be the same."
4. **No Selection**: Error message "Please select at least one Fixed Asset."

---

## Technical Implementation

### 1. Page Extension: `FixedAssetListExt.PageExt.al`

#### Add New Action

```al
action(CreateBulkTransferOrder)
{
    ApplicationArea = All;
    Caption = 'Create Bulk Transfer Order';
    Promoted = true;
    PromotedCategory = Process;
    PromotedIsBig = true;
    Image = TransferOrder;
    ToolTip = 'Creates a transfer order for selected fixed assets with automatic serial number tracking.';

    trigger OnAction()
    var
        FixedAsset: Record "Fixed Asset";
        TransferToLocation: Record Location;
        LocationList: Page "Location List";
        TransferToCode: Code[10];
    begin
        // Get selected Fixed Assets
        CurrPage.SetSelectionFilter(FixedAsset);

        if not FixedAsset.FindSet() then
            Error('Please select at least one Fixed Asset.');

        // Validate selection and get Transfer-from location
        FATransferFunctions.ValidateBulkTransferSelection(FixedAsset);

        // Prompt for Transfer-to Location
        LocationList.LookupMode(true);
        if LocationList.RunModal() = Action::LookupOK then begin
            LocationList.GetRecord(TransferToLocation);
            TransferToCode := TransferToLocation.Code;

            // Create bulk transfer order
            FATransferFunctions.CreateBulkTransferOrder(FixedAsset, TransferToCode);
        end;
    end;
}
```

### 2. Codeunit Extension: `FATransferFunctions.Codeunit.al`

#### New Procedure: ValidateBulkTransferSelection

```al
procedure ValidateBulkTransferSelection(var FixedAsset: Record "Fixed Asset")
var
    ItemLedgerEntry: Record "Item Ledger Entry";
    CurrentLocation: Code[10];
    LocationSet: Boolean;
    MissingTransferItems: Text;
    LocationMismatch: Boolean;
    LocationList: Text;
begin
    LocationSet := false;
    CurrentLocation := '';
    MissingTransferItems := '';
    LocationList := '';

    if FixedAsset.FindSet() then
        repeat
            // Check if transfer item exists for this FA
            ItemLedgerEntry.SetLoadFields("Serial No.", "Location Code");
            ItemLedgerEntry.SetRange("Serial No.", FixedAsset."No.");
            ItemLedgerEntry.SetRange(Open, true);

            if not ItemLedgerEntry.FindFirst() then begin
                if MissingTransferItems <> '' then
                    MissingTransferItems += ', ';
                MissingTransferItems += FixedAsset."No.";
            end else begin
                // Validate location consistency
                if not LocationSet then begin
                    CurrentLocation := ItemLedgerEntry."Location Code";
                    LocationSet := true;
                    LocationList := CurrentLocation;
                end else begin
                    if ItemLedgerEntry."Location Code" <> CurrentLocation then begin
                        LocationMismatch := true;
                        if StrPos(LocationList, ItemLedgerEntry."Location Code") = 0 then
                            LocationList += ', ' + ItemLedgerEntry."Location Code";
                    end;
                end;
            end;
        until FixedAsset.Next() = 0;

    // Report errors
    if MissingTransferItems <> '' then
        Error('Transfer items not found for FA: %1. Create transfer items first.', MissingTransferItems);

    if LocationMismatch then
        Error('Selected FAs have different locations. All FAs must be at the same location to create a bulk transfer. Current locations: %1', LocationList);

    if CurrentLocation = '' then
        Error('Cannot determine current location for selected Fixed Assets.');
end;
```

#### New Procedure: CreateBulkTransferOrder

```al
procedure CreateBulkTransferOrder(var FixedAsset: Record "Fixed Asset"; TransferToCode: Code[10])
var
    TransferHeader: Record "Transfer Header";
    TransferLine: Record "Transfer Line";
    ItemLedgerEntry: Record "Item Ledger Entry";
    Item: Record Item;
    NoSeriesMgt: Codeunit "No. Series";
    TransferFromCode: Code[10];
    LineNo: Integer;
    TransferOrderNo: Code[20];
    FACount: Integer;
begin
    // Get Transfer-from location from first FA
    FixedAsset.FindFirst();
    ItemLedgerEntry.SetRange("Serial No.", FixedAsset."No.");
    ItemLedgerEntry.SetRange(Open, true);
    ItemLedgerEntry.FindFirst();
    TransferFromCode := ItemLedgerEntry."Location Code";

    // Validate Transfer-from <> Transfer-to
    if TransferFromCode = TransferToCode then
        Error('Transfer-from and Transfer-to locations cannot be the same.');

    // Get FA Transfer Item
    FAConversionSetup.GetRecordOnce();
    FAConversionSetup.TestField("FA Transfer Item No.");
    Item.Get(FAConversionSetup."FA Transfer Item No.");

    // Create Transfer Header
    TransferHeader.Init();
    TransferHeader."No." := '';  // Auto-assign from No. Series
    TransferHeader.Insert(true);

    TransferHeader.Validate("Transfer-from Code", TransferFromCode);
    TransferHeader.Validate("Transfer-to Code", TransferToCode);
    TransferHeader.Validate("Posting Date", WorkDate());
    TransferHeader.Validate("Shipment Date", WorkDate());
    TransferHeader.Validate("Receipt Date", WorkDate());
    TransferHeader.Modify(true);

    TransferOrderNo := TransferHeader."No.";
    LineNo := 10000;
    FACount := 0;

    // Create Transfer Lines for each FA
    if FixedAsset.FindSet() then
        repeat
            FACount += 1;

            TransferLine.Init();
            TransferLine."Document No." := TransferHeader."No.";
            TransferLine."Line No." := LineNo;
            TransferLine.Insert(true);

            TransferLine.Validate("Item No.", Item."No.");
            TransferLine.Validate(Quantity, 1);
            TransferLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
            TransferLine.Modify(true);

            // Assign serial number to item tracking
            CreateReservationEntryForTransferLine(TransferLine, FixedAsset."No.");

            LineNo += 10000;
        until FixedAsset.Next() = 0;

    Message('Transfer Order %1 created successfully with %2 line(s).\\Click here to open the transfer order.', TransferOrderNo, FACount);

    // Open the created transfer order
    Page.Run(Page::"Transfer Order", TransferHeader);
end;
```

#### New Procedure: CreateReservationEntryForTransferLine

**Critical Implementation Pattern** - Based on Microsoft's recommended approach for Transfer Orders:

```al
local procedure CreateReservationEntryForTransferLine(TransferLine: Record "Transfer Line"; SerialNo: Code[50])
var
    TempReservationEntry: Record "Reservation Entry" temporary;
    CreateReservEntry: Codeunit "Create Reserv. Entry";
    ReservStatus: Enum "Reservation Status";
begin
    // Outbound (Transfer-from) direction
    TempReservationEntry.Init();
    TempReservationEntry."Entry No." := 1;
    TempReservationEntry."Serial No." := SerialNo;
    TempReservationEntry.Quantity := -1;  // Negative for outbound
    TempReservationEntry."Quantity (Base)" := -1;
    TempReservationEntry.Insert(false);

    // Create reservation entry for Transfer Line (Outbound direction = 0)
    CreateReservEntry.CreateReservEntryFor(
        Database::"Transfer Line",
        0,  // Outbound direction
        TransferLine."Document No.",
        '',
        0,
        TransferLine."Line No.",
        TransferLine."Qty. per Unit of Measure",
        TempReservationEntry.Quantity,
        TempReservationEntry."Quantity (Base)",
        TempReservationEntry);

    CreateReservEntry.CreateEntry(
        TransferLine."Item No.",
        TransferLine."Variant Code",
        TransferLine."Transfer-from Code",
        '',
        TransferLine."Shipment Date",
        TransferLine."Receipt Date",
        0,
        ReservStatus::Surplus);

    // Clear for inbound direction
    TempReservationEntry.DeleteAll();

    // Inbound (Transfer-to) direction
    TempReservationEntry.Init();
    TempReservationEntry."Entry No." := 1;
    TempReservationEntry."Serial No." := SerialNo;
    TempReservationEntry.Quantity := 1;  // Positive for inbound
    TempReservationEntry."Quantity (Base)" := 1;
    TempReservationEntry.Insert(false);

    // Create reservation entry for Transfer Line (Inbound direction = 1)
    CreateReservEntry.CreateReservEntryFor(
        Database::"Transfer Line",
        1,  // Inbound direction
        TransferLine."Document No.",
        '',
        0,
        TransferLine."Line No.",
        TransferLine."Qty. per Unit of Measure",
        TempReservationEntry.Quantity,
        TempReservationEntry."Quantity (Base)",
        TempReservationEntry);

    CreateReservEntry.CreateEntry(
        TransferLine."Item No.",
        TransferLine."Variant Code",
        TransferLine."Transfer-to Code",
        '',
        TransferLine."Shipment Date",
        TransferLine."Receipt Date",
        0,
        ReservStatus::Surplus);
end;
```

**Key Technical Notes:**
1. **Direction Parameter**: Transfer Lines require TWO reservation entries:
   - Direction 0 (Outbound): Negative quantity for items leaving Transfer-from location
   - Direction 1 (Inbound): Positive quantity for items arriving at Transfer-to location
2. **Temporary Records**: Use temporary Reservation Entry records as input
3. **CreateReservEntry Pattern**: Same codeunit used in `CreateReservationEntryForPositiveAdjmt` but with Transfer Line specifics
4. **Quantity Signs**: Outbound is negative (-1), Inbound is positive (+1)

---

## Data Flow Diagram

```
User Selection (Multiple FAs)
         ↓
Validation Check
├─→ Transfer Items Exist? → Item Ledger Entry (Open = true, Serial No. = FA No.)
├─→ Same Location? → Item Ledger Entry."Location Code"
└─→ Item Tracking Setup? → Item."Item Tracking Code"
         ↓
User Prompt: Transfer-to Location
         ↓
Create Transfer Header
├─→ Transfer-from Code (from Current Location)
├─→ Transfer-to Code (from user selection)
└─→ Posting/Shipment/Receipt Dates
         ↓
For Each Selected FA:
    ├─→ Create Transfer Line
    │   ├─→ Item No. = FA Transfer Item
    │   ├─→ Quantity = 1
    │   └─→ Line No. increment
    └─→ Create Reservation Entries
        ├─→ Direction 0 (Outbound): Qty = -1, Serial No. = FA No.
        └─→ Direction 1 (Inbound): Qty = +1, Serial No. = FA No.
         ↓
Display Confirmation & Open Transfer Order
```

---

## Testing Scenarios

### Test Case 1: Single FA Transfer
**Setup**: 1 FA with transfer item at Location A
**Action**: Select FA, create bulk transfer to Location B
**Expected**: Transfer Order created with 1 line, serial number assigned

### Test Case 2: Multiple FAs (5-10)
**Setup**: 10 FAs with transfer items all at Location A
**Action**: Select all 10 FAs, create bulk transfer to Location B
**Expected**: Transfer Order created with 10 lines, all serial numbers assigned correctly

### Test Case 3: Large Batch (20+)
**Setup**: 25 FAs with transfer items all at Location A
**Action**: Select all 25 FAs, create bulk transfer to Location B
**Expected**: Transfer Order created successfully, performance acceptable (<5 seconds)

### Test Case 4: Missing Transfer Items
**Setup**: 5 FAs, only 3 have transfer items
**Action**: Select all 5 FAs, attempt bulk transfer
**Expected**: Error message listing FAs without transfer items

### Test Case 5: Mixed Locations
**Setup**: 5 FAs with transfer items: 3 at Location A, 2 at Location B
**Action**: Select all 5 FAs, attempt bulk transfer
**Expected**: Error message listing different locations found

### Test Case 6: Same Transfer Locations
**Setup**: FAs at Location A
**Action**: Select FAs, choose Location A as Transfer-to
**Expected**: Error message "Transfer-from and Transfer-to locations cannot be the same"

### Test Case 7: Item Tracking Verification
**Setup**: Create transfer order for FAs
**Action**: Open Transfer Order → Select line → Item Tracking Lines
**Expected**: Serial numbers pre-assigned, matching FA numbers

### Test Case 8: Transfer Posting
**Setup**: Create and ship transfer order
**Action**: Post shipment, then post receipt
**Expected**:
- Item Ledger Entries updated with correct serial numbers
- FA Current Location flowfield updated to Transfer-to location
- Service Item locations updated (if applicable)

---

## Configuration Requirements

### Setup Table: FA Conversion Setup
- **FA Transfer Item No.**: Must be configured
- **Item Tracking Code**: FA Transfer Item must have tracking code with "SN Specific Tracking" = true

### Transfer Order Setup
- **Transfer Order Nos.**: No. Series must be configured in Inventory Setup

### Location Setup
- **Transfer-from Location**: Must exist and be active
- **Transfer-to Location**: Must exist and be active
- **In-Transit Code**: May be required depending on BC setup

---

## Error Handling & Validation Matrix

| Scenario | Validation Point | Error Message | Recovery Action |
|----------|------------------|---------------|-----------------|
| No FAs selected | Action trigger | "Please select at least one Fixed Asset." | Select FAs and retry |
| Missing transfer items | Pre-validation | "Transfer items not found for FA: [list]. Create transfer items first." | Create transfer items using "Create FA Transfer Item" action |
| Mixed locations | Pre-validation | "Selected FAs have different locations. All FAs must be at the same location. Current locations: [list]" | Filter selection to single location |
| Same locations | Transfer creation | "Transfer-from and Transfer-to locations cannot be the same." | Select different Transfer-to location |
| Missing tracking code | Item validation | "Item [No.] must have Item Tracking Code." | Configure Item Tracking Code on FA Transfer Item |
| Wrong tracking type | Item tracking validation | "Item Tracking Code must have SN Specific Tracking enabled." | Update Item Tracking Code settings |
| No. Series missing | Transfer Header insert | Standard BC error | Configure Transfer Order Nos. in Inventory Setup |
| Location not found | Location validation | Standard BC error | Verify location codes exist |

---

## Performance Considerations

### Expected Performance
- **10 FAs**: < 2 seconds
- **25 FAs**: < 5 seconds
- **50 FAs**: < 10 seconds
- **100 FAs**: < 20 seconds

### Optimization Strategies
1. **Batch Processing**: Create all transfer lines in single transaction
2. **SetLoadFields**: Use selective field loading for Item Ledger Entry lookups
3. **FindSet vs. FindFirst**: Use FindSet for iteration, FindFirst for single record
4. **Minimal Commits**: Avoid unnecessary Commit() calls
5. **Bulk Validation**: Validate all FAs upfront before creating any records

### Scalability Limits
- **Recommended**: Up to 50 FAs per transfer order
- **Maximum**: 100 FAs per transfer order (based on standard transfer line limits)
- **Beyond 100**: Consider creating multiple transfer orders or batch processing

---

## Integration Points

### Existing Functionality
1. **FA Transfer Item Creation**: Prerequisite for this feature
2. **FA Conversion**: Provides Current Location flowfield
3. **Item Tracking**: Standard BC item tracking system
4. **Transfer Orders**: Standard BC transfer functionality

### Affected Areas
1. **Transfer Posting**: Standard posting will update Item Ledger Entries
2. **Service Items**: Location updates via existing event subscriber (OnAfterInsert_ILE)
3. **E-Shipment**: Integration via existing event subscribers
4. **Consignment**: Location-based customer assignment via existing logic

---

## Future Enhancements (Out of Scope)

1. **Smart Location Grouping**: Automatically group FAs by location and create multiple transfer orders
2. **Transfer Template**: Save frequently used Transfer-to locations as templates
3. **Batch Scheduling**: Schedule bulk transfers for off-peak hours
4. **Transfer Status Dashboard**: Visual overview of pending/in-transit/completed transfers
5. **Reverse Transfer**: Quick action to create return transfer order
6. **Integration with Warehouse**: Advanced warehouse management integration

---

## Acceptance Criteria

- ✅ Action "Create Bulk Transfer Order" appears in Fixed Asset List
- ✅ Multi-selection enabled and working for Fixed Assets
- ✅ Validation prevents transfer order creation for FAs without transfer items
- ✅ Validation enforces same location requirement
- ✅ User prompted to select Transfer-to Location with lookup
- ✅ Transfer Order created with correct header information
- ✅ Transfer Lines created for all selected FAs (1 line per FA)
- ✅ Serial numbers automatically assigned to Item Tracking
- ✅ Item Tracking Lines show correct serial numbers when opened
- ✅ Transfer Order can be posted (ship and receive) successfully
- ✅ Item Ledger Entries created with correct serial numbers after posting
- ✅ FA Current Location updated after transfer receipt posted
- ✅ Clear error messages for all validation failures
- ✅ Confirmation message shows Transfer Order number and line count
- ✅ User can navigate to created Transfer Order from confirmation
- ✅ Performance acceptable for 25+ FAs (< 5 seconds)
- ✅ No. Series configuration documented
- ✅ Test cases executed and passed

---

## Implementation Checklist

### Phase 1: Core Functionality (2 days)
- [ ] Add "Create Bulk Transfer Order" action to FixedAssetListExt.PageExt.al
- [ ] Implement `ValidateBulkTransferSelection` procedure
- [ ] Implement `CreateBulkTransferOrder` procedure
- [ ] Implement `CreateReservationEntryForTransferLine` procedure
- [ ] Add Location lookup prompt
- [ ] Add confirmation message with navigation

### Phase 2: Error Handling (1 day)
- [ ] Implement all validation checks
- [ ] Create user-friendly error messages
- [ ] Add error recovery guidance in messages
- [ ] Test all error scenarios

### Phase 3: Testing (1 day)
- [ ] Execute all test cases (1-8)
- [ ] Performance testing with 10, 25, 50 FAs
- [ ] End-to-end posting verification
- [ ] User acceptance testing

### Phase 4: Documentation (0.5 days)
- [ ] Update user documentation
- [ ] Create setup guide for administrators
- [ ] Document configuration requirements
- [ ] Add troubleshooting guide

---

## Dependencies & Prerequisites

### Existing Features (Must Work)
1. FA Conversion functionality
2. FA Transfer Item creation (CreateFATransferItem action)
3. Item Tracking Code setup on FA Transfer Item
4. Current Location flowfield calculation

### Configuration Required
1. FA Conversion Setup:
   - FA Transfer Item No. configured
   - Item Tracking Code on FA Transfer Item
   - SN Specific Tracking enabled on Item Tracking Code
2. Inventory Setup:
   - Transfer Order Nos. series configured
3. Locations:
   - Multiple locations defined and active

### Developer Prerequisites
1. Understanding of CreateReservEntry codeunit
2. Understanding of Transfer Order data model
3. Understanding of Item Tracking in BC
4. Understanding of FlowFields and CalcFormula

---

## Glossary

- **FA**: Fixed Asset
- **Transfer Item**: Special item used for transferring Fixed Assets between locations
- **Serial No.**: Unique identifier for item tracking (equals FA No. in this context)
- **Current Location**: FlowField showing the location where the FA's transfer item currently resides
- **Item Tracking Code**: BC configuration defining how items are tracked (serial, lot, package)
- **SN Specific Tracking**: Serial Number specific tracking enabled in Item Tracking Code
- **Reservation Entry**: BC table (337) storing item tracking information
- **CreateReservEntry**: Standard BC codeunit for creating reservation/tracking entries
- **Direction**: Transfer order direction (0=Outbound/Ship, 1=Inbound/Receive)

---

**Document Version**: 2.0
**Last Updated**: 2025-01-21
**Author**: System Architect
**Reviewer**: [To be assigned]
**Approved By**: [To be assigned]
