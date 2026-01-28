# Features Directory

## Overview
This directory contains feature-specific implementations separated by team member.

## Structure
Each feature directory should follow this structure:
```
FeatureName/
├─ Views/            # SwiftUI Views
├─ ViewModels/       # Business logic and state management
├─ Models/           # Data models
└─ Services/         # Feature-specific services
```

## Guidelines
1. Keep features isolated and independent
2. Use dependency injection for shared services
3. Create previews for all views
4. Document public interfaces

## Example Feature Structure

// FeatureView.swift
struct FeatureView: View {
    @StateObject private var viewModel = FeatureViewModel()
    
    var body: some View {
        // Implementation
    }
}

// FeatureViewModel.swift
class FeatureViewModel: ObservableObject {
    @Published private(set) var state: FeatureState = .initial
    
    func performAction() {
        // Implementation
    }
}

