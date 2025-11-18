//
//  BladeViewModel.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation
import SwiftUI
import Combine

/// # Blade View Model
/// Manages blade visualization state and user interactions
/// Coordinates between 2D and 3D view representations
public class BladeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// ## Current Blade Geometry
    /// Geometry definition of the currently displayed blade
    /// Updated when new calculations complete or user modifies design
    @Published public var bladeGeometry: BladeGeometry?
    
    /// ## Current Blade Mesh
    /// 3D mesh representation of the current blade
    /// Used for 3D visualization and export operations
    @Published public var bladeMesh: BladeMesh?
    
    /// ## Selected View Type
    /// Currently active visualization mode
    /// Controls whether 2D or 3D representation is displayed
    @Published public var selectedView: BladeViewType = .threeD
    
    /// ## Camera Position
    /// Current camera position in 3D space
    /// Used for 3D view navigation and perspective control
    @Published public var cameraPosition: SIMD3<Float> = [0, 0, 5]
    
    /// ## Show Dimensions Flag
    /// Controls visibility of dimension annotations in 2D views
    /// Helpful for technical drawings and measurement display
    @Published public var showDimensions = true
    
    // MARK: - View Type Enum
    
    /// ## Blade Visualization Types
    /// Available display modes for blade representation
    public enum BladeViewType {
        case threeD      // Interactive 3D model
        case topView     // 2D top-down projection
        case sectionView // 2D cross-section view
    }
    
    // MARK: - Public Methods
    
    /// ## Update Blade Mesh
    /// Generates new 3D mesh from updated geometry
    /// Triggers view updates and recalculation of visual properties
    /// - Parameter geometry: New blade geometry definition
    public func updateMesh(from geometry: BladeGeometry) {
        let generator = BladeMeshGenerator()
        self.bladeMesh = generator.generateMesh(for: geometry, segments: 50)
        self.bladeGeometry = geometry
    }
}
