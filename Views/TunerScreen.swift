//
//  TunerScreen.swift
//  Guitar Tuner
//
//  Main tuner screen with all UI components.
//

import SwiftUI

struct TunerScreen: View {
    @StateObject private var viewModel = TunerViewModel()
    @State private var showSettings = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark background with subtle gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.08, blue: 0.12),
                        Color(red: 0.12, green: 0.12, blue: 0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HeaderView()
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    // Status block (center top)
                    StatusHeaderView(
                        statusColor: viewModel.statusColor,
                        noteBadge: viewModel.noteBadge,
                        message: viewModel.statusMessage,
                        frequency: viewModel.frequencyHz
                    )
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // String field (center)
                    StringFieldView(
                        cents: viewModel.cents,
                        cursorColor: viewModel.statusColor,
                        cursorOpacity: viewModel.cursorOpacity,
                        isLocked: viewModel.isLocked
                    )
                    .frame(height: geometry.size.height * 0.35)
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // String selector row
                    StringSelectorView(selectedString: viewModel.selectedString) { string in
                        viewModel.selectString(string)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                    
                    // Settings button
                    Button(action: {
                        showSettings = true
                    }) {
                        Text("Tuner settings")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            viewModel.startTuning()
            viewModel.selectString(.A) // Default to A string
        }
        .onDisappear {
            viewModel.stopTuning()
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheetView()
        }
    }
}

struct HeaderView: View {
    var body: some View {
        HStack {
            Text("Guitar tuner")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            // Optional settings icon can go here
        }
    }
}

