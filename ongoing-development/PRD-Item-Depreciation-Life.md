# PRD: Item Category Depreciation Life Integration

## Overview
Add depreciation life field to Item Categories and implement automatic calculation in Fixed Asset conversions, where the depreciation start date and end date are calculated based on the conversion date and item category's depreciation life.

## Business Requirements
- Add "Depreciation Life (Years)" field to Item Categories
- During FA conversion, automatically calculate:
  - Depreciation Start Date: Conversion date (beginning of the year)
  - Depreciation End Date: Start Date + Depreciation Life
- Support different depreciation lives per item category

## Technical Requirements
- Extend Item Category table with depreciation life field
- Modify FA conversion logic to use category-based calculations
- Implement date calculations (start of year, end date projection)
- Ensure compatibility with existing depreciation books

## Calculation Logic
```
Conversion Date: 12.09.2025
Depreciation Life: 4 years

Depreciation Start Date: 01.01.2025 (beginning of conversion year)
Depreciation End Date: 31.12.2028 (Start Date + 4 years - 1 day)
```

## User Experience
- Depreciation life configured at Item Category level
- Automatic calculation during FA conversion
- Clear visibility of calculated dates in FA Card
- Validation to ensure category has depreciation life defined

## Acceptance Criteria
- ✅ Depreciation Life field available in Item Categories
- ✅ Automatic calculation during FA conversion
- ✅ Correct date calculations (start/end dates)
- ✅ Validation for missing depreciation life
- ✅ Integration with existing depreciation workflow

## Implementation Notes
- Extend `Item Category` table with new field
- Update `FAConversionFunctions.Codeunit.al` for calculations
- Add validation in conversion process
- Update FA Card to show calculated dates
- Consider separate module approach as mentioned in requirements

## Business Rules
- Depreciation life is mandatory for categories used in FA conversions
- Start date is always January 1st of the conversion year
- End date calculation: Start + Life years - 1 day
- Manual override capability for special cases

## Priority: Low (Separate Module)
## Estimated Effort: 2-3 days
## Dependencies: Item Category table access, FA conversion logic