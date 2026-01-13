//
//  StatusHeaderView.swift
//  Guitar Tuner
//
//  Displays status dot, note badge, guidance message, and frequency.
//

import SwiftUI

struct StatusHeaderView: View {
    let statusColor: Color
    let noteBadge: String
    let message: String
    let frequency: Double
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Status dot
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                    .shadow(color: statusColor.opacity(0.5), radius: 4)
                
                // Note badge
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Text(noteBadge)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            
            // Guidance message
            Text(message)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            // Frequency readout
            if frequency > 0 {
                Text(String(format: "%.1f Hz", frequency))
                    .font(.system(size: 14, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            } else {
                Text("-- Hz")
                    .font(.system(size: 14, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }
}

