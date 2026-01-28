# Service Center iOS App

## Project Overview
SwiftUI-based iOS application for service center management.

## Project Structure
```
ServiceCenter/
├─ Features/          # Feature-specific implementations
├─ Shared/           # Shared components and utilities
├─ App/              # App entry point and main views
├─ Assets/           # Image assets and resources
└─ Tests/            # Unit and UI tests
```

## Development Workflow

### Git Workflow
1. Always create a new branch for your feature
```bash
git checkout -b feature/feature-name
```

2. Regular commits with meaningful messages
```bash
git commit -m "feat: add user authentication"
git commit -m "fix: resolve login button layout"
```

3. Before pushing:
```bash
git checkout main
git pull
git checkout your-feature-branch
git rebase main
git push origin your-feature-branch
```

4. Create Pull Request through GitHub/GitLab
   - Use the PR template
   - Request review from at least one team member
   - Link related issues

### Commit Message Format
- feat: (new feature)
- fix: (bug fix)
- docs: (documentation changes)
- style: (formatting, missing semi-colons, etc)
- refactor: (code change that neither fixes a bug nor adds a feature)
- test: (adding missing tests)
- chore: (updating build tasks etc)

## Setup Instructions
1. Clone the repository
2. Open ServiceCenter.xcodeproj
3. Build and run

## Requirements
- Xcode 15.0+
- iOS 16.0+
- Swift 5.9+
