//
//  CalculationViewModel.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation
import SwiftUI
import Combine

/// # Calculation View Model
/// Main view model for propeller calculation and results management
/// Handles user input, calculation execution, and result presentation
/// Coordinates between physics calculations, 3D rendering, and user interface
public class CalculationViewModel: ObservableObject {
    
    // MARK: - Published Properties
        
        /// ## Calculation Parameters
        /// User-editable parameters for propeller design
        /// Contains all input values needed for BEMT calculation
        /// Updates trigger recalculation when auto-recalculate is enabled
        @Published public var parameters = CalculationParameters()
        
        /// ## Calculation Results
        /// Results from the latest BEMT calculation
        /// Contains performance metrics, convergence data, and detailed analysis
        /// Nil when no calculation has been performed or results are invalid
        @Published public var calculationResult: BEMTResult?
        
        /// ## Blade Geometry
        /// Current blade geometry definition used in calculations
        /// Derived from parameters and used for visualization
        /// Updated when parameters change or new calculation completes
        @Published public var bladeGeometry: BladeGeometry?
        
        /// ## Blade Mesh
        /// 3D mesh representation of the current blade design
        /// Contains vertices, faces, and normals for 3D rendering
        /// Used by SceneKit for visualization and export functions
        @Published public var bladeMesh: BladeMesh?
        
    /// ## Calculation Error
        /// Contains error message if calculation fails
        /// Displayed to user with appropriate error handling UI
        /// Cleared when new calculation starts or parameters change
        @Published public var calculationError: String?
    
    /// ## Calculation Status
        /// Indicates whether a calculation is currently in progress
        /// Used to show progress indicators and disable input controls
        /// Prevents multiple simultaneous calculations
        @Published public var isCalculating = false
    
    /// ## Geometry Update Trigger
        /// Used to trigger UI updates when geometry changes
        /// Provides workaround for Equatable requirements in SwiftUI
        @Published public var geometryUpdateTrigger: Bool = false
    
    // MARK: - Private Properties
        
        /// ## BEMT Calculator Instance
        /// Core physics calculator for propeller performance
        /// Handles all aerodynamic and performance calculations using BEMT theory
        /// Runs computationally intensive operations on background threads
        private let calculator = BEMTCalculator()
    
    /// ## Mesh Generator Instance
        /// Generates 3D mesh from blade geometry definitions
        /// Creates vertices and faces for visualization and export
        /// Supports different levels of detail for performance/quality balance
        private let meshGenerator = BladeMeshGenerator()
    
    /// ## Combine Cancellables
        /// Storage for Combine subscribers and asynchronous operations
        /// Ensures proper memory management and cancellation of ongoing work
        private var cancellables = Set<AnyCancellable>()

        // MARK: - Public Methods
        
