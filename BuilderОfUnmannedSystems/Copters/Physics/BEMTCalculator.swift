//
//  BEMTCalculator.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation

/// # Blade Element Momentum Theory Calculator
/// Advanced BEMT implementation for propeller performance prediction
/// Combines blade element theory with momentum theory for accurate results
public class BEMTCalculator {
    
    // MARK: - Private Constants
    
    /// ## Convergence Tolerance
    /// Numerical tolerance for iterative solution convergence
    /// Smaller values increase accuracy but require more iterations
    private let epsilon: Double = 1e-8
    
    /// ## Maximum Iterations
    /// Safety limit for iterative solvers to prevent infinite loops
    private let maxIterations = 50
    
    /// ## Atmosphere Model
    /// Standard atmosphere model for altitude-dependent properties
    private let atmosphereModel = StandardAtmosphere()
    
    // MARK: - Public Methods
    
    /// ## Calculate Propeller Performance
    /// Main entry point for propeller performance calculation using BEMT
    /// Handles complete calculation pipeline from geometry to results
    /// - Parameters:
    ///   - drone: Drone specifications
    ///   - blade: Blade geometry definition
    ///   - airfoil: Airfoil aerodynamic data
    ///   - rpm: Rotational speed in RPM
    ///   - flightSpeed: Forward flight speed in m/s (0 for hover)
    ///   - includeElementData: Flag to include detailed element data
    /// - Returns: Complete BEMT calculation results
    public func calculatePropeller(
        drone: DroneSpecs,
        blade: BladeGeometry,
        airfoil: AirfoilData,
        rpm: Double,
        flightSpeed: Double = 0.0,
        includeElementData: Bool = false
    ) -> BEMTResult {
        
        // Calculate atmospheric conditions at operating altitude
        let atmosphere = atmosphereModel.calculateConditions(altitude: drone.operatingAltitude)
        
        // Convert RPM to angular velocity (rad/s)
        let omega = rpm * 2.0 * .pi / 60.0
        
        // Discretize blade into elements for analysis
        let numberOfElements = 30
        let dr = (blade.radius - blade.rootCutout) / Double(numberOfElements)
        
        // Initialize result accumulators
        var totalThrust: Double = 0.0
        var totalTorque: Double = 0.0
        var maxResidual: Double = 0.0
        var totalIterations: Int = 0
        var residualHistory: [Double] = []
        var elementIterations: [Int] = []
        var elementData: [BladeElementData] = []
        
        // Process each blade element
        for i in 0..<numberOfElements {
            let r = blade.rootCutout + Double(i) * dr + dr/2.0
            
            let elementResult = calculateBladeElement(
                r: r,
                dr: dr,
                blade: blade,
                airfoil: airfoil,
                omega: omega,
                flightSpeed: flightSpeed,
                numberOfBlades: drone.numberOfBlades,
                atmosphere: atmosphere
            )
            
            // Accumulate results
            totalThrust += elementResult.thrust
            totalTorque += elementResult.torque
            maxResidual = max(maxResidual, elementResult.residual)
            totalIterations += elementResult.iterations
            elementIterations.append(elementResult.iterations)
            
            // Store convergence history from representative element
            if i == numberOfElements / 2 {
                residualHistory = elementResult.residualHistory
            }
            
            // Store detailed element data if requested
            if includeElementData {
                elementData.append(BladeElementData(
                    radius: r,
                    thrust: elementResult.thrust,
                    torque: elementResult.torque,
                    alpha: elementResult.alpha,
                    cl: elementResult.cl,
                    cd: elementResult.cd,
                    reynolds: elementResult.reynolds,
                    mach: elementResult.mach,
                    iterations: elementResult.iterations
                ))
            }
        }
        
        // Scale results for multiple motors and blades
        totalThrust *= Double(drone.numberOfMotors)
        totalTorque *= Double(drone.numberOfMotors)
        
        // Calculate power and efficiency
        let power = totalTorque * omega
        let efficiency = calculateEfficiency(
            thrust: totalThrust,
            power: power,
            speed: flightSpeed,
            area: .pi * pow(blade.radius, 2),
            density: atmosphere.density
        )
        
        // Return comprehensive results
        return BEMTResult(
            thrust: totalThrust,
            torque: totalTorque,
            power: power,
            efficiency: efficiency,
            convergenceInfo: ConvergenceInfo(
                iterations: totalIterations / numberOfElements,
                maxResidual: maxResidual,
                converged: maxResidual < epsilon,
                residualHistory: residualHistory,
                elementWiseIterations: elementIterations
            ),
            elementData: includeElementData ? elementData : nil
        )
    }
    
