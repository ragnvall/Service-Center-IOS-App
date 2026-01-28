# Shared Directory

## Overview
Contains reusable components, utilities, and services used across features.

## Structure
```
Shared/
├─ Components/       # Reusable SwiftUI views
├─ Extensions/       # Swift extensions
├─ Services/         # Core services (networking, storage)
└─ Utils/           # Helper functions and constants
```

## Guidelines
1. All components should be well-documented
2. Include usage examples in comments
3. Write unit tests for utilities and services
4. Avoid feature-specific logic

## Adding New Components
1. Create component in appropriate directory
2. Add documentation and examples
3. Create unit tests if applicable
4. Update this README if adding new categories

## Important Notes
- Coordinate with team when modifying shared components
- Create feature branch for significant changes
- Add preview providers for UI components
