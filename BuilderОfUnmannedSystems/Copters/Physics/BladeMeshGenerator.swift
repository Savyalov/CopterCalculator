//
//  BladeMeshGenerator.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation

/// # Blade Mesh Generator
/// Creates 3D mesh representations from blade geometry definitions
/// Generates vertices, faces, and normals for visualization and export
public class BladeMeshGenerator {
    
    /// ## Generate Blade Mesh
    /// Creates a complete 3D mesh from blade geometry
    /// - Parameters:
    ///   - geometry: Blade geometry definition
    ///   - segments: Number of radial segments (higher = more detail)
    /// - Returns: Complete blade mesh with vertices and faces
    public func generateMesh(for geometry: BladeGeometry, segments: Int) -> BladeMesh {
        var vertices: [BladePoint3D] = []
        var faces: [[Int]] = []
        var normals: [BladePoint3D] = []
        
        let radialSegments = segments
        let chordSegments = 20
        
        // Generate vertices
        for i in 0...radialSegments {
            let r = geometry.rootCutout + (geometry.radius - geometry.rootCutout) * Double(i) / Double(radialSegments)
            let chord = geometry.getChord(at: r / geometry.radius)
            let twist = geometry.getTwist(at: r / geometry.radius)
            
            for j in 0...chordSegments {
                let chordPos = Double(j) / Double(chordSegments) - 0.5 // -0.5 to 0.5
                let x = r
                let y = chordPos * chord * cos(twist)
                let z = chordPos * chord * sin(twist)
                
                vertices.append(BladePoint3D(x: x, y: y, z: z))
            }
        }
        
        // Generate faces
        for i in 0..<radialSegments {
            for j in 0..<chordSegments {
                let v0 = i * (chordSegments + 1) + j
                let v1 = v0 + 1
                let v2 = v0 + (chordSegments + 1)
                let v3 = v2 + 1
                
                // Two triangles per quad
                faces.append([v0, v1, v2])
                faces.append([v1, v3, v2])
            }
        }
        
        // Calculate normals (simplified - all pointing up)
        for _ in vertices {
            normals.append(BladePoint3D(x: 0, y: 0, z: 1))
        }
        
        return BladeMesh(vertices: vertices, faces: faces, normals: normals)
    }
}