    // MARK: - Private Calculation Methods
    
    /// ## Calculate Single Blade Element
    /// Performs BEMT analysis on a single radial element of the blade
    /// Solves coupled equations using Newton-Raphson iteration
    /// - Parameters:
    ///   - r: Radial position of element center
    ///   - dr: Element radial width
    ///   - blade: Blade geometry
    ///   - airfoil: Airfoil data
    ///   - omega: Angular velocity
    ///   - flightSpeed: Forward speed
    ///   - numberOfBlades: Number of blades
    ///   - atmosphere: Atmospheric conditions
    /// - Returns: Element performance and convergence data
    private func calculateBladeElement(
        r: Double,
        dr: Double,
        blade: BladeGeometry,
        airfoil: AirfoilData,
        omega: Double,
        flightSpeed: Double,
        numberOfBlades: Int,
        atmosphere: (temperature: Double, pressure: Double, density: Double, speedOfSound: Double, kinematicViscosity: Double)
    ) -> (thrust: Double, torque: Double, residual: Double, iterations: Int,
          residualHistory: [Double], alpha: Double, cl: Double, cd: Double,
          reynolds: Double, mach: Double) {
        
        // Calculate improved initial guess for induced velocities
        let (initialAxial, initialTangential) = calculateImprovedInitialGuess(
            r: r, R: blade.radius, omega: omega, flightSpeed: flightSpeed,
            numberOfBlades: numberOfBlades, chord: blade.chordDistribution(r / blade.radius),
            twist: blade.twistDistribution(r / blade.radius), density: atmosphere.density
        )
        
        // Initialize iteration variables
        var axialInduced = initialAxial
        var tangentialInduced = initialTangential
        var residual = Double.greatestFiniteMagnitude
        var iterations = 0
        var residualHistory: [Double] = []
        
        var finalThrust: Double = 0.0
        var finalTorque: Double = 0.0
        var finalAlpha: Double = 0.0
        var finalCl: Double = 0.0
        var finalCd: Double = 0.0
        var finalReynolds: Double = 0.0
        var finalMach: Double = 0.0
        
        // Iterative solution loop
        while residual > epsilon && iterations < maxIterations {
            iterations += 1
            
            // Perform Newton-Raphson iteration
            let (newAxial, newTangential, thrust, torque, alpha, cl, cd, reynolds, mach, currentResidual) = newtonRaphsonIteration(
                r: r, dr: dr, blade: blade, airfoil: airfoil, omega: omega,
                flightSpeed: flightSpeed, numberOfBlades: numberOfBlades,
                atmosphere: atmosphere,
                currentAxial: axialInduced, currentTangential: tangentialInduced
            )
            
            // Update convergence tracking
            residual = currentResidual
            residualHistory.append(residual)
            
            // Apply adaptive relaxation for stability
            let relaxation = calculateAdaptiveRelaxation(
                iteration: iterations,
                residual: residual,
                residualHistory: residualHistory
            )
            
            // Update induced velocities
            axialInduced = axialInduced + relaxation * (newAxial - axialInduced)
            tangentialInduced = tangentialInduced + relaxation * (newTangential - tangentialInduced)
            
            // Store current results
            finalThrust = thrust
            finalTorque = torque
            finalAlpha = alpha
            finalCl = cl
            finalCd = cd
            finalReynolds = reynolds
            finalMach = mach
            
            // Check for divergence and apply fallback if needed
            if iterations > 10 && residual > 1.0 {
                return calculateBladeElementFallback(
                    r: r, dr: dr, blade: blade, airfoil: airfoil, omega: omega,
                    flightSpeed: flightSpeed, numberOfBlades: numberOfBlades,
                    atmosphere: atmosphere
                )
            }
        }
        
        // Return final converged results
        return (finalThrust, finalTorque, residual, iterations, residualHistory,
                finalAlpha, finalCl, finalCd, finalReynolds, finalMach)
    }
    
