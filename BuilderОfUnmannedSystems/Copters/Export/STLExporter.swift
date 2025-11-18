//
//  STLExporter.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation

/// # STL File Exporter
/// Exports 3D blade meshes to STL (Stereolithography) file format
/// STL is widely used for 3D printing and CAD applications
public class STLExporter {
    
    // MARK: - Public Methods
    
    /// ## Export Mesh to STL
    /// Converts blade mesh to binary STL format and saves to file
    /// Creates a temporary file with .stl extension
    /// - Parameters:
    ///   - mesh: Blade mesh to export
    ///   - filename: Base filename without extension
    /// - Returns: URL to the created STL file, or nil if export fails
    public static func export(mesh: BladeMesh, filename: String) -> URL? {
        var stlString = "solid \(filename)\n"
        
        // Convert each face to STL facet format
        for face in mesh.faces {
            guard face.count >= 3 else { continue }
            
            let v0 = mesh.vertices[face[0]]
            let v1 = mesh.vertices[face[1]]
            let v2 = mesh.vertices[face[2]]
            
            // Calculate face normal
            let normal = calculateNormal(v0: v0, v1: v1, v2: v2)
            
            // Write facet data in STL format
            stlString += "facet normal \(normal.x) \(normal.y) \(normal.z)\n"
            stlString += "  outer loop\n"
            stlString += "    vertex \(v0.x) \(v0.y) \(v0.z)\n"
            stlString += "    vertex \(v1.x) \(v1.y) \(v1.z)\n"
            stlString += "    vertex \(v2.x) \(v2.y) \(v2.z)\n"
            stlString += "  endloop\n"
            stlString += "endfacet\n"
        }
        
        stlString += "endsolid \(filename)\n"
        
        // Save to temporary directory
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(filename).stl")
        
        do {
            try stlString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error exporting STL: \(error)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    /// ## Calculate Face Normal
    /// Computes unit normal vector for a triangular face
    /// Uses cross product of edge vectors
    /// - Parameters:
    ///   - v0: First vertex of triangle
    ///   - v1: Second vertex of triangle
    ///   - v2: Third vertex of triangle
    /// - Returns: Unit normal vector as (x, y, z) tuple
    private static func calculateNormal(v0: BladePoint3D, v1: BladePoint3D, v2: BladePoint3D) -> (x: Double, y: Double, z: Double) {
        // Calculate edge vectors
        let ux = v1.x - v0.x
        let uy = v1.y - v0.y
        let uz = v1.z - v0.z
        
        let vx = v2.x - v0.x
        let vy = v2.y - v0.y
        let vz = v2.z - v0.z
        
        // Compute cross product
        let nx = uy * vz - uz * vy
        let ny = uz * vx - ux * vz
        let nz = ux * vy - uy * vx
        
        // Normalize to unit length
        let length = sqrt(nx * nx + ny * ny + nz * nz)
        
        return (nx/length, ny/length, nz/length)
    }
}
