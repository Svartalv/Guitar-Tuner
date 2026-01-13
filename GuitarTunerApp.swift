//
//  GuitarTunerApp.swift
//  Guitar Tuner
//
//  Created for Cursor Guitar Tuner Project
//

import SwiftUI

@main
struct GuitarTunerApp: App {
    var body: some Scene {
        WindowGroup {
            TunerScreen()
                .preferredColorScheme(.dark)
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        #endif
    }
}

