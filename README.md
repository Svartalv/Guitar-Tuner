# Guitar Tuner

A native SwiftUI guitar tuner app with a calm, premium UI. Built for macOS and iOS using AVAudioEngine and YIN pitch detection.

## Features

- **String-specific tuning**: Select from 6 guitar strings (E A D G B E) for focused tuning
- **Smooth, stable cursor**: Anti-jitter smoothing with median filtering and exponential smoothing
- **Visual feedback**: Color-coded status indicators and guidance messages
- **Frequency range gating**: Only accepts frequencies within expected ranges for each string
- **Confidence-based detection**: Filters out weak or unstable signals

## Architecture

The app follows MVVM architecture:

- **Models**: `TuningString`, `TuningTarget` - Define guitar strings and their target frequencies
- **Services**: 
  - `AudioInputService` - Handles microphone input via AVAudioEngine
  - `PitchDetectorYIN` - Implements YIN pitch detection algorithm
  - `TunerEngine` - Core tuning logic with smoothing and gating
- **ViewModels**: `TunerViewModel` - Coordinates services and publishes UI state
- **Views**: SwiftUI views for the tuner interface

## Building

### Requirements

- Xcode 14.0 or later
- macOS 13.0+ / iOS 16.0+
- Swift 5.7+

### Setup

1. **Create Xcode Project**:
   - Open Xcode
   - Create a new project (File → New → Project)
   - Choose "App" template
   - Select "Multiplatform" → "App"
   - Name: "Guitar Tuner"
   - Interface: SwiftUI
   - Language: Swift
   - Save in the project directory

2. **Add Source Files**:
   - Delete the default `ContentView.swift` and `Guitar_TunerApp.swift` (if auto-generated)
   - Add all files from this directory to your Xcode project
   - Ensure files are added to both macOS and iOS targets

3. **Configure Info.plist** (iOS):
   - For iOS target, add `NSMicrophoneUsageDescription` key
   - Or use the provided `Info.plist` file

4. **Build and Run**:
   - Select the macOS target for initial testing
   - Build and run (⌘R)
   - Grant microphone permission when prompted

### iOS Setup

1. Add the project to an iOS target in Xcode
2. Ensure `Info.plist` includes `NSMicrophoneUsageDescription`
3. Build and run on device (microphone access requires physical device)

## Tuning Strings

Standard guitar tuning targets:

- **Low E (E2)**: 82.4069 Hz (range: 70-105 Hz)
- **A (A2)**: 110.0000 Hz (range: 95-140 Hz)
- **D (D3)**: 146.8324 Hz (range: 130-190 Hz)
- **G (G3)**: 195.9977 Hz (range: 175-240 Hz)
- **B (B3)**: 246.9417 Hz (range: 220-300 Hz)
- **High E (E4)**: 329.6276 Hz (range: 300-380 Hz)

## Usage

1. Launch the app
2. Select a guitar string from the bottom row
3. Play the corresponding string on your guitar
4. Watch the cursor line move to indicate tuning accuracy
5. Follow the guidance messages to tune up or down
6. When the status turns green and shows "You're good!", the string is in tune

## Technical Details

### Pitch Detection

Uses the YIN algorithm for monophonic fundamental frequency extraction:
- Time-domain autocorrelation-based approach
- Parabolic interpolation for sub-sample accuracy
- Confidence scoring based on difference function values

### Smoothing

Two-stage smoothing to prevent jitter:
1. **Median filter**: Removes outliers from last 5 valid measurements
2. **Exponential smoothing**: Alpha = 0.20 for gradual updates

### Gating

Multiple gating mechanisms ensure stable readings:
- RMS amplitude threshold (0.01) - filters silence
- Confidence threshold (0.3) - filters weak detections
- Frequency range validation - only accepts expected frequencies

### Stability

- Cursor freezes at last stable position for 500ms when signal is lost
- Opacity fades gradually after timeout
- No random jumps or jitter

## File Structure

```
Guitar Tuner/
├── GuitarTunerApp.swift          # App entry point
├── Models/
│   ├── TuningString.swift        # Guitar string enum
│   └── TuningTarget.swift        # Target frequency struct
├── Services/
│   ├── AudioInputService.swift   # Microphone capture
│   ├── PitchDetectorYIN.swift    # YIN pitch detection
│   └── TunerEngine.swift         # Tuning logic & smoothing
├── ViewModels/
│   └── TunerViewModel.swift      # MVVM coordinator
├── Views/
│   ├── TunerScreen.swift         # Main screen
│   ├── StatusHeaderView.swift    # Status indicators
│   ├── StringFieldView.swift     # String lines & cursor
│   ├── StringSelectorView.swift  # String buttons
│   └── SettingsSheetView.swift   # Settings placeholder
├── Info.plist                    # iOS microphone permission
└── README.md                     # This file
```

## Testing

### macOS Testing

1. Grant microphone permission when prompted
2. Use built-in microphone or external USB mic
3. Test each string individually
4. Verify cursor movement is smooth and stable
5. Check that guidance messages update correctly

### iOS Testing

1. Install on physical device (simulator has no microphone)
2. Grant microphone permission
3. Test in quiet environment for best results
4. Adjust buffer size if needed for responsiveness

## Customization

### Tuning Parameters

Adjust in `TunerEngine.swift`:
- `rmsThreshold`: Minimum signal level (default: 0.01)
- `confidenceThreshold`: Minimum detection confidence (default: 0.3)
- `smoothingAlpha`: Smoothing strength (default: 0.20)
- `stabilityTimeout`: Freeze duration (default: 0.5s)

### UI Colors

Status colors defined in `TunerEngine.swift`:
- Red: > 15 cents deviation
- Orange: 8-15 cents
- Yellow: 3-8 cents
- Green: ≤ 2 cents (in tune)

## Future Enhancements

- Auto mode (detects string automatically)
- Calibration settings
- Alternative tuning presets
- Visual waveform display
- Recording and playback

## License

Created for Cursor Guitar Tuner Project.

