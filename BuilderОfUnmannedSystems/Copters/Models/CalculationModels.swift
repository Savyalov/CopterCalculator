//
//  CalculationModels.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation

/// # BEMT Calculation Result
/// Contains comprehensive results from Blade Element Momentum Theory calculation
/// Includes performance metrics, convergence data, and detailed element information
public struct BEMTResult {
    
    // MARK: - Public Properties
    
    /// ## Total Thrust
    /// Total thrust produced by all propellers in Newtons
    /// Primary performance metric for propulsion system
    public let thrust: Double
    
    /// ## Total Torque
    /// Total torque required to drive all propellers in Newton-meters
    /// Used for motor selection and power calculation
    public let torque: Double
    
    /// ## Total Power
    /// Total mechanical power consumed by all propellers in Watts
    /// Calculated as torque × angular velocity
    public let power: Double
    
    /// ## Propeller Efficiency
    /// Overall efficiency of the propeller system (0.0 to 1.0)
    /// Ratio of useful power to input power
    public let efficiency: Double
    
    /// ## Convergence Information
    /// Detailed data about the iterative solution process
    /// Includes iteration count, residuals, and convergence status
    public let convergenceInfo: ConvergenceInfo
    
    /// ## Element Data
    /// Optional detailed data for each blade element
    /// Provides insight into radial distribution of forces and flow conditions
    public let elementData: [BladeElementData]?
    
    // MARK: - Initialization
    
    /// ## BEMT Result Initializer
    /// Creates a complete BEMT calculation result
    /// - Parameters:
    ///   - thrust: Total thrust in N
    ///   - torque: Total torque in N·m
    ///   - power: Total power in W
    ///   - efficiency: Propeller efficiency
    ///   - convergenceInfo: Convergence data
    ///   - elementData: Optional element-wise data
    public init(thrust: Double, torque: Double, power: Double, efficiency: Double,
                convergenceInfo: ConvergenceInfo, elementData: [BladeElementData]?) {
        self.thrust = thrust
        self.torque = torque
        self.power = power
        self.efficiency = efficiency
        self.convergenceInfo = convergenceInfo
        self.elementData = elementData
    }
}

/// # Convergence Information
/// Detailed data about the iterative solution process in BEMT calculation
/// Helps users understand the reliability and accuracy of results
public struct ConvergenceInfo {
    
    // MARK: - Public Properties
    
    /// ## Iteration Count
    /// Number of iterations performed to reach convergence
    /// Higher values may indicate difficult convergence conditions
    public let iterations: Int
    
    /// ## Maximum Residual
    /// Largest residual value at convergence
    /// Indicates how well the solution satisfied the equations
    public let maxResidual: Double
    
    /// ## Convergence Status
    /// Whether the iterative process successfully converged
    /// False indicates the solution may not be reliable
    public let converged: Bool
    
    /// ## Residual History
    /// Array of residual values from each iteration
    /// Shows the convergence trajectory and stability
    public let residualHistory: [Double]
    
    /// ## Element-wise Iterations
    /// Number of iterations required for each blade element
    /// Identifies problematic radial positions
    public let elementWiseIterations: [Int]
    
    // MARK: - Initialization
    
    /// ## Convergence Info Initializer
    /// Creates convergence information for BEMT results
    /// - Parameters:
    ///   - iterations: Number of iterations
    ///   - maxResidual: Maximum residual value
    ///   - converged: Convergence status
    ///   - residualHistory: History of residuals
    ///   - elementWiseIterations: Iterations per element
    public init(iterations: Int, maxResidual: Double, converged: Bool,
                residualHistory: [Double], elementWiseIterations: [Int]) {
        self.iterations = iterations
        self.maxResidual = maxResidual
        self.converged = converged
        self.residualHistory = residualHistory
        self.elementWiseIterations = elementWiseIterations
    }
}

/// # Blade Element Data
/// Detailed aerodynamic and performance data for individual blade elements
/// Used for advanced analysis and optimization
public struct BladeElementData {
    
    // MARK: - Public Properties
    
    /// ## Radial Position
    /// Distance from rotation center to element center in meters
    /// Identifies the location along the blade span
    public let radius: Double
    
    /// ## Element Thrust
    /// Thrust contribution from this element in Newtons
    /// Shows how thrust is distributed along the blade
    public let thrust: Double
    
    /// ## Element Torque
    /// Torque contribution from this element in Newton-meters
    /// Shows how torque is distributed along the blade
    public let torque: Double
    
    /// ## Angle of Attack
    /// Local angle of attack in radians
    /// Key aerodynamic parameter for each element
    public let alpha: Double
    
    /// ## Lift Coefficient
    /// Local lift coefficient for the airfoil
    /// Determines lifting capability at this element
    public let cl: Double
    
    /// ## Drag Coefficient
    /// Local drag coefficient for the airfoil
    /// Determines drag penalty at this element
    public let cd: Double
    
    /// ## Reynolds Number
    /// Local Reynolds number based on chord and flow conditions
    /// Affects airfoil performance and transition behavior
    public let reynolds: Double
    
    /// ## Mach Number
    /// Local Mach number based on flow velocity
    /// Important for compressibility effects at high speeds
    public let mach: Double
    
    /// ## Iteration Count
    /// Number of iterations required for this element to converge
    /// Indicates numerical difficulty at this radial position
    public let iterations: Int
    
    // MARK: - Initialization
    
    /// ## Blade Element Data Initializer
    /// Creates detailed element data for analysis
    /// - Parameters:
    ///   - radius: Radial position in meters
    ///   - thrust: Thrust contribution in N
    ///   - torque: Torque contribution in N·m
    ///   - alpha: Angle of attack in radians
    ///   - cl: Lift coefficient
    ///   - cd: Drag coefficient
    ///   - reynolds: Reynolds number
    ///   - mach: Mach number
    ///   - iterations: Iteration count
    public init(radius: Double, thrust: Double, torque: Double, alpha: Double, cl: Double,
                cd: Double, reynolds: Double, mach: Double, iterations: Int) {
        self.radius = radius
        self.thrust = thrust
        self.torque = torque
        self.alpha = alpha
        self.cl = cl
        self.cd = cd
        self.reynolds = reynolds
        self.mach = mach
        self.iterations = iterations
    }
}
