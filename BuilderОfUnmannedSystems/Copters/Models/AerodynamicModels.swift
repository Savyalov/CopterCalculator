//
//  AerodynamicModels.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation

/// # Airfoil Data Model
/// Contains comprehensive aerodynamic coefficients for different Reynolds numbers and angles of attack
/// Used for interpolation and calculation of lift, drag, and moment coefficients
public struct AirfoilData {
    
    // MARK: - Public Properties
    
    /// ## Reynolds Numbers Array
    /// Array of Reynolds numbers for which aerodynamic data is available
    /// Used to interpolate coefficients for intermediate Reynolds numbers
    public let reynoldsNumbers: [Double]
    
    /// ## Angle of Attack Arrays
    /// 2D array containing angles of attack (in radians) for each Reynolds number
    /// First dimension: Reynolds number index
    /// Second dimension: Angles of attack for that Reynolds number
    public let alpha: [[Double]]
    
    /// ## Lift Coefficient Arrays
    /// 2D array containing lift coefficients (Cl) corresponding to angles of attack
    /// Used to calculate lift force on blade elements
    public let cl: [[Double]]
    
    /// ## Drag Coefficient Arrays
    /// 2D array containing drag coefficients (Cd) corresponding to angles of attack
    /// Used to calculate drag force on blade elements
    public let cd: [[Double]]
    
    /// ## Moment Coefficient Arrays
    /// 2D array containing moment coefficients (Cm) corresponding to angles of attack
    /// Used for pitching moment calculations (optional)
    public let cm: [[Double]]
    
    // MARK: - Initialization
    
    /// ## Initializer
    /// Creates a new AirfoilData instance with specified aerodynamic coefficients
    /// - Parameters:
    ///   - reynoldsNumbers: Array of Reynolds numbers
    ///   - alpha: 2D array of angles of attack in radians
    ///   - cl: 2D array of lift coefficients
    ///   - cd: 2D array of drag coefficients
    ///   - cm: 2D array of moment coefficients
    public init(reynoldsNumbers: [Double], alpha: [[Double]], cl: [[Double]], cd: [[Double]], cm: [[Double]]) {
        self.reynoldsNumbers = reynoldsNumbers
        self.alpha = alpha
        self.cl = cl
        self.cd = cd
        self.cm = cm
    }
    
    // MARK: - Public Methods
    
    /// ## Get Aerodynamic Coefficients
    /// Interpolates aerodynamic coefficients for given angle of attack and Reynolds number
    /// Uses bilinear interpolation between available data points
    /// - Parameters:
    ///   - alpha: Angle of attack in radians
    ///   - reynolds: Reynolds number
    /// - Returns: Tuple containing (cl, cd, cm) coefficients
    public func getCoefficients(for alpha: Double, reynolds: Double) -> (cl: Double, cd: Double, cm: Double) {
        guard let lowerIndex = findReynoldsIndex(reynolds) else {
            return interpolateForSingleReynolds(alpha: alpha, reynolds: reynolds)
        }
        
        let lowerRe = reynoldsNumbers[lowerIndex]
        let upperRe = reynoldsNumbers[lowerIndex + 1]
        
        let (cl1, cd1, cm1) = interpolateForReynolds(at: lowerIndex, alpha: alpha)
        let (cl2, cd2, cm2) = interpolateForReynolds(at: lowerIndex + 1, alpha: alpha)
        
        let t = (reynolds - lowerRe) / (upperRe - lowerRe)
        
        return (
            cl1 + t * (cl2 - cl1),
            cd1 + t * (cd2 - cd1),
            cm1 + t * (cm2 - cm1)
        )
    }
    
    // MARK: - Private Methods
    
    /// ## Find Reynolds Index
    /// Locates the appropriate Reynolds number interval for interpolation
    /// - Parameter reynolds: Target Reynolds number
    /// - Returns: Lower index of Reynolds number interval, or nil if out of range
    private func findReynoldsIndex(_ reynolds: Double) -> Int? {
        for i in 0..<reynoldsNumbers.count-1 {
            if reynolds >= reynoldsNumbers[i] && reynolds <= reynoldsNumbers[i+1] {
                return i
            }
        }
        return nil
    }
    
    /// ## Interpolate for Specific Reynolds Number
    /// Performs linear interpolation of coefficients for a specific Reynolds number index
    /// - Parameters:
    ///   - index: Reynolds number index in the data arrays
    ///   - alpha: Target angle of attack
    /// - Returns: Interpolated coefficients (cl, cd, cm)
    private func interpolateForReynolds(at index: Int, alpha: Double) -> (cl: Double, cd: Double, cm: Double) {
        let alphas = self.alpha[index]
        let cls = self.cl[index]
        let cds = self.cd[index]
        let cms = self.cm[index]
        
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
    /// Fallback method when target Reynolds number is outside available ranges
    /// Uses closest available Reynolds number data
    /// - Parameters:
    ///   - alpha: Target angle of attack
    ///   - reynolds: Target Reynolds number
    /// - Returns: Coefficients from closest Reynolds number data
    private func interpolateForSingleReynolds(alpha: Double, reynolds: Double) -> (cl: Double, cd: Double, cm: Double) {
        let closestIndex = findClosestReynoldsIndex(reynolds)
        return interpolateForReynolds(at: closestIndex, alpha: alpha)
    }
    
    /// ## Find Closest Reynolds Index
    /// Locates the closest available Reynolds number when exact match is not available
    /// - Parameter reynolds: Target Reynolds number
    /// - Returns: Index of closest Reynolds number in the data array
    private func findClosestReynoldsIndex(_ reynolds: Double) -> Int {
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
