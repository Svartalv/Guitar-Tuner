//
//  StringFieldView.swift
//  Guitar Tuner
//
//  Draws 6 string lines and the active cursor line that moves based on cents deviation.
//

import SwiftUI

struct StringFieldView: View {
    let cents: Double
    let cursorColor: Color
    let cursorOpacity: Double
    let isLocked: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background string lines (6 thin lines)
                ForEach(0..<6, id: \.self) { index in
                    StringLineView(
                        index: index,
                        totalStrings: 6,
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                }
                
                // Active cursor line
                CursorLineView(
                    cents: cents,
                    color: cursorColor,
                    opacity: cursorOpacity,
                    isLocked: isLocked,
                    width: geometry.size.width,
                    height: geometry.size.height
                )
            }
        }
    }
}

struct StringLineView: View {
    let index: Int
    let totalStrings: Int
    let width: Double
    let height: Double
    
    var body: some View {
        let spacing = width / Double(totalStrings + 1)
        let xPosition = spacing * Double(index + 1)
        
        Path { path in
            // Bottom point (slightly spread)
            let bottomX = xPosition
            let bottomY = height * 0.9
            
            // Top point (converging slightly)
            let topX = width * 0.5 + (xPosition - width * 0.5) * 0.7
            let topY = height * 0.1
            
            path.move(to: CGPoint(x: bottomX, y: bottomY))
            path.addLine(to: CGPoint(x: topX, y: topY))
        }
        .stroke(Color.white.opacity(0.15), lineWidth: 1)
    }
}

struct CursorLineView: View {
    let cents: Double
    let color: Color
    let opacity: Double
    let isLocked: Bool
    let width: Double
    let height: Double
    
    var body: some View {
        // Map cents to x position
        let clampedCents = max(-50.0, min(50.0, cents))
        let t = (clampedCents + 50.0) / 100.0
        
        let leftBoundX = width * 0.1
        let rightBoundX = width * 0.9
        let xPosition = leftBoundX + t * (rightBoundX - leftBoundX)
        
        // Line thickness based on locked state
        let lineWidth: CGFloat = isLocked ? 4 : 3
        
        Path { path in
            // Bottom center point
            let bottomX = width * 0.5
            let bottomY = height * 0.9
            
            // Top point (shifted by cents)
            let topX = xPosition
            let topY = height * 0.1
            
            path.move(to: CGPoint(x: bottomX, y: bottomY))
            path.addLine(to: CGPoint(x: topX, y: topY))
        }
        .stroke(
            color.opacity(opacity),
            style: StrokeStyle(
                lineWidth: lineWidth,
                lineCap: .round,
                lineJoin: .round
            )
        )
        .shadow(color: color.opacity(opacity * 0.5), radius: isLocked ? 8 : 4)
        .animation(.easeOut(duration: 0.1), value: xPosition)
    }
}

