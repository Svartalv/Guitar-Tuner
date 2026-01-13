//
//  StringSelectorView.swift
//  Guitar Tuner
//
//  Row of 6 circular buttons for selecting guitar strings.
//

import SwiftUI

struct StringSelectorView: View {
    let selectedString: TuningString
    let onSelect: (TuningString) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(TuningString.allCases) { string in
                Button(action: {
                    onSelect(string)
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                selectedString == string
                                    ? Color.white.opacity(0.25)
                                    : Color.white.opacity(0.1)
                            )
                            .frame(
                                width: selectedString == string ? 60 : 50,
                                height: selectedString == string ? 60 : 50
                            )
                        
                        Text(string.displayName)
                            .font(.system(
                                size: selectedString == string ? 20 : 18,
                                weight: selectedString == string ? .semibold : .regular,
                                design: .rounded
                            ))
                            .foregroundColor(
                                selectedString == string
                                    ? .white
                                    : .white.opacity(0.7)
                            )
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}


