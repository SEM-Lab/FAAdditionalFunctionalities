# Development Workflow

## Getting Started
1. **Activate Project**: Use Serena to activate the project
2. **Environment Setup**: Choose appropriate sandbox environment
3. **Code Changes**: Edit AL files in `src/` directory structure
4. **Syntax Validation**: AL extension provides real-time validation
5. **Publish & Test**: Use VS Code debugger to deploy and test

## Development Environments

### Available Sandboxes
- **DIRUI_TEST**: Default development (Page 60005 startup)
- **YILDIZ_ENV**: Pera environment testing
- **DARYO_TEST**: Document attachment scenarios
- **ERRA_DEV**: General development environment

### Launch Configuration Setup
```json
{
    "name": "DIRUI_TEST",
    "type": "al",
    "request": "launch",
    "environmentType": "Sandbox",
    "environmentName": "DIRUI_TEST",
    "startupObjectId": 60005,
    "startupObjectType": "Page"
}
```

## Code Development Process

### 1. Feature Planning
- Identify business requirement
- Design AL object structure
- Plan integration points
- Consider dependencies and event subscribers

### 2. Object Creation
- Use AL Object Designer or manual creation
- Follow ID range 60000-60500
- Implement proper naming conventions
- Add comprehensive documentation

### 3. Implementation
```al
// Example: New codeunit structure
codeunit 60002 "New Feature Functions"
{
    // Object properties
    Access = Public;
    
    // Business logic implementation
    procedure ProcessNewFeature()
    begin
        // Implementation here
    end;
}
```

### 4. Event Integration
```al
// Event subscriber pattern
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Standard Codeunit", 'OnAfterEvent', '', false, false)]
local procedure HandleStandardEvent(var Rec: Record "Standard Table")
begin
    // Custom logic here
end;
```

### 5. Testing & Validation
- Publish to sandbox environment
- Test end-to-end scenarios
- Validate business logic
- Check integration with dependencies
- Verify Turkish localization

## Quality Assurance

### Code Review Checklist
- [ ] AL syntax validation passes
- [ ] LinterCop rules compliance
- [ ] Proper error handling implemented
- [ ] Business logic validation
- [ ] Integration testing completed
- [ ] Translation files updated

### Testing Scenarios
1. **Conversion Process**: Item Card → FA Conversion → Fixed Asset
2. **Transfer Process**: Fixed Asset → Transfer Item → Resource Card
3. **Integration Testing**: E-Shipment and Consignment workflows
4. **Multi-language**: Turkish localization verification

## Deployment Process

### 1. Build Preparation
- Ensure all dependencies are available
- Update version numbers in app.json
- Generate fresh translation files
- Run final syntax validation

### 2. Package Generation
- Compile extension using AL compiler
- Generate .app package file
- Validate package integrity
- Test package installation

### 3. Environment Deployment
- Deploy to target Business Central environment
- Verify extension installation
- Test critical business processes
- Monitor for runtime errors

## Maintenance & Updates

### Version Management
- Follow semantic versioning (Major.Minor.Patch)
- Update app.json version field
- Maintain changelog documentation
- Test backward compatibility

### Bug Fixes
1. Reproduce issue in sandbox
2. Implement fix with proper validation
3. Test fix thoroughly
4. Update documentation if needed
5. Deploy to production

### Feature Enhancements
1. Analyze business requirements
2. Design solution architecture
3. Implement with comprehensive testing
4. Update user documentation
5. Plan rollout strategy

## Best Practices

### Code Organization
- Keep related functionality together
- Use consistent naming patterns
- Document complex business logic
- Maintain clean separation of concerns

### Performance Considerations
- Use singleton pattern for setup tables
- Implement efficient database queries
- Minimize record locking
- Optimize event subscriber logic

### Error Handling
- Provide meaningful error messages
- Implement proper validation
- Handle edge cases gracefully
- Log errors for debugging

### Documentation
- Keep CLAUDE.md updated
- Document new features
- Maintain code comments
- Update translation files