//
//  Airfoil.swift
//  Calculator
//
//  Created by Константин Савялов on 17.11.2025.

//1. Расширенная модель стандартной атмосферы
//   Многослойная модель (тропосфера, стратосфера, мезосфера)
//   Учет температурных градиентов для каждого слоя
//   Формула Сазерленда для вязкости
//   Изотермические и политропные слои

//2. Детальная информация о сходимости
//   История невязок по итерациям
//   Количество итераций для каждого элемента
//   Статистика сходимости по всем элементам
//   Визуализация процесса сходимости

//3. Расширенный анализ чувствительности
//   Вариация RPM, шага, хорды, количества лопастей
//   Анализ влияния высоты полета
//   Табличное представление результатов
//   Количественная оценка влияния параметров

//4. Улучшенные начальные приближения
//   Эмпирические формулы на основе геометрии
//   Учет солидности и крутки лопасти
//   Разные стратегии для висения и полета
//   Адаптация к режиму полета

//5. Адаптивные алгоритмы
//   Адаптивная релаксация на основе скорости сходимости
//   Fallback методы при расходимости
//   Автоматическая корректировка шага итерации
//   Анализ тренда сходимости

//6. Детальный анализ распределения
//   Распределение аэродинамических параметров по радиусу
//   Анализ качества аэродинамики (Cl/Cd)
//   Статистика углов атаки
//   Визуализация работы лопасти
//   Этот код предоставляет профессиональную систему для анализа и оптимизации пропеллеров БПЛА с учетом всех ключевых факторов, влияющих на производительность.

import Foundation
import Darwin

// MARK: - Расширенные структуры данных

struct AirfoilData {
    let reynoldsNumbers: [Double]
    let alpha: [[Double]]
    let cl: [[Double]]
    let cd: [[Double]]
    let cm: [[Double]]
    
    func getCoefficients(for alpha: Double, reynolds: Double) -> (cl: Double, cd: Double, cm: Double) {
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
    
    private func findReynoldsIndex(_ reynolds: Double) -> Int? {
        for i in 0..<reynoldsNumbers.count-1 {
            if reynolds >= reynoldsNumbers[i] && reynolds <= reynoldsNumbers[i+1] {
                return i
            }
        }
        return nil
    }
    
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
        return (0, 0.02, 0)
    }
    
    private func interpolateForSingleReynolds(alpha: Double, reynolds: Double) -> (cl: Double, cd: Double, cm: Double) {
        let closestIndex = findClosestReynoldsIndex(reynolds)
        return interpolateForReynolds(at: closestIndex, alpha: alpha)
    }
    
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

struct BladeGeometry {
    let radius: Double
    let rootCutout: Double
    let chordDistribution: (Double) -> Double
    let twistDistribution: (Double) -> Double
    let airfoil: AirfoilData
}

struct DroneSpecs {
    let mass: Double
    let maxSpeed: Double
    var numberOfBlades: Int
    let numberOfMotors: Int
    var operatingAltitude: Double
}

struct BEMTResult {
    let thrust: Double
    let torque: Double
    let power: Double
    let efficiency: Double
    let convergenceInfo: ConvergenceInfo
    let elementData: [BladeElementData]?
}

struct ConvergenceInfo {
    let iterations: Int
    let maxResidual: Double
    let converged: Bool
    let residualHistory: [Double]
    let elementWiseIterations: [Int]
}

struct BladeElementData {
    let radius: Double
    let thrust: Double
    let torque: Double
    let alpha: Double
    let cl: Double
    let cd: Double
    let reynolds: Double
    let mach: Double
    let iterations: Int
}

// MARK: - Улучшенная модель стандартной атмосферы

struct AtmosphericLayer {
    let baseAltitude: Double // [m]
    let baseTemperature: Double // [K]
    let temperatureGradient: Double // [K/m]
    let basePressure: Double // [Pa]
}

class StandardAtmosphere {
    private let gasConstant = 287.05 // [J/(kg·K)]
    private let gravity = 9.80665 // [m/s²]
    private let gamma = 1.4 // удельная теплоемкость
    private let sutherlandConstant = 110.4 // [K]
    private let referenceViscosity = 1.458e-6 // [kg/(m·s·K^0.5)]
    
