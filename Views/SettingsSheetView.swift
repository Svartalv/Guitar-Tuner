//
//  SettingsSheetView.swift
//  Guitar Tuner
//
//  Placeholder settings sheet for future calibration features.
//

import SwiftUI

struct SettingsSheetView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Tuner Settings")
                    .font(.system(size: 24, weight: .semibold))
                    .padding(.top, 40)
                
                Text("Settings and calibration options will be available in a future update.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            #if os(macOS)
            .background(Color(NSColor.windowBackgroundColor))
            #else
            .background(Color(UIColor.systemBackground))
            #endif
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
        #if os(macOS)
        .frame(width: 400, height: 300)
        #endif
    }
}