        /// ## Calculate Blade Performance
        /// Main method to execute complete propeller calculation pipeline
        /// Runs asynchronously to keep UI responsive during computation
        /// Updates all published properties upon completion
        /// Handles errors gracefully and provides user feedback
    public func calculateBlade() {
            // Validate parameters before calculation
            let validation = validateParameters()
            guard validation.isValid else {
                calculationError = validation.errorMessage ?? "Invalid parameters"
                return
            }
            
            // Reset previous state
            isCalculating = true
            calculationError = nil
            calculationResult = nil
            
            // Execute calculation on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard let self = self else { return }
                    
                    do {
                        // Create drone specifications from user parameters
                        let drone = DroneSpecs(
                            mass: self.parameters.droneMass,
                            maxSpeed: self.parameters.maxSpeed,
                            numberOfBlades: self.parameters.numberOfBlades,
                            numberOfMotors: self.parameters.numberOfMotors,
                            operatingAltitude: self.parameters.operatingAltitude
                        )
                        
                        // Create blade geometry using distribution functions
                        let blade = self.createBladeGeometry()
                        
                        // Perform comprehensive BEMT calculation
                        let result = self.calculator.calculatePropeller(
                            drone: drone,
                            blade: blade,
                            airfoil: AirfoilDatabase.naca4412,
                            rpm: self.parameters.targetRPM,
                            flightSpeed: 0.0,  // Hover condition
                            includeElementData: true  // For detailed analysis
                        )
                        
                        // Generate high-quality 3D mesh for visualization
                        let mesh = self.meshGenerator.generateMesh(for: blade, segments: 50)
                        
                        // Update UI on main thread
                        DispatchQueue.main.async {
                            self.calculationResult = result
                            self.updateBladeGeometry(blade)
                            self.bladeMesh = mesh
                            self.isCalculating = false
                            
                            // Trigger geometry update for UI
                            self.geometryUpdateTrigger.toggle()
                            
                            // Notify subscribers of successful calculation
                            self.objectWillChange.send()
                            
                            print("Calculation completed successfully: \(result.thrust) N thrust, \(result.efficiency * 100)% efficiency")
                                            }
                                            
                                        } catch {
                                            // Handle calculation errors gracefully
                                            DispatchQueue.main.async {
                                                self.calculationError = error.localizedDescription
                                                self.isCalculating = false
                                                self.objectWillChange.send()
                                                
                                                print("Calculation error: \(error.localizedDescription)")
                }
            }
        }
    }


    
    /// ## Update Blade Geometry
    /// Updates the blade geometry and triggers necessary UI updates
    /// - Parameter geometry: New blade geometry to set
    public func updateBladeGeometry(_ geometry: BladeGeometry) {
        bladeGeometry = geometry
        // Force UI update by toggling the trigger
        geometryUpdateTrigger.toggle()
    }
    
    /// ## Export as STL Format
    /// Exports current blade mesh to STL file format for 3D printing
    /// STL is industry standard for rapid prototyping and manufacturing
    /// - Returns: URL to temporary STL file, or nil if export fails
    public func exportAsSTL() -> URL? {
        guard let mesh = bladeMesh else {
            calculationError = "No blade mesh available for export"
            return nil
        }
        
        do {
            let url = STLExporter.export(mesh: mesh, filename: "propeller_blade")
            if url == nil {
                calculationError = "STL export failed"
            } else {
                print("STL export successful: \(url?.path ?? "unknown")")
            }
            return url
        }
    }
    
    /// ## Export as OBJ Format
    /// Exports current blade mesh to OBJ file format for 3D modeling
    /// OBJ is widely used in CAD software and 3D graphics applications
    /// - Returns: URL to temporary OBJ file, or nil if export fails
    public func exportAsOBJ() -> URL? {
        guard let mesh = bladeMesh else {
            calculationError = "No blade mesh available for export"
            return nil
        }
        
        do {
            let url = OBJExporter.export(mesh: mesh, filename: "propeller_blade")
            if url == nil {
                calculationError = "OBJ export failed"
            } else {
                print("OBJ export successful: \(url?.path ?? "unknown")")
            }
            return url
        }
    }
    
    /// ## Reset Calculation
    /// Clears current results and resets to initial state
    /// Useful for starting new designs or clearing errors
    public func resetCalculation() {
        calculationResult = nil
        bladeGeometry = nil
        bladeMesh = nil
        calculationError = nil
        geometryUpdateTrigger.toggle()
        objectWillChange.send()
        
        print("Calculation reset")
    }
    
    /// ## Reset Parameters to Defaults
    /// Restores all parameters to their default values
    /// Useful for starting fresh or recovering from invalid states
    public func resetParametersToDefaults() {
        parameters = CalculationParameters()
        objectWillChange.send()
        print("Parameters reset to defaults")
    }
    
    /// ## Validate Parameters
    /// Checks if current parameters are within valid ranges
    /// Provides user feedback for invalid inputs before calculation
    /// - Returns: Boolean indicating parameter validity and optional error message
    public func validateParameters() -> (isValid: Bool, errorMessage: String?) {
        // Check mass validity
        if parameters.droneMass <= 0 {
            return (false, "Drone mass must be greater than zero")
        }
        
        if parameters.droneMass > 50 {
            return (false, "Drone mass cannot exceed 50 kg")
        }
        
        // Check speed validity
        if parameters.maxSpeed < 0 {
            return (false, "Maximum speed cannot be negative")
        }
        
        if parameters.maxSpeed > 200 {
            return (false, "Maximum speed cannot exceed 200 m/s")
        }
        
        // Check blade count validity
        if parameters.numberOfBlades < 1 {
            return (false, "At least one blade is required")
        }
        
        if parameters.numberOfBlades > 8 {
            return (false, "Maximum 8 blades per propeller supported")
        }
        
        // Check motor count validity
        if parameters.numberOfMotors < 1 {
            return (false, "At least one motor is required")
        }
        
        if parameters.numberOfMotors > 12 {
            return (false, "Maximum 12 motors supported")
        }
        
        // Check altitude validity
        if parameters.operatingAltitude < 0 {
            return (false, "Operating altitude cannot be negative")
        }
        
        if parameters.operatingAltitude > 10000 {
            return (false, "Operating altitude cannot exceed 10,000 meters")
        }
        
        // Check geometry validity
        if parameters.bladeRadius <= parameters.rootCutout {
            return (false, "Blade radius must be greater than root cutout")
        }
        
        if parameters.bladeRadius <= 0 {
            return (false, "Blade radius must be greater than zero")
        }
        
        if parameters.bladeRadius > 1.0 {
            return (false, "Blade radius cannot exceed 1.0 meter")
        }
        
        if parameters.rootCutout < 0 {
            return (false, "Root cutout cannot be negative")
        }
        
        if parameters.rootCutout > 0.2 {
            return (false, "Root cutout cannot exceed 0.2 meters")
        }
        
        // Check RPM validity
        if parameters.targetRPM <= 0 {
            return (false, "Target RPM must be greater than zero")
        }
        
        if parameters.targetRPM > 50000 {
            return (false, "Target RPM cannot exceed 50,000 RPM")
        }
        
        return (true, nil)
    }
    
    /// ## Load Preset Parameters
    /// Applies predefined parameter sets for common drone configurations
    /// Useful for quick starts and educational purposes
    /// - Parameter preset: Preset configuration to load
    public func loadPreset(_ preset: DronePreset) {
        switch preset {
        case .racingQuadcopter:
            parameters = CalculationParameters(
                droneMass: 1.2,
                maxSpeed: 35.0,
                numberOfBlades: 2,
                numberOfMotors: 4,
                operatingAltitude: 100.0,
                bladeRadius: 0.127,
                rootCutout: 0.015,
                targetRPM: 8000
            )
            
        case .cinematicHexacopter:
            parameters = CalculationParameters(
                droneMass: 3.5,
                maxSpeed: 20.0,
                numberOfBlades: 3,
                numberOfMotors: 6,
                operatingAltitude: 200.0,
                bladeRadius: 0.152,
                rootCutout: 0.020,
                targetRPM: 5000
            )
            
        case .heavyLiftOctocopter:
            parameters = CalculationParameters(
                droneMass: 8.0,
                maxSpeed: 15.0,
                numberOfBlades: 3,
                numberOfMotors: 8,
                operatingAltitude: 50.0,
                bladeRadius: 0.178,
                rootCutout: 0.025,
                targetRPM: 3500
            )
            
        case .microDrone:
            parameters = CalculationParameters(
                droneMass: 0.3,
                maxSpeed: 15.0,
                numberOfBlades: 2,
                numberOfMotors: 4,
                operatingAltitude: 50.0,
                bladeRadius: 0.076,
                rootCutout: 0.010,
                targetRPM: 12000
            )
        }
        
        objectWillChange.send()
        print("Loaded preset: \(preset)")
    }
    
    /// ## Get Calculation Summary
    /// Provides formatted summary of current calculation results
    /// Useful for reports, sharing, or quick overview
    /// - Returns: Formatted string with key performance metrics
    public func getCalculationSummary() -> String {
        guard let result = calculationResult else {
            return "No calculation results available"
        }
        
        return """
        Propeller Design Summary
        ========================
        Thrust: \(String(format: "%.2f", result.thrust)) N
        Power: \(String(format: "%.1f", result.power)) W
        Torque: \(String(format: "%.3f", result.torque)) N·m
        Efficiency: \(String(format: "%.1f", result.efficiency * 100))%
        Convergence: \(result.convergenceInfo.converged ? "Achieved" : "Failed")
        Iterations: \(result.convergenceInfo.iterations)
        """
    }
    
    /// ## Estimate Calculation Time
    /// Provides rough estimate of calculation duration
    /// Helps set user expectations for computational tasks
    /// - Returns: Estimated time in seconds
    public func estimateCalculationTime() -> TimeInterval {
        // Simple heuristic based on parameter complexity
        var complexity = 0.0
        
        complexity += Double(parameters.numberOfBlades) * 0.5
        complexity += (parameters.bladeRadius - 0.1) * 10.0
        complexity += (parameters.targetRPM / 1000) * 0.3
        
        return max(1.0, min(10.0, complexity))
    }
    
    // MARK: - Private Methods
    
    /// ## Setup Bindings
    /// Configures reactive programming bindings and observers
    /// Handles automatic updates and state synchronization
    private func setupBindings() {
        // Monitor parameter changes for auto-recalculation
        $parameters
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] newParameters in
                self?.handleParametersChange(newParameters)
            }
            .store(in: &cancellables)
        
        // Monitor calculation status for UI updates
        $isCalculating
            .sink { [weak self] isCalculating in
                if isCalculating {
                    print("Calculation started...")
                } else {
                    print("Calculation finished")
                }
            }
            .store(in: &cancellables)
    }
    
    /// ## Handle Parameters Change
    /// Processes parameter changes and triggers appropriate actions
    /// - Parameter newParameters: Updated parameter values
    private func handleParametersChange(_ newParameters: CalculationParameters) {
        // Auto-recalculate if enabled and parameters are valid
        if UserDefaults.standard.bool(forKey: "autoRecalculate"),
           validateParameters().isValid,
           !isCalculating {
            calculateBlade()
        }
        
        // Update dependent properties even if not recalculating
        updateDependentProperties()
    }
    
    /// ## Update Dependent Properties
    /// Updates derived properties that depend on current parameters
    /// Maintains consistency in the view model state
    private func updateDependentProperties() {
        // Create temporary geometry for preview purposes
        let previewGeometry = createBladeGeometry()
        
        // Only update if significantly different from current
        if bladeGeometry == nil || !areGeometriesSimilar(bladeGeometry!, previewGeometry) {
            bladeGeometry = previewGeometry
            geometryUpdateTrigger.toggle()
        }
    }
    
    /// ## Create Blade Geometry from Parameters
    /// Generates blade geometry based on current parameters
    /// - Returns: Configured BladeGeometry instance
    private func createBladeGeometry() -> BladeGeometry {
        return BladeGeometry(
            radius: parameters.bladeRadius,
            rootCutout: parameters.rootCutout,
            chordDistribution: { radialPosition in
                // Linear chord distribution from root to tip
                let rootChord = 0.025  // 25mm at root
                let tipChord = 0.01    // 10mm at tip
                return rootChord + (tipChord - rootChord) * radialPosition
            },
            twistDistribution: { radialPosition in
                // Non-linear twist distribution with root bias
                let rootTwist = 0.35   // ~20 degrees at root
                let tipTwist = 0.12    // ~7 degrees at tip
                return rootTwist + (tipTwist - rootTwist) * pow(radialPosition, 1.5)
            }
        )
    }
    
    /// ## Compare Geometry Similarity
    /// Determines if two geometries are similar enough to avoid unnecessary updates
    /// - Parameters:
    ///   - a: First geometry to compare
    ///   - b: Second geometry to compare
    /// - Returns: Boolean indicating if geometries are similar
    private func areGeometriesSimilar(_ a: BladeGeometry, _ b: BladeGeometry) -> Bool {
        // Compare key properties with tolerance
        let radiusSimilar = abs(a.radius - b.radius) < 0.001
        let cutoutSimilar = abs(a.rootCutout - b.rootCutout) < 0.001
        
        return radiusSimilar && cutoutSimilar
    }
}

