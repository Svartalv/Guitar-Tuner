# Quick Setup Guide

## Create Xcode Project

1. **Open Xcode**
2. **Create New Project**:
   - File → New → Project
   - Choose "App" template
   - Click "Next"
   - Product Name: `Guitar Tuner`
   - Team: (select your team or leave default)
   - Organization Identifier: `com.yourname` (or your preference)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - ✅ Check "Include Tests" (optional)
   - Click "Next"
   - **IMPORTANT**: Save location should be the parent directory (one level up from this folder), OR save here and we'll move files
   - Click "Create"

3. **Add Existing Files**:
   - In Xcode, right-click on the project in the navigator
   - Select "Add Files to 'Guitar Tuner'..."
   - Navigate to this directory
   - Select ALL the .swift files and folders:
     - `GuitarTunerApp.swift`
     - `Models/` folder
     - `Services/` folder
     - `ViewModels/` folder
     - `Views/` folder
   - ✅ Check "Copy items if needed"
   - ✅ Check "Create groups"
   - ✅ Check both macOS and iOS targets
   - Click "Add"

4. **Remove Default Files**:
   - Delete `ContentView.swift` (if it exists)
   - Delete the auto-generated `Guitar_TunerApp.swift` (we have `GuitarTunerApp.swift`)

5. **Configure Info.plist for iOS**:
   - Select the iOS target
   - Go to Info tab
   - Add key: `Privacy - Microphone Usage Description`
   - Value: `Guitar Tuner needs access to your microphone to detect pitch and tune your guitar.`

6. **Build and Run**:
   - Select "My Mac" or your Mac as the destination
   - Press ⌘R or click the Play button
   - Grant microphone permission when prompted

## Alternative: Use Swift Package (if you prefer)

If you want to test without Xcode project, you can create a Package.swift, but SwiftUI apps really need Xcode projects for proper building.