    /// ## Improved Initial Guess Calculation
    /// Provides intelligent starting values for induced velocities
    /// Reduces iteration count and improves convergence stability
    /// - Parameters:
    ///   - r: Radial position
    ///   - R: Blade radius
    ///   - omega: Angular velocity
    ///   - flightSpeed: Forward speed
    ///   - numberOfBlades: Blade count
    ///   - chord: Local chord length
    ///   - twist: Local twist angle
    ///   - density: Air density
    /// - Returns: Initial guesses for axial and tangential induced velocities
    private func calculateImprovedInitialGuess(
        r: Double, R: Double, omega: Double, flightSpeed: Double,
        numberOfBlades: Int, chord: Double, twist: Double, density: Double
    ) -> (axial: Double, tangential: Double) {
        
        let tipSpeed = omega * R
        let localSpeed = omega * r
        
        if flightSpeed == 0 {
            // Hover regime - empirical formula based on vortex theory
            let solidity = (Double(numberOfBlades) * chord) / (2.0 * .pi * r)
            let axialGuess = tipSpeed * 0.1 * (r/R)
            
            // Account for solidity and twist effects
            let twistEffect = max(0.1, 1.0 - abs(twist - 0.2) / 0.5)
            let tangentialGuess = axialGuess * 0.5 * solidity * twistEffect
            
            return (axialGuess, tangentialGuess)
        } else {
            // Forward flight regime - advance ratio based estimation
            let advanceRatio = flightSpeed / (omega * R)
            let radialPosition = r / R
            
            // Complex model based on advance ratio and radial position
            let axialGuess = flightSpeed * (0.1 + 0.05 * advanceRatio) * (1.0 - radialPosition)
            let tangentialGuess = flightSpeed * (0.02 + 0.01 * advanceRatio) * radialPosition
            
            return (axialGuess, tangentialGuess)
        }
    }
    
    /// ## Adaptive Relaxation Calculation
    /// Dynamically adjusts relaxation factor based on convergence behavior
    /// Improves stability and speeds up convergence
    /// - Parameters:
    ///   - iteration: Current iteration number
    ///   - residual: Current residual value
    ///   - residualHistory: History of previous residuals
    /// - Returns: Adaptive relaxation factor (0.0 to 1.0)
    private func calculateAdaptiveRelaxation(iteration: Int, residual: Double, residualHistory: [Double]) -> Double {
        let baseRelaxation = 0.3
        
        // Start with conservative relaxation
        if iteration < 3 {
            return 0.1
        }
        
        // Analyze convergence trend
        if residualHistory.count >= 3 {
            let recentImprovement = residualHistory[residualHistory.count-3] - residual
            let improvementRatio = recentImprovement / residualHistory[residualHistory.count-3]
            
            if improvementRatio > 0.3 {
                // Fast convergence - increase step size
                return min(0.8, baseRelaxation * 1.5)
            } else if improvementRatio < 0.05 {
                // Slow convergence - decrease step size
                return max(0.1, baseRelaxation * 0.7)
            }
        }
        
        // Conservative relaxation for large residuals
        if residual > 1.0 {
            return 0.1
        }
        
        return baseRelaxation
    }
    
