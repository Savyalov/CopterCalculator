//
//  Blade3DRenderer.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation
import SceneKit
import SwiftUI
import Combine

/// # 3D Blade Renderer
/// Manages 3D visualization of propeller blades using SceneKit
/// Provides high-quality rendering with realistic materials and lighting
public class Blade3DRenderer: NSObject, ObservableObject {
    
    // MARK: - Public Properties
    
    /// ## Loading Status
    /// Indicates whether the renderer is currently processing geometry
    /// Used to show loading indicators in the UI
    @Published public var isLoading = false
    
    // MARK: - Private Properties
    
    /// ## SceneKit Scene
    /// Root scene containing all 3D objects and lighting
    /// Manages the 3D environment and rendering pipeline
    private var scene: SCNScene
    
    /// ## Camera Node
    /// SceneKit camera for viewing the 3D scene
    /// Controls viewpoint and projection parameters
    private var cameraNode: SCNNode
    
    /// ## Blade Node
    /// SceneKit node containing the blade geometry
    /// Parent node for all blade visual components
    private var bladeNode: SCNNode?
    
    // MARK: - Initialization
    
    /// ## 3D Renderer Initializer
    /// Sets up the SceneKit scene with default lighting and camera
    public override init() {
        self.scene = SCNScene()
        self.cameraNode = SCNNode()
        super.init()
        setupScene()
    }
    
    // MARK: - Public Methods
    
    /// ## Render Blade Mesh
    /// Converts blade mesh to SceneKit geometry and adds to scene
    /// Applies materials and configures for high-quality rendering
    /// - Parameter mesh: Blade mesh to render
    /// - Returns: Configured SceneKit scene ready for display
    public func renderBlade(mesh: BladeMesh) -> SCNScene {
        isLoading = true
        
        // Remove previous blade geometry
        bladeNode?.removeFromParentNode()
        
        // Create new blade geometry from mesh
        let bladeGeometry = createGeometry(from: mesh)
        bladeNode = SCNNode(geometry: bladeGeometry)
        
        // Apply realistic material properties
        let material = SCNMaterial()
        material.diffuse.contents = NSColor.systemBlue
        material.specular.contents = NSColor.white
        material.shininess = 0.8
        material.transparency = 0.9
        bladeGeometry.materials = [material]
        
        // Add blade to scene
        scene.rootNode.addChildNode(bladeNode!)
        
        isLoading = false
        return scene
    }
    
    /// ## Update Camera Position
    /// Moves the camera to a new position in 3D space
    /// - Parameter position: New camera position as SIMD3<Float>
    public func updateCamera(position: SIMD3<Float>) {
        cameraNode.position = SCNVector3(position.x, position.y, position.z)
    }
    
    // MARK: - Private Methods
    
    /// ## Setup Scene Environment
    /// Configures default lighting, camera, and scene properties
    /// Creates a professional visualization environment
    private func setupScene() {
        // Setup camera with default position
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 15)
        scene.rootNode.addChildNode(cameraNode)
        
        // Add ambient light for base illumination
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light!.type = .ambient
        ambientLight.light!.color = NSColor(white: 0.3, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
        
        // Add directional light for highlights and shadows
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light!.type = .directional
        directionalLight.light!.color = NSColor(white: 0.8, alpha: 1.0)
        directionalLight.position = SCNVector3(10, 10, 10)
        directionalLight.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(directionalLight)
    }
    
    /// ## Create SceneKit Geometry
    /// Converts custom blade mesh to SceneKit geometry format
    /// - Parameter mesh: Source blade mesh data
    /// - Returns: SceneKit geometry ready for rendering
    private func createGeometry(from mesh: BladeMesh) -> SCNGeometry {
        var vertices: [SCNVector3] = []
        var indices: [Int32] = []
        
        // Convert custom vertices to SceneKit format
        for vertex in mesh.vertices {
            vertices.append(SCNVector3(vertex.x, vertex.y, vertex.z))
        }
        
        // Convert faces to triangle indices
        for face in mesh.faces {
            for vertexIndex in face {
                indices.append(Int32(vertexIndex))
            }
        }
        
        // Create SceneKit geometry sources
        let vertexSource = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        
        return SCNGeometry(sources: [vertexSource], elements: [element])
    }
}
