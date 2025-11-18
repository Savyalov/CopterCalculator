//
//  StyleManager.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import SwiftUI

/// # Liquid Glass Button Style
/// Custom button style implementing Apple's Liquid Glass design language
/// Features translucent backgrounds, smooth animations, and subtle borders
public struct LiquidGlassButtonStyle: ButtonStyle {
    
    // MARK: - ButtonStyle Implementation
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                // Visual effect background with border
                VisualEffectView(material: .selection, blendingMode: .behindWindow)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(8)
            )
            .foregroundColor(.accentColor)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// # Visual Effect View
/// NSViewRepresentable for macOS visual effect (vibrancy) views
/// Creates translucent background effects similar to native macOS apps
public struct VisualEffectView: NSViewRepresentable {
    
    // MARK: - Properties
    
    /// ## Visual Material Type
    /// macOS visual material for the background effect
    /// Controls appearance and translucency level
    public let material: NSVisualEffectView.Material
    
    /// ## Blending Mode
    /// How the visual effect blends with background content
    /// Typically .behindWindow for sidebar and content backgrounds
    public let blendingMode: NSVisualEffectView.BlendingMode
    
    // MARK: - NSViewRepresentable Implementation
    
    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Extensions

extension NumberFormatter {
    /// ## Decimal Formatter for Parameter Input
    /// Standardized number formatter for parameter text fields
    /// Ensures consistent decimal formatting across the application
    public static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 3
        return formatter
    }()
}
