//
//  TuningString.swift
//  Guitar Tuner
//
//  Represents the six guitar strings with their target frequencies and detection ranges.
//

import Foundation

enum TuningString: String, CaseIterable, Identifiable {
    case lowE = "E"
    case A = "A"
    case D = "D"
    case G = "G"
    case B = "B"
    case highE = "E"
    
    var id: String { rawValue }
    
    var displayName: String {
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
        switch self {
        case .lowE: return 70.0
        case .A: return 95.0
        case .D: return 130.0
        case .G: return 175.0
        case .B: return 220.0
        case .highE: return 300.0
        }
    }
    
    var maxFrequency: Double {
        switch self {
        case .lowE: return 105.0
        case .A: return 140.0
        case .D: return 190.0
        case .G: return 240.0
        case .B: return 300.0
        case .highE: return 380.0
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