// MARK: - Supporting Types

/// ## Drone Preset Configurations
/// Predefined parameter sets for common drone types
/// Helps users get started quickly with realistic configurations
public enum DronePreset: String, CaseIterable {
    case racingQuadcopter      // High-speed, agile racing drone
    case cinematicHexacopter   // Smooth, stable camera platform
    case heavyLiftOctocopter   // High-payload industrial drone
    case microDrone           // Small, lightweight drone
    
    /// ## Display Name
    /// User-friendly name for UI presentation
    public var displayName: String {
        switch self {
        case .racingQuadcopter: return "Racing Quadcopter"
        case .cinematicHexacopter: return "Cinematic Hexacopter"
        case .heavyLiftOctocopter: return "Heavy Lift Octocopter"
        case .microDrone: return "Micro Drone"
        }
    }
    
    /// ## Description
    /// Detailed description of the preset configuration
    public var description: String {
        switch self {
        case .racingQuadcopter:
            return "High-performance racing drone with aggressive props"
        case .cinematicHexacopter:
            return "Smooth aerial platform for camera work"
        case .heavyLiftOctocopter:
            return "Industrial drone for heavy payloads"
        case .microDrone:
            return "Small lightweight drone for indoor use"
        }
    }
}

/// ## Calculation Parameters Structure
/// Complete set of user-configurable input parameters
/// Used for both calculation and visualization
public struct CalculationParameters: Equatable {
    
