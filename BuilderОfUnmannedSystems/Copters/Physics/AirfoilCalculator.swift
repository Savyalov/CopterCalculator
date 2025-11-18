//
//  AirfoilCalculator.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation

/// # Airfoil Coefficient Calculator
/// Provides interpolation and calculation services for airfoil aerodynamic coefficients
/// Handles Reynolds number effects and compressibility corrections
public class AirfoilCalculator {
    
    // MARK: - Public Methods
    
    /// ## Get Aerodynamic Coefficients
    /// Retrieves interpolated aerodynamic coefficients for specified conditions
    /// Performs bilinear interpolation in Reynolds number and angle of attack
    /// - Parameters:
    ///   - airfoil: Airfoil data containing coefficient tables
    ///   - alpha: Angle of attack in radians
    ///   - reynolds: Reynolds number based on chord and flow conditions
    /// - Returns: Tuple of (cl, cd, cm) coefficients
    public static func getCoefficients(for airfoil: AirfoilData, alpha: Double, reynolds: Double) -> (cl: Double, cd: Double, cm: Double) {
        guard let lowerIndex = findReynoldsIndex(reynolds, in: airfoil.reynoldsNumbers) else {
            return interpolateForSingleReynolds(airfoil: airfoil, alpha: alpha, reynolds: reynolds)
        }
        
        let lowerRe = airfoil.reynoldsNumbers[lowerIndex]
        let upperRe = airfoil.reynoldsNumbers[lowerIndex + 1]
        
        let (cl1, cd1, cm1) = interpolateForReynolds(airfoil: airfoil, at: lowerIndex, alpha: alpha)
        let (cl2, cd2, cm2) = interpolateForReynolds(airfoil: airfoil, at: lowerIndex + 1, alpha: alpha)
        
        let t = (reynolds - lowerRe) / (upperRe - lowerRe)
        
        return (
            cl1 + t * (cl2 - cl1),
            cd1 + t * (cd2 - cd1),
            cm1 + t * (cm2 - cm1)
        )
    }
    
    /// ## Apply Compressibility Correction
    /// Applies Prandtl-Glauert correction for compressibility effects at high Mach numbers
    /// - Parameters:
    ///   - cl: Incompressible lift coefficient
    ///   - cd: Incompressible drag coefficient
    ///   - mach: Mach number of the flow
    /// - Returns: Compressibility-corrected (cl, cd) coefficients
    public static func applyCompressibilityCorrection(cl: Double, cd: Double, mach: Double) -> (cl: Double, cd: Double) {
        guard mach > 0.3 else { return (cl, cd) }
        
        let beta = sqrt(1 - mach * mach)
        return (cl / beta, cd / beta)
    }
    
    // MARK: - Private Methods
    
    /// ## Find Reynolds Index
    /// Locates the appropriate Reynolds number interval for interpolation
    /// - Parameters:
    ///   - reynolds: Target Reynolds number
    ///   - reynoldsNumbers: Array of available Reynolds numbers
    /// - Returns: Lower index of the interval, or nil if out of range
    private static func findReynoldsIndex(_ reynolds: Double, in reynoldsNumbers: [Double]) -> Int? {
        for i in 0..<reynoldsNumbers.count-1 {
            if reynolds >= reynoldsNumbers[i] && reynolds <= reynoldsNumbers[i+1] {
                return i
            }
        }
        return nil
    }
    
    /// ## Interpolate for Specific Reynolds Number
    /// Performs angle of attack interpolation for a fixed Reynolds number
    /// - Parameters:
    ///   - airfoil: Airfoil data
    ///   - index: Reynolds number index
    ///   - alpha: Target angle of attack
    /// - Returns: Interpolated coefficients (cl, cd, cm)
    private static func interpolateForReynolds(airfoil: AirfoilData, at index: Int, alpha: Double) -> (cl: Double, cd: Double, cm: Double) {
        let alphas = airfoil.alpha[index]
        let cls = airfoil.cl[index]
        let cds = airfoil.cd[index]
        let cms = airfoil.cm[index]
        
        for i in 0..<alphas.count-1 {
            if alpha >= alphas[i] && alpha <= alphas[i+1] {
                let t = (alpha - alphas[i]) / (alphas[i+1] - alphas[i])
                let cl = cls[i] + t * (cls[i+1] - cls[i])
                let cd = cds[i] + t * (cds[i+1] - cds[i])
                let cm = cms[i] + t * (cms[i+1] - cms[i])
                return (cl, cd, cm)
            }
        }
        return (0, 0.02, 0) // Default values if out of range
    }
    
    /// ## Interpolate for Single Reynolds Number
    /// Fallback method when Reynolds number is outside available range
    /// Uses closest available Reynolds number data
    /// - Parameters:
    ///   - airfoil: Airfoil data
    ///   - alpha: Target angle of attack
    ///   - reynolds: Target Reynolds number
    /// - Returns: Coefficients from closest Reynolds number
    private static func interpolateForSingleReynolds(airfoil: AirfoilData, alpha: Double, reynolds: Double) -> (cl: Double, cd: Double, cm: Double) {
        let closestIndex = findClosestReynoldsIndex(reynolds, in: airfoil.reynoldsNumbers)
        return interpolateForReynolds(airfoil: airfoil, at: closestIndex, alpha: alpha)
    }
    
    /// ## Find Closest Reynolds Index
    /// Locates the closest available Reynolds number when exact match not available
    /// - Parameters:
    ///   - reynolds: Target Reynolds number
    ///   - reynoldsNumbers: Array of available Reynolds numbers
    /// - Returns: Index of closest Reynolds number
    private static func findClosestReynoldsIndex(_ reynolds: Double, in reynoldsNumbers: [Double]) -> Int {
        var minDifference = Double.greatestFiniteMagnitude
        var closestIndex = 0
        
        for (index, re) in reynoldsNumbers.enumerated() {
            let difference = abs(re - reynolds)
            if difference < minDifference {
                minDifference = difference
                closestIndex = index
            }
        }
        return closestIndex
    }
}
