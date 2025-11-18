//
//  GeometryModels.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation
import CoreGraphics

/// # Drone Specifications Model
/// Contains all operational parameters needed for propeller design calculations
/// Represents the drone's physical characteristics and performance requirements
public struct DroneSpecs {
    
    // MARK: - Public Properties
    
    /// ## Drone Mass
    /// Total mass of the drone including all components and payload in kilograms
    /// Used to calculate required thrust for hover and maneuver
    public let mass: Double
    
    /// ## Maximum Speed
    /// Maximum designed flight speed in meters per second
    /// Affects propeller design for different flight regimes
    public let maxSpeed: Double
    
    /// ## Number of Blades per Propeller
    /// Number of blades on each propeller
    /// Affects solidity, efficiency, and noise characteristics
    public let numberOfBlades: Int
    
    /// ## Number of Motors
    /// Total number of motors on the drone
    /// Used to calculate thrust distribution per motor
    public let numberOfMotors: Int
    
    /// ## Operating Altitude
    /// Typical operational altitude in meters above sea level
    /// Affects air density and propeller performance
    public let operatingAltitude: Double
    
    // MARK: - Initialization
    
    /// ## Drone Specifications Initializer
    /// Creates a new drone specification set
    /// - Parameters:
    ///   - mass: Total drone mass in kg
    ///   - maxSpeed: Maximum speed in m/s
    ///   - numberOfBlades: Blades per propeller
    ///   - numberOfMotors: Total motor count
    ///   - operatingAltitude: Operational altitude in meters
    public init(mass: Double, maxSpeed: Double, numberOfBlades: Int, numberOfMotors: Int, operatingAltitude: Double) {
        self.mass = mass
        self.maxSpeed = maxSpeed
        self.numberOfBlades = numberOfBlades
        self.numberOfMotors = numberOfMotors
        self.operatingAltitude = operatingAltitude
    }
}

/// # Blade Geometry Model
/// Defines the geometric properties of a propeller blade including radius, chord distribution, and twist distribution
/// Used for both calculation and visualization purposes
public struct BladeGeometry: Equatable {
    
    // MARK: - Public Properties
    
    /// ## Blade Radius
    /// Total radius of the blade from center to tip in meters
    /// Determines the swept area and overall size of the propeller
    public let radius: Double
    
    /// ## Root Cutout Distance
    /// Distance from rotation center to the start of the aerodynamic blade section in meters
    /// Accounts for hub and mounting hardware
    public let rootCutout: Double
    
    // MARK: - Equatable Conformance
    
    /// ## Equatable Implementation
    /// Compares two BladeGeometry instances for equality
    /// Note: Cannot compare closure-based distributions, so we compare based on sampled values
    public static func == (lhs: BladeGeometry, rhs: BladeGeometry) -> Bool {
        // Compare basic properties
        guard lhs.radius == rhs.radius,
              lhs.rootCutout == rhs.rootCutout else {
            return false
        }
        
        // Sample distribution functions at key points to compare
        let samplePoints = [0.0, 0.25, 0.5, 0.75, 1.0]
        
        for point in samplePoints {
            // Sample chord distribution
            let lhsChord = lhs.getChord(at: point)
            let rhsChord = rhs.getChord(at: point)
            
            // Sample twist distribution
            let lhsTwist = lhs.getTwist(at: point)
            let rhsTwist = rhs.getTwist(at: point)
            
            // Compare sampled values with tolerance
            if abs(lhsChord - rhsChord) > 1e-10 || abs(lhsTwist - rhsTwist) > 1e-10 {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Private Properties (Closure-based distributions)
    
    /// ## Chord Distribution Function
    /// Function that defines how chord length varies along the blade radius
    /// - Parameter radialPosition: Normalized radial position (0 at root, 1 at tip)
    /// - Returns: Chord length in meters at specified radial position
    let chordDistribution: (Double) -> Double
    
    /// ## Twist Distribution Function
    /// Function that defines how blade twist varies along the radius
    /// - Parameter radialPosition: Normalized radial position (0 at root, 1 at tip)
    /// - Returns: Twist angle in radians at specified radial position
    let twistDistribution: (Double) -> Double
    
    // MARK: - Initialization
    
    /// ## Blade Geometry Initializer
    /// Creates a new blade geometry definition
    /// - Parameters:
    ///   - radius: Total blade radius in meters
    ///   - rootCutout: Root cutout distance in meters
    ///   - chordDistribution: Function defining chord length distribution
    ///   - twistDistribution: Function defining twist distribution
    public init(radius: Double, rootCutout: Double,
                chordDistribution: @escaping (Double) -> Double,
                twistDistribution: @escaping (Double) -> Double) {
        self.radius = radius
        self.rootCutout = rootCutout
        self.chordDistribution = chordDistribution
        self.twistDistribution = twistDistribution
    }
    
    // MARK: - Public Methods
    
    /// ## Get Chord at Position
    /// Public accessor for chord distribution function
    /// - Parameter radialPosition: Normalized radial position (0-1)
    /// - Returns: Chord length in meters
    public func getChord(at radialPosition: Double) -> Double {
        return chordDistribution(radialPosition)
    }
    
    /// ## Get Twist at Position
    /// Public accessor for twist distribution function
    /// - Parameter radialPosition: Normalized radial position (0-1)
    /// - Returns: Twist angle in radians
    public func getTwist(at radialPosition: Double) -> Double {
        return twistDistribution(radialPosition)
    }
}

/// # 3D Point Structure
/// Represents a point in 3D space with double precision coordinates
/// Used for mesh generation and 3D modeling
public struct BladePoint3D {
    
    // MARK: - Public Properties
    
    /// ## X Coordinate
    /// Coordinate along the longitudinal axis (typically blade radial direction)
    public let x: Double
    
    /// ## Y Coordinate
    /// Coordinate along the horizontal axis (typically chordwise direction)
    public let y: Double
    
    /// ## Z Coordinate
    /// Coordinate along the vertical axis (typically thickness direction)
    public let z: Double
    
    // MARK: - Initialization
    
    /// ## 3D Point Initializer
    /// Creates a new 3D point with specified coordinates
    /// - Parameters:
    ///   - x: X coordinate value
    ///   - y: Y coordinate value
    ///   - z: Z coordinate value
    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

/// # Blade Mesh Model
/// Complete 3D mesh representation of a propeller blade
/// Contains vertices, faces, and normals for 3D rendering and export
public struct BladeMesh {
    
    // MARK: - Public Properties
    
    /// ## Mesh Vertices
    /// Array of 3D points defining the vertex positions of the mesh
    /// Each vertex represents a corner point of the blade surface
    public let vertices: [BladePoint3D]
    
    /// ## Mesh Faces
    /// 2D array defining the triangular faces of the mesh
    /// Each face contains 3 indices pointing to vertices array
    public let faces: [[Int]]
    
    /// ## Vertex Normals
    /// Array of normal vectors for each vertex
    /// Used for lighting calculations and smooth shading
    public let normals: [BladePoint3D]
    
    // MARK: - Initialization
    
    /// ## Blade Mesh Initializer
    /// Creates a complete blade mesh representation
    /// - Parameters:
    ///   - vertices: Array of vertex positions
    ///   - faces: Array of face definitions
    ///   - normals: Array of vertex normals
    public init(vertices: [BladePoint3D], faces: [[Int]], normals: [BladePoint3D]) {
        self.vertices = vertices
        self.faces = faces
        self.normals = normals
    }
}