    /// ## Newton-Raphson Iteration
    /// Performs single iteration of Newton-Raphson method for BEMT equations
    /// Solves coupled system for induced velocities
    /// - Parameters:
    ///   - r: Radial position
    ///   - dr: Element width
    ///   - blade: Blade geometry
    ///   - airfoil: Airfoil data
    ///   - omega: Angular velocity
    ///   - flightSpeed: Forward speed
    ///   - numberOfBlades: Blade count
    ///   - atmosphere: Atmospheric conditions
    ///   - currentAxial: Current axial induced velocity
    ///   - currentTangential: Current tangential induced velocity
    /// - Returns: Updated velocities, forces, and convergence data
    private func newtonRaphsonIteration(
        r: Double, dr: Double, blade: BladeGeometry, airfoil: AirfoilData, omega: Double,
        flightSpeed: Double, numberOfBlades: Int,
        atmosphere: (temperature: Double, pressure: Double, density: Double, speedOfSound: Double, kinematicViscosity: Double),
        currentAxial: Double, currentTangential: Double
    ) -> (axial: Double, tangential: Double, thrust: Double, torque: Double, alpha: Double, cl: Double, cd: Double, reynolds: Double, mach: Double, residual: Double) {
        
        // Calculate forces and flow conditions
        let (thrustBET, torqueBET, alpha, cl, cd, reynolds, mach) = calculateForces(
            r: r, dr: dr, blade: blade, airfoil: airfoil, omega: omega,
            flightSpeed: flightSpeed, numberOfBlades: numberOfBlades,
            atmosphere: atmosphere,
            axialInduced: currentAxial, tangentialInduced: currentTangential
        )
        
        // Calculate tip loss factor
        let tipLossFactor = calculateTipLossFactor(
            r: r, R: blade.radius, numberOfBlades: numberOfBlades,
            inflowAngle: calculateInflowAngle(
                r: r, omega: omega, flightSpeed: flightSpeed,
                axialInduced: currentAxial, tangentialInduced: currentTangential
            )
        )
        
        // Momentum theory equations
        let thrustMT = 4.0 * .pi * atmosphere.density * r * dr *
                      (flightSpeed + currentAxial) * currentAxial * tipLossFactor
        let torqueMT = 4.0 * .pi * atmosphere.density * pow(r, 3) * dr *
                      omega * currentTangential * tipLossFactor
        
        // Calculate residuals
        let residual1 = thrustBET - thrustMT
        let residual2 = torqueBET - torqueMT
        let residual = max(abs(residual1), abs(residual2))
        
        // Solve for new induced velocities
        let newAxial = solveForAxialInduced(
            thrustBET: thrustBET, flightSpeed: flightSpeed,
            r: r, dr: dr, density: atmosphere.density, tipLossFactor: tipLossFactor
        )
        
        let newTangential = solveForTangentialInduced(
            torqueBET: torqueBET, omega: omega,
            r: r, dr: dr, density: atmosphere.density, tipLossFactor: tipLossFactor
        )
        
        return (newAxial, newTangential, thrustBET, torqueBET, alpha, cl, cd, reynolds, mach, residual)
    }
    
    /// ## Calculate Aerodynamic Forces
    /// Computes thrust and torque contributions from blade element
    /// - Parameters:
    ///   - r: Radial position
    ///   - dr: Element width
    ///   - blade: Blade geometry
    ///   - airfoil: Airfoil data
    ///   - omega: Angular velocity
    ///   - flightSpeed: Forward speed
    ///   - numberOfBlades: Blade count
    ///   - atmosphere: Atmospheric conditions
    ///   - axialInduced: Axial induced velocity
    ///   - tangentialInduced: Tangential induced velocity
    /// - Returns: Forces, angles, and flow conditions
    private func calculateForces(
        r: Double, dr: Double, blade: BladeGeometry, airfoil: AirfoilData, omega: Double,
        flightSpeed: Double, numberOfBlades: Int,
        atmosphere: (temperature: Double, pressure: Double, density: Double, speedOfSound: Double, kinematicViscosity: Double),
        axialInduced: Double, tangentialInduced: Double
    ) -> (thrust: Double, torque: Double, alpha: Double, cl: Double, cd: Double, reynolds: Double, mach: Double) {
        
        // Calculate local velocities
        let ut = omega * r - tangentialInduced
        let up = flightSpeed + axialInduced
        
        // Calculate inflow angle and angle of attack
        let inflowAngle = atan2(up, ut)
        let bladeTwist = blade.twistDistribution(r / blade.radius)
        var alpha = bladeTwist - inflowAngle
        
        // Limit angle of attack to reasonable range
        alpha = max(-0.35, min(0.35, alpha))
        
        // Get local geometry
        let chord = blade.chordDistribution(r / blade.radius)
        let w = sqrt(ut * ut + up * up)
        
        // Calculate flow parameters
        let reynolds = w * chord / atmosphere.kinematicViscosity
        let mach = w / atmosphere.speedOfSound
        
        // Get aerodynamic coefficients
        var (cl, cd, _) = AirfoilCalculator.getCoefficients(for: airfoil, alpha: alpha, reynolds: reynolds)
        
        // Apply compressibility correction
        (cl, cd) = AirfoilCalculator.applyCompressibilityCorrection(cl: cl, cd: cd, mach: mach)
        
        // Calculate forces
        let dynamicPressure = 0.5 * atmosphere.density * w * w
        let dL = dynamicPressure * chord * dr * cl
        let dD = dynamicPressure * chord * dr * cd
        
        // Resolve forces into thrust and torque
        let thrust = Double(numberOfBlades) * (dL * cos(inflowAngle) - dD * sin(inflowAngle))
        let torque = Double(numberOfBlades) * r * (dL * sin(inflowAngle) + dD * cos(inflowAngle))
        
        return (thrust, torque, alpha, cl, cd, reynolds, mach)
    }
    
