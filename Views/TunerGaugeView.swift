//
//  TunerGaugeView.swift
//  Guitar Tuner
//
//  Semi-circular gauge display with note indicator.
//

import SwiftUI

struct TunerGaugeView: View {
    let note: String
    let cents: Double
    let color: Color
    let opacity: Double
    
    @State private var displayedNote: String = ""
    
    private func calculateDotPosition(geometry: GeometryProxy, cents: Double) -> (x: CGFloat, y: CGFloat) {
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height * 0.25
        let radius = min(geometry.size.width, geometry.size.height) * 0.45
        
        // Use cents directly (already interpolated in TunerEngine)
        let clampedCents = max(-50.0, min(50.0, cents))
        
        // Map to center when in tune (within 45 cents), otherwise show position
        let normalizedPosition: Double
        if abs(clampedCents) <= 45.0 {
            normalizedPosition = 0.5 // Center when in tune
        } else {
            normalizedPosition = (clampedCents + 50.0) / 100.0
        }
        
        let angle = .pi - (normalizedPosition * .pi)
        let center = CGPoint(x: centerX, y: centerY)
        let dotX = center.x + cos(angle) * radius
        let dotY = center.y - sin(angle) * radius
        
        return (dotX, dotY)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height * 0.25
            let radius = min(geometry.size.width, geometry.size.height) * 0.45
            let dotPos = calculateDotPosition(geometry: geometry, cents: cents)
            
            ZStack {
                // Semi-circular arc (gauge background)
                Path { path in
                    let center = CGPoint(x: centerX, y: centerY)
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: Angle(radians: .pi),
                        endAngle: Angle(radians: 0),
                        clockwise: false
                    )
                }
                .stroke(Color.white.opacity(0.2), lineWidth: 4)
                
                // Tuning indicator dot - reduced movement, uses opacity from engine
                Circle()
                    .fill(color.opacity(opacity))
                    .frame(width: 14, height: 14)
                    .position(x: dotPos.x, y: dotPos.y)
                    .shadow(color: color.opacity(opacity * 0.8), radius: 8)
                    .animation(.easeOut(duration: 0.15), value: dotPos.x)
                    .animation(.easeOut(duration: 0.15), value: dotPos.y)
                    .animation(.easeOut(duration: 0.3), value: opacity)
                
                // Flat and Sharp symbols
                Text("♭")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
                    .position(
                        x: centerX - radius * 0.85,
                        y: centerY + radius * 0.3
                    )
                
                Text("#")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
                    .position(
                        x: centerX + radius * 0.85,
                        y: centerY + radius * 0.3
                    )
                
                // Large note letter in center - always white with animation
                Text(displayedNote.isEmpty ? note : displayedNote)
                    .font(.system(size: 140, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .position(
                        x: centerX,
                        y: centerY + radius + 80
                    )
                    .scaleEffect(displayedNote == note ? 1.0 : 0.9)
                    .opacity(displayedNote == note ? 1.0 : 0.7)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: displayedNote)
                    .onChange(of: note) { newNote in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            displayedNote = newNote
                        }
                    }
                    .onAppear {
                        displayedNote = note
                    }
            }
        }
    }
}