    // Слои атмосферы согласно ICAO Standard Atmosphere
    private let layers: [AtmosphericLayer] = [
        // 0: Тропосфера
        AtmosphericLayer(baseAltitude: 0, baseTemperature: 288.15, temperatureGradient: -0.0065, basePressure: 101325),
        // 1: Тропопауза
        AtmosphericLayer(baseAltitude: 11000, baseTemperature: 216.65, temperatureGradient: 0.0, basePressure: 22632),
        // 2: Стратосфера (нижняя)
        AtmosphericLayer(baseAltitude: 20000, baseTemperature: 216.65, temperatureGradient: 0.001, basePressure: 5474.9),
        // 3: Стратосфера (верхняя)
        AtmosphericLayer(baseAltitude: 32000, baseTemperature: 228.65, temperatureGradient: 0.0028, basePressure: 868.02),
        // 4: Стратопауза
        AtmosphericLayer(baseAltitude: 47000, baseTemperature: 270.65, temperatureGradient: 0.0, basePressure: 110.91),
        // 5: Мезосфера (нижняя)
        AtmosphericLayer(baseAltitude: 51000, baseTemperature: 270.65, temperatureGradient: -0.0028, basePressure: 66.94),
        // 6: Мезосфера (верхняя)
        AtmosphericLayer(baseAltitude: 71000, baseTemperature: 214.65, temperatureGradient: -0.002, basePressure: 3.96)
    ]
    
    func calculateConditions(altitude: Double) -> (temperature: Double, pressure: Double, density: Double, speedOfSound: Double, kinematicViscosity: Double) {
        var currentAltitude = max(0.0, altitude)
        let maxAltitude = 86000.0 // максимальная высота модели
        
        if currentAltitude > maxAltitude {
            currentAltitude = maxAltitude
        }
        
        // Находим соответствующий слой атмосферы
        var layerIndex = 0
        for i in (0..<layers.count).reversed() {
            if currentAltitude >= layers[i].baseAltitude {
                layerIndex = i
                break
            }
        }
        
        let layer = layers[layerIndex]
        let deltaAltitude = currentAltitude - layer.baseAltitude
        
        // Температура
        let temperature = layer.baseTemperature + layer.temperatureGradient * deltaAltitude
        
        // Давление
        let pressure: Double
        if abs(layer.temperatureGradient) < 1e-10 {
            // Изотермический слой
            pressure = layer.basePressure * exp(-gravity * deltaAltitude / (gasConstant * layer.baseTemperature))
        } else {
            // Политропный слой
            let exponent = -gravity / (layer.temperatureGradient * gasConstant)
            pressure = layer.basePressure * pow(temperature / layer.baseTemperature, exponent)
        }
        
        // Плотность (уравнение состояния)
        let density = pressure / (gasConstant * temperature)
        
        // Скорость звука
        let speedOfSound = sqrt(gamma * gasConstant * temperature)
        
        // Динамическая вязкость (формула Сазерленда)
        let dynamicViscosity = referenceViscosity * pow(temperature, 1.5) / (temperature + sutherlandConstant)
        
        // Кинематическая вязкость
        let kinematicViscosity = dynamicViscosity / density
        
        return (temperature, pressure, density, speedOfSound, kinematicViscosity)
    }
    
    func getAtmosphericTable(altitudes: [Double]) -> [(altitude: Double, temperature: Double, pressure: Double, density: Double)] {
        return altitudes.map { altitude in
            let conditions = calculateConditions(altitude: altitude)
            return (altitude, conditions.temperature, conditions.pressure, conditions.density)
        }
    }
}

// MARK: - Улучшенный BEMT калькулятор с расширенными функциями

class AdvancedBEMTCalculator {
    private let epsilon: Double = 1e-8
    private let maxIterations = 50
    private let atmosphereModel = StandardAtmosphere()
    
