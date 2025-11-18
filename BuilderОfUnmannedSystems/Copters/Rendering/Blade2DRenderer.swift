//
//  Blade2DRenderer.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation
import SwiftUI

/// # 2D Blade Renderer
/// Creates 2D technical drawings of propeller blades
/// Generates top views, section views, and dimension annotations
public class Blade2DRenderer {
    
    // MARK: - Public Methods
    
    /// ## Create Top View Path
    /// Generates SVG-style path for blade top view projection
    /// Shows planform shape with accurate chord distribution
    /// - Parameters:
    ///   - geometry: Blade geometry definition
    ///   - size: Drawing canvas size
    /// - Returns: SwiftUI Path representing the top view
    public static func createTopViewPath(geometry: BladeGeometry, size: CGSize) -> Path {
        var path = Path()
        let scale = min(size.width, size.height) / CGFloat(geometry.radius * 2.2)
        
        // Draw blade outline from root to tip and back
        let segments = 100
        for i in 0...segments {
            let r = geometry.rootCutout + (geometry.radius - geometry.rootCutout) * Double(i) / Double(segments)
            let chord = geometry.chordDistribution(r / geometry.radius)
            
            let x = CGFloat(r) * scale + size.width / 2
            let yTop = size.height / 2 - CGFloat(chord / 2) * scale
            let yBottom = size.height / 2 + CGFloat(chord / 2) * scale
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: yTop))
            } else {
                path.addLine(to: CGPoint(x: x, y: yTop))
            }
        }
        
        for i in (0...segments).reversed() {
            let r = geometry.rootCutout + (geometry.radius - geometry.rootCutout) * Double(i) / Double(segments)
            let chord = geometry.chordDistribution(r / geometry.radius)
            
            let x = CGFloat(r) * scale + size.width / 2
            let yBottom = size.height / 2 + CGFloat(chord / 2) * scale
            
            path.addLine(to: CGPoint(x: x, y: yBottom))
        }
        
        path.closeSubpath()
        return path
    }
    
    /// ## Create Section View Path
    /// Generates airfoil section view at specified radial position
    /// Shows airfoil shape with appropriate thickness and camber
    /// - Parameters:
    ///   - geometry: Blade geometry definition
    ///   - size: Drawing canvas size
    ///   - radiusFraction: Radial position (0 = root, 1 = tip)
    /// - Returns: SwiftUI Path representing the section view
    public static func createSectionViewPath(geometry: BladeGeometry, size: CGSize, at radiusFraction: Double = 0.7) -> Path {
        var path = Path()
        
        let r = geometry.rootCutout + (geometry.radius - geometry.rootCutout) * radiusFraction
        let chord = geometry.chordDistribution(radiusFraction)
        
        let scale = min(size.width, size.height) / CGFloat(chord * 3)
        
        // Draw simplified airfoil shape
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        // Upper surface coordinates
        for i in 0...20 {
            let t = Double(i) / 20.0
            let x = CGFloat(t * chord) * scale
            let y = CGFloat(sin(t * .pi) * chord * 0.1) * scale // Simplified airfoil curve
            
            if i == 0 {
                path.move(to: CGPoint(x: centerX - CGFloat(chord/2) * scale + x,
                                    y: centerY - y))
            } else {
                path.addLine(to: CGPoint(x: centerX - CGFloat(chord/2) * scale + x,
                                       y: centerY - y))
            }
        }
        
        // Lower surface coordinates
        for i in (0...20).reversed() {
            let t = Double(i) / 20.0
            let x = CGFloat(t * chord) * scale
            let y = CGFloat(sin(t * .pi) * chord * 0.08) * scale // Different curve for lower surface
            
            path.addLine(to: CGPoint(x: centerX - CGFloat(chord/2) * scale + x,
                                   y: centerY + y))
        }
        
        path.closeSubpath()
        return path
    }
    
    /// ## Create Dimension Lines
    /// Generates dimension annotations for technical drawings
    /// Adds measurement lines with labels for key geometric parameters
    /// - Parameters:
    ///   - geometry: Blade geometry definition
    ///   - size: Drawing canvas size
    /// - Returns: Array of dimension line definitions
    public static func createDimensionLines(geometry: BladeGeometry, size: CGSize) -> [DimensionLine] {
        var dimensions: [DimensionLine] = []
        
        let scale = min(size.width, size.height) / CGFloat(geometry.radius * 2.2)
        
        // Blade radius dimension
        dimensions.append(DimensionLine(
            start: CGPoint(x: size.width / 2 + CGFloat(geometry.rootCutout) * scale, y: size.height - 30),
            end: CGPoint(x: size.width / 2 + CGFloat(geometry.radius) * scale, y: size.height - 30),
            text: String(format: "%.0f mm", geometry.radius * 1000)
        ))
        
        // Root chord dimension
        let rootChord = geometry.chordDistribution(0)
        dimensions.append(DimensionLine(
            start: CGPoint(x: 30, y: size.height / 2 - CGFloat(rootChord/2) * scale),
            end: CGPoint(x: 30, y: size.height / 2 + CGFloat(rootChord/2) * scale),
            text: String(format: "%.0f mm", rootChord * 1000)
        ))
        
        return dimensions
    }
}

/// # Dimension Line Model
/// Represents a dimension annotation in technical drawings
/// Contains position data and label text for measurement display
public struct DimensionLine {
    
    // MARK: - Public Properties
    
    /// ## Start Point
    /// Starting coordinate of the dimension line in drawing coordinates
    /// Typically connects to one end of the measured feature
    public let start: CGPoint
    
    /// ## End Point
    /// Ending coordinate of the dimension line in drawing coordinates
    /// Typically connects to the other end of the measured feature
    public let end: CGPoint
    
    /// ## Dimension Text
    /// Text label displaying the measured value with units
    /// Formatted according to engineering standards
    public let text: String
    
    // MARK: - Initialization
    
    /// ## Dimension Line Initializer
    /// Creates a new dimension line annotation
    /// - Parameters:
    ///   - start: Start point coordinate
    ///   - end: End point coordinate
    ///   - text: Dimension text label
    public init(start: CGPoint, end: CGPoint, text: String) {
        self.start = start
        self.end = end
        self.text = text
    }
}
