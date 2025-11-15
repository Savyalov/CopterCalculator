//
//  WarningView.swift
//  Calculator
//
//  Created by Константин Савялов on 15.11.2025.
//

import SwiftUI

struct WarningView: View {
    let message: String
    var isWarning: Bool = true
    
    var body: some View {
        HStack {
            Image(systemName: isWarning ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .foregroundColor(isWarning ? .orange : .blue)
            Text(message)
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .background(isWarning ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isWarning ? Color.orange : Color.blue, lineWidth: 1)
        )
    }
}
