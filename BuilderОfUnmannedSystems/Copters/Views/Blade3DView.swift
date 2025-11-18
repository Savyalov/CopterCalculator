//
//  Blade3DView.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import SwiftUI
import SceneKit

/// # 3D Blade View
/// Displays interactive 3D model of the propeller blade
/// Uses SceneKit for high-quality real-time rendering
public struct Blade3DView: View {
    
    // MARK: - Environment Objects
    
    /// ## Blade View Model
    /// Provides blade mesh data and visualization state
    @EnvironmentObject var bladeVM: BladeViewModel
    
    // MARK: - State Objects
    
    /// ## 3D Renderer
    /// Manages SceneKit scene and 3D rendering
    @StateObject private var renderer = Blade3DRenderer()
    
    // MARK: - Body Implementation
    
    public var body: some View {
        VStack(spacing: 0) {
            // Controls header
            HStack {
                Text("3D Модель лопасти")
                    .font(.headline)
                
                Spacer()
                
                Button("Сбросить камеру") {
                    bladeVM.cameraPosition = [0, 0, 5]
                }
                .buttonStyle(LiquidGlassButtonStyle())
            }
            .padding()
            .background(VisualEffectView(material: .headerView, blendingMode: .behindWindow))
            
            // 3D View area
            if let mesh = bladeVM.bladeMesh {
                SceneView(
                    scene: renderer.renderBlade(mesh: mesh),
                    pointOfView: nil,
                    options: [.allowsCameraControl, .autoenablesDefaultLighting]
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .padding()
            } else {
                Text("3D модель недоступна")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Export buttons
            HStack {
                Spacer()
                
                if let mesh = bladeVM.bladeMesh {
                    ExportButton(
                        title: "Экспорт STL",
                        systemImage: "square.and.arrow.down",
                        action: { STLExporter.export(mesh: mesh, filename: "blade") }
                    )
                    
                    ExportButton(
                        title: "Экспорт OBJ",
                        systemImage: "square.and.arrow.down",
                        action: { OBJExporter.export(mesh: mesh, filename: "blade") }
                    )
                }
            }
            .padding()
        }
    }
}

/// # Export Button
/// Standardized button for file export operations
public struct ExportButton: View {
    
    // MARK: - Properties
    
    /// ## Button Title
    /// Text label for the export button
    public let title: String
    
    /// ## System Image Name
    /// SF Symbol for button icon
    public let systemImage: String
    
    /// ## Export Action
    /// Closure that performs export and returns file URL
    public let action: () -> URL?
    
    // MARK: - Body Implementation
    
    public var body: some View {
        Button(action: {
            if let url = action() {
                // Open exported file location
                NSWorkspace.shared.open(url.deletingLastPathComponent())
            }
        }) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
            }
        }
        .buttonStyle(LiquidGlassButtonStyle())
    }
}

// MARK: - Preview Provider

struct Blade3DView_Previews: PreviewProvider {
    static var previews: some View {
        Blade3DView()
            .environmentObject(BladeViewModel())
    }
}