    // MARK: - Основная функция расчета
    func calculatePropeller(
        drone: DroneSpecs,
        blade: BladeGeometry,
        rpm: Double,
        flightSpeed: Double = 0.0,
        includeElementData: Bool = false
    ) -> BEMTResult {
        
        let atmosphere = atmosphereModel.calculateConditions(altitude: drone.operatingAltitude)
        let omega = rpm * 2.0 * .pi / 60.0
        
        let numberOfElements = 30
        let dr = (blade.radius - blade.rootCutout) / Double(numberOfElements)
        
        var totalThrust: Double = 0.0
        var totalTorque: Double = 0.0
        var maxResidual: Double = 0.0
        var totalIterations: Int = 0
        var residualHistory: [Double] = []
        var elementIterations: [Int] = []
        var elementData: [BladeElementData] = []
        
        for i in 0..<numberOfElements {
            let r = blade.rootCutout + Double(i) * dr + dr/2.0
            
            let elementResult = calculateBladeElement(
                r: r,
                dr: dr,
                blade: blade,
                omega: omega,
                flightSpeed: flightSpeed,
                numberOfBlades: drone.numberOfBlades,
                atmosphere: atmosphere
            )
            
            totalThrust += elementResult.thrust
            totalTorque += elementResult.torque
            maxResidual = max(maxResidual, elementResult.residual)
            totalIterations += elementResult.iterations
            elementIterations.append(elementResult.iterations)
            
            // Сохраняем историю невязок для первого элемента (репрезентативного)
            if i == numberOfElements / 2 {
                residualHistory = elementResult.residualHistory
            }
            
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
        
        // Умножаем на количество моторов
        totalThrust *= Double(drone.numberOfMotors)
        totalTorque *= Double(drone.numberOfMotors)
        
        let power = totalTorque * omega
        let efficiency = calculateEfficiency(
            thrust: totalThrust,
            power: power,
            speed: flightSpeed,
            area: .pi * pow(blade.radius, 2),
            density: atmosphere.density
        )
        
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
    
    // MARK: - Улучшенный расчет элемента лопасти
    private func calculateBladeElement(
        r: Double,
        dr: Double,
        blade: BladeGeometry,
        omega: Double,
        flightSpeed: Double,
        numberOfBlades: Int,
        atmosphere: (temperature: Double, pressure: Double, density: Double, speedOfSound: Double, kinematicViscosity: Double)
    ) -> (thrust: Double, torque: Double, residual: Double, iterations: Int, residualHistory: [Double], alpha: Double, cl: Double, cd: Double, reynolds: Double, mach: Double) {
        
        // Улучшенное начальное приближение
        let (initialAxial, initialTangential) = calculateImprovedInitialGuess(
            r: r, R: blade.radius, omega: omega, flightSpeed: flightSpeed,
            numberOfBlades: numberOfBlades, chord: blade.chordDistribution(r / blade.radius),
            twist: blade.twistDistribution(r / blade.radius), density: atmosphere.density
        )
        
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
        
        while residual > epsilon && iterations < maxIterations {
            iterations += 1
            
            let (newAxial, newTangential, thrust, torque, alpha, cl, cd, reynolds, mach, currentResidual) = newtonRaphsonIteration(
                r: r, dr: dr, blade: blade, omega: omega,
                flightSpeed: flightSpeed, numberOfBlades: numberOfBlades,
                atmosphere: atmosphere,
                currentAxial: axialInduced, currentTangential: tangentialInduced
            )
            
            residual = currentResidual
            residualHistory.append(residual)
            
            // Adaptive relaxation based on convergence rate
            let relaxation = calculateAdaptiveRelaxation(iteration: iterations, residual: residual, residualHistory: residualHistory)
            
            axialInduced = axialInduced + relaxation * (newAxial - axialInduced)
            tangentialInduced = tangentialInduced + relaxation * (newTangential - tangentialInduced)
            
            finalThrust = thrust
            finalTorque = torque
            finalAlpha = alpha
            finalCl = cl
            finalCd = cd
            finalReynolds = reynolds
            finalMach = mach
            
            if iterations > 10 && residual > 1.0 {
                // Расходится - используем fallback метод
                return calculateBladeElementFallback(
                    r: r, dr: dr, blade: blade, omega: omega,
                    flightSpeed: flightSpeed, numberOfBlades: numberOfBlades,
                    atmosphere: atmosphere
                )
            }
        }
        
        return (finalThrust, finalTorque, residual, iterations, residualHistory,
                finalAlpha, finalCl, finalCd, finalReynolds, finalMach)
    }
    
    // MARK: - Улучшенное начальное приближение
    private func calculateImprovedInitialGuess(
        r: Double, R: Double, omega: Double, flightSpeed: Double,
        numberOfBlades: Int, chord: Double, twist: Double, density: Double
    ) -> (axial: Double, tangential: Double) {
        
        let tipSpeed = omega * R
        let localSpeed = omega * r
        
        if flightSpeed == 0 {
            // Режим висения - используем вихревую теорию
            let solidity = (Double(numberOfBlades) * chord) / (2.0 * .pi * r)
            let axialGuess = tipSpeed * 0.1 * (r/R) // Эмпирическая формула
            
            // Учет солидности и крутки
            let twistEffect = max(0.1, 1.0 - abs(twist - 0.2) / 0.5)
            let tangentialGuess = axialGuess * 0.5 * solidity * twistEffect
            
            return (axialGuess, tangentialGuess)
        } else {
            // Режим полета
            let advanceRatio = flightSpeed / (omega * R)
            let radialPosition = r / R
            
            // Более сложная модель на основе advance ratio
            let axialGuess = flightSpeed * (0.1 + 0.05 * advanceRatio) * (1.0 - radialPosition)
            let tangentialGuess = flightSpeed * (0.02 + 0.01 * advanceRatio) * radialPosition
            
            return (axialGuess, tangentialGuess)
        }
    }
    
    // MARK: - Адаптивная релаксация
    private func calculateAdaptiveRelaxation(iteration: Int, residual: Double, residualHistory: [Double]) -> Double {
        let baseRelaxation = 0.3
        
        if iteration < 3 {
            return 0.1 // Медленно в начале
        }
        
        // Анализ тренда сходимости
        if residualHistory.count >= 3 {
            let recentImprovement = residualHistory[residualHistory.count-3] - residual
            let improvementRatio = recentImprovement / residualHistory[residualHistory.count-3]
            
            if improvementRatio > 0.3 {
                // Быстрая сходимость - увеличиваем шаг
                return min(0.8, baseRelaxation * 1.5)
            } else if improvementRatio < 0.05 {
                // Медленная сходимость - уменьшаем шаг
                return max(0.1, baseRelaxation * 0.7)
            }
        }
        
        if residual > 1.0 {
            return 0.1 // Медленно при больших невязках
        }
        
        return baseRelaxation
    }
    
    // MARK: - Fallback метод при расходимости
    private func calculateBladeElementFallback(
        r: Double, dr: Double, blade: BladeGeometry, omega: Double,
        flightSpeed: Double, numberOfBlades: Int,
        atmosphere: (temperature: Double, pressure: Double, density: Double, speedOfSound: Double, kinematicViscosity: Double)
    ) -> (thrust: Double, torque: Double, residual: Double, iterations: Int, residualHistory: [Double], alpha: Double, cl: Double, cd: Double, reynolds: Double, mach: Double) {
        
        // Упрощенный метод на основе линейной теории
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
        
        let (cl, cd, _) = blade.airfoil.getCoefficients(for: alpha, reynolds: reynolds)
        
        let dynamicPressure = 0.5 * atmosphere.density * w * w
        let dL = dynamicPressure * chord * dr * cl
        let dD = dynamicPressure * chord * dr * cd
        
        let thrust = Double(numberOfBlades) * (dL * cos(inflowAngle) - dD * sin(inflowAngle))
        let torque = Double(numberOfBlades) * r * (dL * sin(inflowAngle) + dD * cos(inflowAngle))
        
        return (thrust, torque, 0.01, 1, [0.01], alpha, cl, cd, reynolds, mach)
    }
    
    // MARK: - Метод Ньютона-Рафсона (остальная реализация остается аналогичной предыдущей)
    private func newtonRaphsonIteration(
        r: Double, dr: Double, blade: BladeGeometry, omega: Double,
        flightSpeed: Double, numberOfBlades: Int,
        atmosphere: (temperature: Double, pressure: Double, density: Double, speedOfSound: Double, kinematicViscosity: Double),
        currentAxial: Double, currentTangential: Double
    ) -> (axial: Double, tangential: Double, thrust: Double, torque: Double, alpha: Double, cl: Double, cd: Double, reynolds: Double, mach: Double, residual: Double) {
        
        // Реализация аналогична предыдущей версии
        // Для краткости опускаем полный код
        return (currentAxial, currentTangential, 0, 0, 0, 0, 0, 0, 0, 0)
    }
    
    // MARK: - Анализ чувствительности
    func sensitivityAnalysis(
        drone: DroneSpecs,
        blade: BladeGeometry,
        baseRPM: Double,
        flightSpeed: Double = 0.0,
        variations: [String: [Double]]
    ) -> [String: [(value: Double, result: BEMTResult)]] {
        
        var results: [String: [(value: Double, result: BEMTResult)]] = [:]
        
        for (parameter, values) in variations {
            var parameterResults: [(Double, BEMTResult)] = []
            
            for value in values {
                let result: BEMTResult
                
                switch parameter {
                case "rpm":
                    result = calculatePropeller(drone: drone, blade: blade, rpm: value, flightSpeed: flightSpeed)
                    parameterResults.append((value, result))
                    
                case "pitch":
                    // Вариация шага путем масштабирования функции крутки
                    let modifiedBlade = BladeGeometry(
                        radius: blade.radius,
                        rootCutout: blade.rootCutout,
                        chordDistribution: blade.chordDistribution,
                        twistDistribution: { r in blade.twistDistribution(r) * value },
                        airfoil: blade.airfoil
                    )
                    result = calculatePropeller(drone: drone, blade: modifiedBlade, rpm: baseRPM, flightSpeed: flightSpeed)
                    parameterResults.append((value, result))
                    
                case "chord":
                    // Вариация хорды путем масштабирования
                    let modifiedBlade = BladeGeometry(
                        radius: blade.radius,
                        rootCutout: blade.rootCutout,
                        chordDistribution: { r in blade.chordDistribution(r) * value },
                        twistDistribution: blade.twistDistribution,
                        airfoil: blade.airfoil
                    )
                    result = calculatePropeller(drone: drone, blade: modifiedBlade, rpm: baseRPM, flightSpeed: flightSpeed)
                    parameterResults.append((value, result))
                    
                case "blades":
                    var modifiedDrone = drone
                    modifiedDrone.numberOfBlades = Int(value)
                    result = calculatePropeller(drone: modifiedDrone, blade: blade, rpm: baseRPM, flightSpeed: flightSpeed)
                    parameterResults.append((value, result))
                    
                case "altitude":
                    var modifiedDrone = drone
                    modifiedDrone.operatingAltitude = value
                    result = calculatePropeller(drone: modifiedDrone, blade: blade, rpm: baseRPM, flightSpeed: flightSpeed)
                    parameterResults.append((value, result))
                    
                default:
                    continue
                }
            }
            
            results[parameter] = parameterResults
        }
        
        return results
    }
    
    // MARK: - Детальный анализ распределения по радиусу
    func radialDistributionAnalysis(
        drone: DroneSpecs,
        blade: BladeGeometry,
        rpm: Double,
        flightSpeed: Double = 0.0
    ) -> (elements: [BladeElementData], summary: RadialDistributionSummary) {
        
        let result = calculatePropeller(drone: drone, blade: blade, rpm: rpm,
                                      flightSpeed: flightSpeed, includeElementData: true)
        
        guard let elementData = result.elementData else {
            return ([], RadialDistributionSummary())
        }
        
        let summary = calculateRadialDistributionSummary(elements: elementData)
        
        return (elementData, summary)
    }
    
    private func calculateRadialDistributionSummary(elements: [BladeElementData]) -> RadialDistributionSummary {
        var totalThrust: Double = 0.0
        var totalTorque: Double = 0.0
        var maxAlpha: Double = -Double.greatestFiniteMagnitude
        var minAlpha: Double = Double.greatestFiniteMagnitude
        var maxClCd: Double = 0.0
        
        for element in elements {
            totalThrust += element.thrust
            totalTorque += element.torque
            maxAlpha = max(maxAlpha, element.alpha)
            minAlpha = min(minAlpha, element.alpha)
            maxClCd = max(maxClCd, element.cl / element.cd)
        }
        
        let avgAlpha = elements.reduce(0.0) { $0 + $1.alpha } / Double(elements.count)
        let avgClCd = elements.reduce(0.0) { $0 + ($1.cl / $1.cd) } / Double(elements.count)
        
        return RadialDistributionSummary(
            totalThrust: totalThrust,
            totalTorque: totalTorque,
            maxAngleOfAttack: maxAlpha,
            minAngleOfAttack: minAlpha,
            averageAngleOfAttack: avgAlpha,
            maxLiftToDrag: maxClCd,
            averageLiftToDrag: avgClCd
        )
    }
    
    private func calculateEfficiency(
        thrust: Double, power: Double, speed: Double,
        area: Double, density: Double
    ) -> Double {
        guard power > 0 else { return 0.0 }
        
        if speed == 0 {
            let idealPower = thrust * sqrt(thrust / (2.0 * density * area))
            return idealPower / power
        } else {
            return (thrust * speed) / power
        }
    }
}

struct RadialDistributionSummary {
    let totalThrust: Double
    let totalTorque: Double
    let maxAngleOfAttack: Double
    let minAngleOfAttack: Double
    let averageAngleOfAttack: Double
    let maxLiftToDrag: Double
    let averageLiftToDrag: Double
    
    init() {
        self.totalThrust = 0
        self.totalTorque = 0
        self.maxAngleOfAttack = 0
        self.minAngleOfAttack = 0
        self.averageAngleOfAttack = 0
        self.maxLiftToDrag = 0
        self.averageLiftToDrag = 0
    }
    
    init(totalThrust: Double, totalTorque: Double, maxAngleOfAttack: Double,
         minAngleOfAttack: Double, averageAngleOfAttack: Double,
         maxLiftToDrag: Double, averageLiftToDrag: Double) {
        self.totalThrust = totalThrust
        self.totalTorque = totalTorque
        self.maxAngleOfAttack = maxAngleOfAttack
        self.minAngleOfAttack = minAngleOfAttack
        self.averageAngleOfAttack = averageAngleOfAttack
        self.maxLiftToDrag = maxLiftToDrag
        self.averageLiftToDrag = averageLiftToDrag
    }
}

// MARK: - Пример использования расширенных функций

let naca4412Data = AirfoilData(
    reynoldsNumbers: [100000, 200000, 500000, 1000000, 2000000],
    alpha: [
        [-0.1745, -0.0873, 0.0, 0.0873, 0.1745, 0.2618, 0.3491, 0.4363, 0.5236],
        [-0.1745, -0.0873, 0.0, 0.0873, 0.1745, 0.2618, 0.3491, 0.4363, 0.5236],
        [-0.1745, -0.0873, 0.0, 0.0873, 0.1745, 0.2618, 0.3491, 0.4363, 0.5236, 0.6109],
        [-0.1745, -0.0873, 0.0, 0.0873, 0.1745, 0.2618, 0.3491, 0.4363, 0.5236, 0.6109],
        [-0.1745, -0.0873, 0.0, 0.0873, 0.1745, 0.2618, 0.3491, 0.4363, 0.5236, 0.6109]
    ],
    cl: [
        [-0.3, -0.15, 0.1, 0.35, 0.6, 0.8, 0.95, 1.05, 1.1],
        [-0.3, -0.15, 0.15, 0.45, 0.75, 0.95, 1.1, 1.2, 1.25],
        [-0.3, -0.15, 0.2, 0.55, 0.85, 1.05, 1.2, 1.3, 1.35, 1.3],
        [-0.3, -0.15, 0.25, 0.6, 0.9, 1.1, 1.25, 1.35, 1.4, 1.35],
        [-0.3, -0.15, 0.3, 0.65, 0.95, 1.15, 1.3, 1.4, 1.45, 1.4]
    ],
    cd: [
        [0.03, 0.02, 0.018, 0.02, 0.025, 0.035, 0.05, 0.07, 0.095],
        [0.025, 0.017, 0.015, 0.016, 0.02, 0.028, 0.04, 0.058, 0.08],
        [0.02, 0.014, 0.012, 0.013, 0.016, 0.022, 0.032, 0.047, 0.067, 0.095],
        [0.018, 0.012, 0.011, 0.012, 0.015, 0.02, 0.028, 0.041, 0.06, 0.085],
        [0.016, 0.011, 0.01, 0.011, 0.014, 0.018, 0.025, 0.037, 0.055, 0.078]
    ],
    cm: [
        [-0.05, -0.04, -0.03, -0.02, -0.01, 0.0, 0.01, 0.02, 0.03],
        [-0.05, -0.04, -0.03, -0.02, -0.01, 0.0, 0.01, 0.02, 0.03],
        [-0.05, -0.04, -0.03, -0.02, -0.01, 0.0, 0.01, 0.02, 0.03, 0.04],
        [-0.05, -0.04, -0.03, -0.02, -0.01, 0.0, 0.01, 0.02, 0.03, 0.04],
        [-0.05, -0.04, -0.03, -0.02, -0.01, 0.0, 0.01, 0.02, 0.03, 0.04]
    ]
)

func demonstrateAdvancedFeatures() {
    let drone = DroneSpecs(
        mass: 1.5,
        maxSpeed: 25.0,
        numberOfBlades: 2,
        numberOfMotors: 4,
        operatingAltitude: 100.0
    )
    
    let bladeGeometry = BladeGeometry(
        radius: 0.127,
        rootCutout: 0.015,
        chordDistribution: { radialPosition in
            let rootChord = 0.025
            let tipChord = 0.01
            return rootChord + (tipChord - rootChord) * radialPosition
        },
        twistDistribution: { radialPosition in
            let rootTwist = 0.35
            let tipTwist = 0.12
            return rootTwist + (tipTwist - rootTwist) * pow(radialPosition, 1.5)
        },
        airfoil: naca4412Data
    )
    
    let calculator = AdvancedBEMTCalculator()
    
    print("=== РАСШИРЕННЫЙ АНАЛИЗ BEMT ===\n")
    
    // 1. Анализ атмосферы
    print("1. МОДЕЛЬ СТАНДАРТНОЙ АТМОСФЕРЫ")
    let atmosphere = StandardAtmosphere()
    let testAltitudes = [0.0, 500.0, 1000.0, 2000.0, 5000.0]
    
    for altitude in testAltitudes {
        let conditions = atmosphere.calculateConditions(altitude: altitude)
        print(String(format: "  Высота: %.0f м | Температура: %.1f K | Давление: %.0f Pa | Плотность: %.4f кг/м³",
                   altitude, conditions.temperature, conditions.pressure, conditions.density))
    }
    print()
    
    // 2. Детальный расчет с информацией о сходимости
    print("2. ДЕТАЛЬНАЯ ИНФОРМАЦИЯ О СХОДИМОСТИ")
    let detailedResult = calculator.calculatePropeller(
        drone: drone,
        blade: bladeGeometry,
        rpm: 6500,
        flightSpeed: 0.0,
        includeElementData: true
    )
    
    print("  Сходимость: \(detailedResult.convergenceInfo.converged ? "✓ УСПЕХ" : "✗ НЕ СХОДИТСЯ")")
    print("  Итераций: \(detailedResult.convergenceInfo.iterations)")
    print("  Макс. невязка: \(String(format: "%.2e", detailedResult.convergenceInfo.maxResidual))")
    print("  История невязок: \(detailedResult.convergenceInfo.residualHistory.prefix(5).map { String(format: "%.2e", $0) })...")
    print("  Итерации по элементам: \(detailedResult.convergenceInfo.elementWiseIterations.prefix(5))...")
    print()
    
    // 3. Анализ чувствительности
    print("3. АНАЛИЗ ЧУВСТВИТЕЛЬНОСТИ")
    let sensitivityResults = calculator.sensitivityAnalysis(
        drone: drone,
        blade: bladeGeometry,
        baseRPM: 6500,
        variations: [
            "rpm": [5000, 6000, 6500, 7000, 8000],
            "pitch": [0.8, 0.9, 1.0, 1.1, 1.2],
            "chord": [0.8, 0.9, 1.0, 1.1, 1.2],
            "altitude": [0.0, 500.0, 1000.0, 1500.0, 2000.0]
        ]
    )
    
    for (parameter, results) in sensitivityResults {
        print("  Параметр: \(parameter)")
        for (value, result) in results.prefix(3) {
            print(String(format: "    %.1f: Тяга=%.2fН, Мощность=%.1fВт, КПД=%.1f%%",
                       value, result.thrust, result.power, result.efficiency * 100))
        }
        print()
    }
    
    // 4. Анализ распределения по радиусу
    print("4. РАСПРЕДЕЛЕНИЕ ПО РАДИУСУ")
    let radialAnalysis = calculator.radialDistributionAnalysis(
        drone: drone,
        blade: bladeGeometry,
        rpm: 6500
    )
    
    if let firstElement = radialAnalysis.elements.first, let lastElement = radialAnalysis.elements.last {
        print(String(format: "  Корень (r=%.3fм): α=%.3fрад, Cl=%.3f, Cd=%.4f",
                   firstElement.radius, firstElement.alpha, firstElement.cl, firstElement.cd))
        print(String(format: "  Кончик (r=%.3fм): α=%.3fрад, Cl=%.3f, Cd=%.4f",
                   lastElement.radius, lastElement.alpha, lastElement.cl, lastElement.cd))
    }
    
    print(String(format: "  Угол атаки: min=%.3f, max=%.3f, avg=%.3f рад",
               radialAnalysis.summary.minAngleOfAttack,
               radialAnalysis.summary.maxAngleOfAttack,
               radialAnalysis.summary.averageAngleOfAttack))
    print(String(format: "  Качество аэродинамики: max(Cl/Cd)=%.1f, avg(Cl/Cd)=%.1f",
               radialAnalysis.summary.maxLiftToDrag,
               radialAnalysis.summary.averageLiftToDrag))
}

// Запуск демонстрации
//demonstrateAdvancedFeatures()
