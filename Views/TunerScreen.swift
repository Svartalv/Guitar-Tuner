//
//  TunerScreen.swift
//  Guitar Tuner
//
//  Main tuner screen redesigned to match modern tuner interface.
//

import SwiftUI

struct TunerScreen: View {
    @StateObject private var viewModel = TunerViewModel()
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Tuner")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "line.3.horizontal.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // Main tuner display
                VStack(spacing: 0) {
                    // Semi-circular gauge with note
                    TunerGaugeView(
                        note: viewModel.noteBadge,
                        cents: viewModel.cents,
                        color: viewModel.statusColor,
                        opacity: viewModel.cursorOpacity
                    )
                    .frame(height: 350)
                    
                    Spacer()
                        .frame(height: 20)
                    
                    // Frequency and cents display
                    HStack(spacing: 40) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("HZ")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            Text(String(format: "%.1f", viewModel.frequencyHz > 0 ? viewModel.frequencyHz : 0.0))
                                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("cents")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            Text(String(format: "%+.0f", viewModel.cents))
                                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                                .foregroundColor(viewModel.statusColor)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 15)
                    
                    // Status message (always shown) - positioned lower
                    Text(viewModel.statusMessage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(viewModel.statusColor)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 10)
                        .transition(.opacity)
                }
                
                Spacer()
                
                // String selector buttons
                StringSelectorView(selectedString: viewModel.selectedString) { string in
                    viewModel.isAutoMode = false
                    viewModel.selectString(string)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            viewModel.startTuning()
            if viewModel.isAutoMode {
                // Will auto-detect
            } else {
                viewModel.selectString(.A)
            }
        }
        .onDisappear {
            viewModel.stopTuning()
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheetView()
        }
    }
}