    // MARK: - Drone Properties
    
    /// ## Drone Mass
    /// Total mass of drone including payload in kilograms
    /// Directly affects required thrust and power consumption
    public var droneMass: Double
    
    /// ## Maximum Speed
    /// Design maximum horizontal flight speed in meters per second
    /// Influences propeller design for different flight regimes
    public var maxSpeed: Double
    
    /// ## Number of Blades
    /// Blades per propeller (affects solidity and efficiency)
    /// Typically 2-4 blades for most drone applications
    public var numberOfBlades: Int
    
    /// ## Number of Motors
    /// Total propulsion units on the drone
    /// Determines thrust distribution and redundancy
    public var numberOfMotors: Int
    
    /// ## Operating Altitude
    /// Typical mission altitude above sea level in meters
    /// Affects air density and propeller performance
    public var operatingAltitude: Double
    
    // MARK: - Blade Geometry Properties
    
    /// ## Blade Radius
    /// Total length from rotation center to blade tip in meters
    /// Primary determinant of swept area and thrust capacity
    public var bladeRadius: Double
    
    /// ## Root Cutout
    /// Non-aerodynamic section at blade root in meters
    /// Accommodates hub assembly and mounting hardware
    public var rootCutout: Double
    
    // MARK: - Performance Properties
    
