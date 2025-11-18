//
//  Blade2DView.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import SwiftUI

/// # 2D Blade View
/// Displays technical 2D drawings of the propeller blade
/// Shows top view, section views, and dimension annotations
public struct Blade2DView: View {
    
    // MARK: - Environment Objects
    
    /// ## Blade View Model
    /// Provides blade geometry and view state
    @EnvironmentObject var bladeVM: BladeViewModel
    
    // MARK: - Body Implementation
    
    public var body: some View {
        VStack(spacing: 0) {
            // View selector and controls
            HStack {
                Text("2D Чертеж")
                    .font(.headline)
                
                Spacer()
                
                // View type picker
                Picker("Вид", selection: $bladeVM.selectedView) {
                    Text("Вид сверху").tag(BladeViewModel.BladeViewType.topView)
                    Text("Сечение").tag(BladeViewModel.BladeViewType.sectionView)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
                
                // Dimensions toggle
                Toggle("Показать размеры", isOn: $bladeVM.showDimensions)
            }
            .padding()
            .background(VisualEffectView(material: .headerView, blendingMode: .behindWindow))
            
            // 2D Drawing area
            if let geometry = bladeVM.bladeGeometry {
                GeometryReader { geo in
                    ZStack {
                        // Background
                        VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                            .cornerRadius(8)
                        
                        // Drawing content based on selected view
                        Group {
                            switch bladeVM.selectedView {
                            case .topView:
                                TopView(geometry: geometry, size: geo.size)
                            case .sectionView:
                                SectionView(geometry: geometry, size: geo.size)
                            default:
                                EmptyView()
                            }
                        }
                        
                        // Dimension overlays if enabled
                        if bladeVM.showDimensions {
                            DimensionOverlay(geometry: geometry, size: geo.size)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                }
                .padding()
            } else {
                Text("2D чертеж недоступен")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

/// # Top View Drawing
/// Shows blade planform (top-down view)
public struct TopView: View {
    
    // MARK: - Properties
    
    /// ## Blade Geometry
    /// Geometric definition of the blade
    public let geometry: BladeGeometry
    
    /// ## Drawing Size
    /// Available size for the drawing
    public let size: CGSize
    
    // MARK: - Body Implementation
    
    public var body: some View {
        Blade2DRenderer.createTopViewPath(geometry: geometry, size: size)
            .stroke(Color.accentColor, lineWidth: 2)
            .fill(Color.accentColor.opacity(0.1))
    }
}

/// # Section View Drawing
/// Shows airfoil cross-section at specified radial position
public struct SectionView: View {
    
    // MARK: - Properties
    
    /// ## Blade Geometry
    /// Geometric definition of the blade
    public let geometry: BladeGeometry
    
    /// ## Drawing Size
    /// Available size for the drawing
    public let size: CGSize
    
    // MARK: - Body Implementation
    
    public var body: some View {
        Blade2DRenderer.createSectionViewPath(geometry: geometry, size: size)
            .stroke(Color.accentColor, lineWidth: 2)
            .fill(Color.accentColor.opacity(0.1))
    }
}

/// # Dimension Overlay
/// Displays measurement dimensions and annotations
public struct DimensionOverlay: View {
    
    // MARK: - Properties
    
    /// ## Blade Geometry
    /// Geometric definition for dimension calculation
    public let geometry: BladeGeometry
    
    /// ## Drawing Size
    /// Available size for dimension placement
    public let size: CGSize
    
    // MARK: - Body Implementation
    
    public var body: some View {
        ForEach(Array(Blade2DRenderer.createDimensionLines(geometry: geometry, size: size).enumerated()), id: \.offset) { _, dimension in
            DimensionLineView(dimension: dimension)
        }
    }
}

/// # Dimension Line View
/// Individual dimension line with labels and markers
public struct DimensionLineView: View {
    
    // MARK: - Properties
    
    /// ## Dimension Line Data
    /// Contains position and label information
    public let dimension: DimensionLine
    
    // MARK: - Body Implementation
    
    public var body: some View {
        ZStack {
            // Dimension line
            Path { path in
                path.move(to: dimension.start)
                path.addLine(to: dimension.end)
            }
            .stroke(Color.primary, lineWidth: 1)
            
            // Arrow heads
            Circle()
                .fill(Color.primary)
                .frame(width: 4, height: 4)
                .position(dimension.start)
            
            Circle()
                .fill(Color.primary)
                .frame(width: 4, height: 4)
                .position(dimension.end)
            
            // Dimension text
            Text(dimension.text)
                .font(.caption)
                .padding(4)
                .background(VisualEffectView(material: .menu, blendingMode: .behindWindow))
                .cornerRadius(4)
                .position(
                    x: (dimension.start.x + dimension.end.x) / 2,
                    y: (dimension.start.y + dimension.end.y) / 2 - 15
                )
        }
    }
}

// MARK: - Preview Provider

struct Blade2DView_Previews: PreviewProvider {
    static var previews: some View {
        Blade2DView()
            .environmentObject(BladeViewModel())
    }
}
