# Service Center

An iOS app for posting and finding local services/jobs — think a lightweight marketplace where users post a job, others accept and complete it, and both sides leave ratings. Built with SwiftUI and Firebase as a team project, run as a multi-sprint Scrum project (see `Scrum Documents/`).

## Features

- **Authentication** — email/password sign-up, login, and password reset via Firebase Auth, with Firestore-backed user profiles
- **Posts** — create, browse, and save job/service posts with images, hashtags, and location
- **Job lifecycle** — accept a posted job, mark it complete, and notify both parties by email
- **Rating system** — rate the other party once a job is completed
- **Comments** — comment threads on posts
- **Messaging** — direct messaging between users (Firebase-backed chat)
- **Filtering & hashtags** — filter posts by category/hashtag and location
- **Profiles** — user profile pages with skills and post history

## Tech stack

- SwiftUI, Combine
- Firebase (Auth, Firestore)
- SendGrid (transactional email notifications)

## Setup

1. Clone the repository and open `Service Center.xcodeproj` in Xcode (15.0+, iOS 16.0+, Swift 5.9+).
2. Add your own `GoogleService-Info.plist` for Firebase, or use the included one for local testing.
3. Copy `Service Center/Features/Emails/Services/Secrets.swift.example` to `Secrets.swift` in the same folder and add your own SendGrid API key (this file is gitignored).
4. Build and run.

## Project structure

Code is organized by feature (`Service Center/Features/<Feature>/{Views,ViewModels,Models,Services}`) so each team member could work on a feature in isolation. Project planning docs (sprint plans/reports, team agreement) are in `Scrum Documents/`.