    /// ## Target RPM
    /// Design rotational speed in revolutions per minute
    /// Balances efficiency, noise, and structural limits
    public var targetRPM: Double
    
    // MARK: - Initialization
    
    /// ## Default Initializer
    /// Sets reasonable default values for new designs
    /// Based on typical racing quadcopter configuration
    public init() {
        self.droneMass = 1.5
        self.maxSpeed = 25.0
        self.numberOfBlades = 2
        self.numberOfMotors = 4
        self.operatingAltitude = 100.0
        self.bladeRadius = 0.127
        self.rootCutout = 0.015
        self.targetRPM = 6500
    }
    
    /// ## Custom Initializer
    /// Creates parameters with specific values for advanced users
    public init(droneMass: Double, maxSpeed: Double, numberOfBlades: Int,
                numberOfMotors: Int, operatingAltitude: Double,
                bladeRadius: Double, rootCutout: Double, targetRPM: Double) {
        self.droneMass = droneMass
        self.maxSpeed = maxSpeed
        self.numberOfBlades = numberOfBlades
        self.numberOfMotors = numberOfMotors
        self.operatingAltitude = operatingAltitude
        self.bladeRadius = bladeRadius
        self.rootCutout = rootCutout
        self.targetRPM = targetRPM
    }
    
    // MARK: - Equatable Conformance
    
    /// ## Equatable Implementation
    /// Compares all properties for equality
    public static func == (lhs: CalculationParameters, rhs: CalculationParameters) -> Bool {
        return lhs.droneMass == rhs.droneMass &&
               lhs.maxSpeed == rhs.maxSpeed &&
               lhs.numberOfBlades == rhs.numberOfBlades &&
               lhs.numberOfMotors == rhs.numberOfMotors &&
               lhs.operatingAltitude == rhs.operatingAltitude &&
               lhs.bladeRadius == rhs.bladeRadius &&
               lhs.rootCutout == rhs.rootCutout &&
               lhs.targetRPM == rhs.targetRPM
    }
}