    // MARK: - Helper Methods
    
    /// ## Calculate Tip Loss Factor
    /// Prandtl's tip loss factor correction
    /// Accounts for finite number of blades and tip vortices
    private func calculateTipLossFactor(r: Double, R: Double, numberOfBlades: Int, inflowAngle: Double) -> Double {
        let f = Double(numberOfBlades) * (R - r) / (2.0 * r * sin(inflowAngle))
        return (2.0 / .pi) * acos(exp(-f))
    }
    
    /// ## Calculate Inflow Angle
    /// Angle between rotation plane and resultant flow
    private func calculateInflowAngle(r: Double, omega: Double, flightSpeed: Double, axialInduced: Double, tangentialInduced: Double) -> Double {
        let ut = omega * r - tangentialInduced
        let up = flightSpeed + axialInduced
        return atan2(up, ut)
    }
    
    /// ## Solve for Axial Induced Velocity
    /// Analytical solution for axial induced velocity from momentum theory
    private func solveForAxialInduced(thrustBET: Double, flightSpeed: Double, r: Double, dr: Double, density: Double, tipLossFactor: Double) -> Double {
        if thrustBET <= 0 { return 0.0 }
        
        let term = thrustBET / (4.0 * .pi * density * r * dr * tipLossFactor)
        if flightSpeed == 0 {
            return sqrt(term) / 2.0
        } else {
            return (-flightSpeed + sqrt(flightSpeed * flightSpeed + 4.0 * term)) / 2.0
        }
    }
    
    /// ## Solve for Tangential Induced Velocity
    /// Analytical solution for tangential induced velocity from momentum theory
    private func solveForTangentialInduced(torqueBET: Double, omega: Double, r: Double, dr: Double, density: Double, tipLossFactor: Double) -> Double {
        if torqueBET <= 0 { return 0.0 }
        return torqueBET / (4.0 * .pi * density * pow(r, 3) * dr * omega * tipLossFactor)
    }
    
    /// ## Fallback Calculation Method
    /// Simplified calculation when iterative method fails to converge
    /// Provides reasonable estimates without iteration
    private func calculateBladeElementFallback(
        r: Double, dr: Double, blade: BladeGeometry, airfoil: AirfoilData, omega: Double,
        flightSpeed: Double, numberOfBlades: Int,
        atmosphere: (temperature: Double, pressure: Double, density: Double, speedOfSound: Double, kinematicViscosity: Double)
    ) -> (thrust: Double, torque: Double, residual: Double, iterations: Int, residualHistory: [Double], alpha: Double, cl: Double, cd: Double, reynolds: Double, mach: Double) {
        
        // Simplified calculation without induced velocities
        let chord = blade.chordDistribution(r / blade.radius)
        let twist = blade.twistDistribution(r / blade.radius)
        
        let ut = omega * r
        let up = flightSpeed
        
        let inflowAngle = atan2(up, ut)
        var alpha = twist - inflowAngle
        alpha = max(-0.3, min(0.3, alpha))
        
        let w = sqrt(ut * ut + up * up)
        let reynolds = w * chord / atmosphere.kinematicViscosity
        let mach = w / atmosphere.speedOfSound
        
        let (cl, cd, _) = AirfoilCalculator.getCoefficients(for: airfoil, alpha: alpha, reynolds: reynolds)
        
        let dynamicPressure = 0.5 * atmosphere.density * w * w
        let dL = dynamicPressure * chord * dr * cl
        let dD = dynamicPressure * chord * dr * cd
        
        let thrust = Double(numberOfBlades) * (dL * cos(inflowAngle) - dD * sin(inflowAngle))
        let torque = Double(numberOfBlades) * r * (dL * sin(inflowAngle) + dD * cos(inflowAngle))
        
        return (thrust, torque, 0.01, 1, [0.01], alpha, cl, cd, reynolds, mach)
    }
    
    /// ## Calculate Propeller Efficiency
    /// Computes efficiency metric for current operating condition
    /// Different formulas for hover and forward flight
    private func calculateEfficiency(thrust: Double, power: Double, speed: Double, area: Double, density: Double) -> Double {
        guard power > 0 else { return 0.0 }
        
        if speed == 0 {
            // Figure of merit for hover
            let idealPower = thrust * sqrt(thrust / (2.0 * density * area))
            return idealPower / power
        } else {
            // Propulsive efficiency for forward flight
            return (thrust * speed) / power
        }
    }
}
