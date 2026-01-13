//
//  TuningString.swift
//  Guitar Tuner
//
//  Represents the six guitar strings with their target frequencies and detection ranges.
//

import Foundation

enum TuningString: CaseIterable, Identifiable {
    case lowE
    case A
    case D
    case G
    case B
    case highE
    
    var id: String { displayName }
    
    var displayName: String {
        // Display only letters for end user (no octaves)
        switch self {
        case .lowE: return "E"
        case .A: return "A"
        case .D: return "D"
        case .G: return "G"
        case .B: return "B"
        case .highE: return "E"
        }
    }
    
    var targetFrequency: Double {
        switch self {
        case .lowE: return 82.4069
        case .A: return 110.0000
        case .D: return 146.8324
        case .G: return 195.9977
        case .B: return 246.9417
        case .highE: return 329.6276
        }
    }
    
    var minFrequency: Double {
        // Even wider ranges for more flexible detection
        switch self {
        case .lowE: return 60.0   // was 65.0
        case .A: return 85.0       // was 90.0
        case .D: return 120.0      // was 125.0
        case .G: return 165.0      // was 170.0
        case .B: return 210.0      // was 215.0
        case .highE: return 290.0  // was 295.0
        }
    }
    
    var maxFrequency: Double {
        // Even wider ranges for more flexible detection
        switch self {
        case .lowE: return 115.0  // was 110.0
        case .A: return 150.0      // was 145.0
        case .D: return 200.0      // was 195.0
        case .G: return 250.0      // was 245.0
        case .B: return 310.0      // was 305.0
        case .highE: return 390.0  // was 385.0
        }
    }
    
    var noteName: String {
        switch self {
        case .lowE: return "E2"
        case .A: return "A2"
        case .D: return "D3"
        case .G: return "G3"
        case .B: return "B3"
        case .highE: return "E4"
        }
    }
}