// MARK: - Preview Support

#if DEBUG
/// ## Mock Calculation View Model
/// Provides sample data for SwiftUI previews and testing
/// Allows UI development without running actual calculations
class MockCalculationViewModel: CalculationViewModel {
    override init() {
        
        super.init()
        // Set up mock data for previews
        self.setupMockData()
    }
    
    /// ## Setup Mock Data
    /// Configures the view model with realistic sample data for previews
    private func setupMockData() {
        // Set mock parameters
        self.parameters = CalculationParameters(
            droneMass: 1.5,
            maxSpeed: 25.0,
            numberOfBlades: 2,
            numberOfMotors: 4,
            operatingAltitude: 100.0,
            bladeRadius: 0.127,
            rootCutout: 0.015,
            targetRPM: 6500
        )
        
        // Create mock calculation results
        self.calculationResult = BEMTResult(
            thrust: 45.2,
            torque: 0.85,
            power: 320.5,
            efficiency: 0.72,
            convergenceInfo: ConvergenceInfo(
                iterations: 8,
                maxResidual: 1e-9,
                converged: true,
                residualHistory: [1e-3, 1e-5, 1e-7, 1e-9],
                elementWiseIterations: [8, 8, 7, 8, 9, 8]
            ),
            elementData: [
                BladeElementData(
                    radius: 0.03,
                    thrust: 0.5,
                    torque: 0.01,
                    alpha: 0.12,
                    cl: 0.8,
                    cd: 0.02,
                    reynolds: 150000,
                    mach: 0.15,
                    iterations: 8
                ),
                BladeElementData(
                    radius: 0.06,
                    thrust: 1.2,
                    torque: 0.025,
                    alpha: 0.10,
                    cl: 0.75,
                    cd: 0.018,
                    reynolds: 180000,
                    mach: 0.18,
                    iterations: 8
                )
            ]
        )
        
        // Create sample geometry
        self.bladeGeometry = BladeGeometry(
            radius: 0.127,
            rootCutout: 0.015,
            chordDistribution: { r in 0.025 + (0.01 - 0.025) * r },
            twistDistribution: { r in 0.35 + (0.12 - 0.35) * pow(r, 1.5) }
        )
        
        // Generate sample mesh
        self.bladeMesh = BladeMeshGenerator().generateMesh(
            for: self.bladeGeometry!,
            segments: 20
        )
        
        self.isCalculating = false
    }
    
    /// ## Mock calculation for preview purposes
    override func calculateBlade() {
        isCalculating = true
        
        // Simulate calculation delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isCalculating = false
            self.calculationError = nil
            
            // Update with new mock results
            self.calculationResult = BEMTResult(
                thrust: Double.random(in: 40...50),
                torque: Double.random(in: 0.7...0.9),
                power: Double.random(in: 300...350),
                efficiency: Double.random(in: 0.65...0.75),
                convergenceInfo: ConvergenceInfo(
                    iterations: Int.random(in: 5...10),
                    maxResidual: 1e-9,
                    converged: true,
                    residualHistory: [1e-3, 1e-5, 1e-7, 1e-9],
                    elementWiseIterations: [8, 8, 7, 8, 9, 8]
                ),
                elementData: nil
            )
            
            self.objectWillChange.send()
        }
    }
}
#endif

// MARK: - User Defaults Extension

extension UserDefaults {
    /// ## Auto Recalculate Setting
    /// Whether to automatically recalculate when parameters change
    static var autoRecalculate: Bool {
        get {
            return standard.bool(forKey: "autoRecalculate")
        }
        set {
            standard.set(newValue, forKey: "autoRecalculate")
        }
    }
    
    /// ## High Quality Render Setting
    /// Whether to use high-quality rendering for 3D views
    static var highQualityRender: Bool {
        get {
            return standard.bool(forKey: "highQualityRender")
        }
        set {
            standard.set(newValue, forKey: "highQualityRender")
        }
    }
    
    /// ## Default Export Format
    /// Preferred file format for 3D model exports
    static var defaultExportFormat: String {
        get {
            return standard.string(forKey: "defaultExportFormat") ?? "STL"
        }
        set {
            standard.set(newValue, forKey: "defaultExportFormat")
        }
    }
}
