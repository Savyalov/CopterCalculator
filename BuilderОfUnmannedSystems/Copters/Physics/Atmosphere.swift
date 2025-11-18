//
//  Atmosphere.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation

/// # Atmospheric Layer Model
/// Represents a layer in the standard atmosphere with constant temperature gradient
/// Used for piecewise atmospheric property calculation
public struct AtmosphericLayer {
    
    // MARK: - Public Properties
    
    /// ## Base Altitude
    /// Altitude at the bottom of the layer in meters above sea level
    /// Reference point for temperature and pressure calculations
    public let baseAltitude: Double
    
    /// ## Base Temperature
    /// Temperature at the base of the layer in Kelvin
    /// Reference temperature for gradient calculations
    public let baseTemperature: Double
    
    /// ## Temperature Gradient
    /// Rate of temperature change with altitude in K/m
    /// Positive for inversion layers, negative for normal lapse rate
    public let temperatureGradient: Double
    
    /// ## Base Pressure
    /// Pressure at the base of the layer in Pascals
    /// Reference pressure for barometric calculations
    public let basePressure: Double
    
    // MARK: - Initialization
    
    /// ## Atmospheric Layer Initializer
    /// Creates a new atmospheric layer definition
    /// - Parameters:
    ///   - baseAltitude: Layer base altitude in meters
    ///   - baseTemperature: Base temperature in Kelvin
    ///   - temperatureGradient: Temperature gradient in K/m
    ///   - basePressure: Base pressure in Pascals
    public init(baseAltitude: Double, baseTemperature: Double, temperatureGradient: Double, basePressure: Double) {
        self.baseAltitude = baseAltitude
        self.baseTemperature = baseTemperature
        self.temperatureGradient = temperatureGradient
        self.basePressure = basePressure
    }
}

/// # Standard Atmosphere Calculator
/// Implements the International Standard Atmosphere (ISA) model
/// Calculates atmospheric properties at any altitude up to 86 km
public class StandardAtmosphere {
    
    // MARK: - Physical Constants
    
    /// ## Gas Constant for Air
    /// Specific gas constant for dry air in J/(kg·K)
    /// Used in ideal gas law calculations
    private let gasConstant = 287.05
    
    /// ## Gravitational Acceleration
    /// Standard gravitational acceleration in m/s²
    /// Used for hydrostatic equation calculations
    private let gravity = 9.80665
    
    /// ## Specific Heat Ratio
    /// Ratio of specific heats for air (gamma = cp/cv)
    /// Used for speed of sound calculations
    private let gamma = 1.4
    
    /// ## Sutherland's Constant
    /// Sutherland's constant for viscosity calculation in Kelvin
    /// Used in Sutherland's law for dynamic viscosity
    private let sutherlandConstant = 110.4
    
    /// ## Reference Dynamic Viscosity
    /// Reference coefficient for dynamic viscosity calculation in kg/(m·s·K^0.5)
    /// Used in Sutherland's viscosity formula
    private let referenceViscosity = 1.458e-6
    
    // MARK: - Atmospheric Layers
    
    /// ## ISA Atmospheric Layers
    /// Array of atmospheric layers according to ICAO Standard Atmosphere
    /// Covers altitudes from sea level to 86 km with appropriate gradients
    private let layers: [AtmosphericLayer] = [
        // 0: Troposphere (0-11 km)
        AtmosphericLayer(baseAltitude: 0, baseTemperature: 288.15, temperatureGradient: -0.0065, basePressure: 101325),
        // 1: Tropopause (11-20 km)
        AtmosphericLayer(baseAltitude: 11000, baseTemperature: 216.65, temperatureGradient: 0.0, basePressure: 22632),
        // 2: Lower Stratosphere (20-32 km)
        AtmosphericLayer(baseAltitude: 20000, baseTemperature: 216.65, temperatureGradient: 0.001, basePressure: 5474.9),
        // 3: Upper Stratosphere (32-47 km)
        AtmosphericLayer(baseAltitude: 32000, baseTemperature: 228.65, temperatureGradient: 0.0028, basePressure: 868.02),
        // 4: Stratopause (47-51 km)
        AtmosphericLayer(baseAltitude: 47000, baseTemperature: 270.65, temperatureGradient: 0.0, basePressure: 110.91),
        // 5: Lower Mesosphere (51-71 km)
        AtmosphericLayer(baseAltitude: 51000, baseTemperature: 270.65, temperatureGradient: -0.0028, basePressure: 66.94),
        // 6: Upper Mesosphere (71-86 km)
        AtmosphericLayer(baseAltitude: 71000, baseTemperature: 214.65, temperatureGradient: -0.002, basePressure: 3.96)
    ]
    
    // MARK: - Public Methods
    
    /// ## Calculate Atmospheric Conditions
    /// Computes complete atmospheric properties at specified altitude
    /// Uses ISA model with piecewise continuous layers
    /// - Parameter altitude: Altitude above sea level in meters
    /// - Returns: Tuple containing temperature, pressure, density, speed of sound, and kinematic viscosity
    public func calculateConditions(altitude: Double) -> (temperature: Double, pressure: Double, density: Double, speedOfSound: Double, kinematicViscosity: Double) {
        var currentAltitude = max(0.0, altitude)
        let maxAltitude = 86000.0 // Maximum model altitude
        
        // Clamp altitude to model limits
        if currentAltitude > maxAltitude {
            currentAltitude = maxAltitude
        }
        
        // Find appropriate atmospheric layer
        var layerIndex = 0
        for i in (0..<layers.count).reversed() {
            if currentAltitude >= layers[i].baseAltitude {
                layerIndex = i
                break
            }
        }
        
        let layer = layers[layerIndex]
        let deltaAltitude = currentAltitude - layer.baseAltitude
        
        // Calculate temperature using layer gradient
        let temperature = layer.baseTemperature + layer.temperatureGradient * deltaAltitude
        
        // Calculate pressure based on layer type
        let pressure: Double
        if abs(layer.temperatureGradient) < 1e-10 {
            // Isothermal layer - exponential pressure decay
            pressure = layer.basePressure * exp(-gravity * deltaAltitude / (gasConstant * layer.baseTemperature))
        } else {
            // Polytropic layer - power law pressure relationship
            let exponent = -gravity / (layer.temperatureGradient * gasConstant)
            pressure = layer.basePressure * pow(temperature / layer.baseTemperature, exponent)
        }
        
        // Calculate density using ideal gas law
        let density = pressure / (gasConstant * temperature)
        
        // Calculate speed of sound
        let speedOfSound = sqrt(gamma * gasConstant * temperature)
        
        // Calculate dynamic viscosity using Sutherland's formula
        let dynamicViscosity = referenceViscosity * pow(temperature, 1.5) / (temperature + sutherlandConstant)
        
        // Calculate kinematic viscosity
        let kinematicViscosity = dynamicViscosity / density
        
        return (temperature, pressure, density, speedOfSound, kinematicViscosity)
    }
    
    /// ## Generate Atmospheric Table
    /// Creates a table of atmospheric properties at specified altitudes
    /// Useful for analysis and visualization of altitude effects
    /// - Parameter altitudes: Array of altitudes in meters
    /// - Returns: Array of tuples containing altitude, temperature, pressure, and density
    public func getAtmosphericTable(altitudes: [Double]) -> [(altitude: Double, temperature: Double, pressure: Double, density: Double)] {
        return altitudes.map { altitude in
            let conditions = calculateConditions(altitude: altitude)
            return (altitude, conditions.temperature, conditions.pressure, conditions.density)
        }
    }
}
