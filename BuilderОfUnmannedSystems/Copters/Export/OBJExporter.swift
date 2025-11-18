//
//  OBJExporter.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation

/// # OBJ File Exporter
/// Exports 3D blade meshes to OBJ (Wavefront) file format
/// OBJ is commonly used in 3D modeling, animation, and game development
public class OBJExporter {
    
    // MARK: - Public Methods
    
    /// ## Export Mesh to OBJ
    /// Converts blade mesh to OBJ format and saves to file
    /// Creates a temporary file with .obj extension
    /// - Parameters:
    ///   - mesh: Blade mesh to export
    ///   - filename: Base filename without extension
    /// - Returns: URL to the created OBJ file, or nil if export fails
    public static func export(mesh: BladeMesh, filename: String) -> URL? {
        var objString = "# Propeller Blade Export\n"
        objString += "o \(filename)\n"
        
        // Write vertex coordinates
        for vertex in mesh.vertices {
            objString += "v \(vertex.x) \(vertex.y) \(vertex.z)\n"
        }
        
        // Write vertex normals
        for normal in mesh.normals {
            objString += "vn \(normal.x) \(normal.y) \(normal.z)\n"
        }
        
        // Write face definitions
        objString += "s off\n" // Smoothing group off
        for face in mesh.faces {
            objString += "f"
            for vertexIndex in face {
                // OBJ uses 1-based indexing for vertices and normals
                objString += " \(vertexIndex + 1)//\(vertexIndex + 1)"
            }
            objString += "\n"
        }
        
        // Save to temporary directory
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(filename).obj")
        
        do {
            try objString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error exporting OBJ: \(error)")
            return nil
        }
    }
}
