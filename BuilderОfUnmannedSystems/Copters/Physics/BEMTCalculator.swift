//
//  BEMTCalculator.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation

/// # Калькулятор теории элемента лопасти и импульса
/// Продвинутая реализация BEMT для прогнозирования производительности пропеллера
/// Сочетает теорию элемента лопасти с теорией импульса для точных результатов
public class BEMTCalculator {
    
    // MARK: - Приватные константы
    
    /// ## Допуск сходимости
    /// Численный допуск для сходимости итерационного решения
    /// Меньшие значения увеличивают точность, но требуют больше итераций
    private let epsilon: Double = 1e-8
    
    /// ## Максимальное количество итераций
    /// Предохранительный предел для итерационных решателей для предотвращения бесконечных циклов
    private let maxIterations = 50
    
    /// ## Модель атмосферы
    /// Модель стандартной атмосферы для свойств, зависящих от высоты
    private let atmosphereModel = StandardAtmosphere()
    
    // MARK: - Публичные методы
    
    /// ## Рассчитать производительность пропеллера
    /// Основная точка входа для расчета производительности пропеллера с использованием BEMT
    /// Обрабатывает полный конвейер расчетов от геометрии до результатов
    /// - Parameters:
    ///   - drone: Характеристики дрона
    ///   - blade: Определение геометрии лопасти
    ///   - airfoil: Аэродинамические данные профиля
    ///   - rpm: Скорость вращения в об/мин
    ///   - flightSpeed: Скорость прямого полета в м/с (0 для зависания)
    ///   - includeElementData: Флаг включения детальных данных по элементам
    /// - Returns: Полные результаты расчета BEMT
    public func calculatePropeller(
        drone: DroneSpecs,
        blade: BladeGeometry,
        airfoil: AirfoilData,
        rpm: Double,
        flightSpeed: Double = 0.0,
        includeElementData: Bool = false
    ) -> BEMTResult {
        
        // Вычисляем атмосферные условия на рабочей высоте
        let atmosphere = atmosphereModel.calculateConditions(altitude: drone.operatingAltitude)
        
        // Преобразуем RPM в угловую скорость (рад/с)
        let omega = rpm * 2.0 * .pi / 60.0
        
        // Дискретизируем лопасть на элементы для анализа
        let numberOfElements = 30
        let dr = (blade.radius - blade.rootCutout) / Double(numberOfElements)
        
        // Инициализируем аккумуляторы результатов
        var totalThrust: Double = 0.0
        var totalTorque: Double = 0.0
        var maxResidual: Double = 0.0
        var totalIterations: Int = 0
        var residualHistory: [Double] = []
        var elementIterations: [Int] = []
        var elementData: [BladeElementData] = []
        
        // Обрабатываем каждый элемент лопасти
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
            
            // Аккумулируем результаты
            totalThrust += elementResult.thrust
            totalTorque += elementResult.torque
            maxResidual = max(maxResidual, elementResult.residual)
            totalIterations += elementResult.iterations
            elementIterations.append(elementResult.iterations)
            
            // Сохраняем историю сходимости от репрезентативного элемента
            if i == numberOfElements / 2 {
                residualHistory = elementResult.residualHistory
            }
            
            // Сохраняем детальные данные элемента если запрошено
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
        
        // Масштабируем результаты для нескольких моторов и лопастей
        totalThrust *= Double(drone.numberOfMotors)
        totalTorque *= Double(drone.numberOfMotors)
        
        // Вычисляем мощность и эффективность
        let power = totalTorque * omega
        let efficiency = calculateEfficiency(
            thrust: totalThrust,
            power: power,
            speed: flightSpeed,
            area: .pi * pow(blade.radius, 2),
            density: atmosphere.density
        )
        
        // Возвращаем комплексные результаты
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
    
    // MARK: - Приватные методы расчетов
    
    /// ## Рассчитать одиночный элемент лопасти
    /// Выполняет анализ BEMT на одиночном радиальном элементе лопасти
    /// Решает связанные уравнения с использованием итераций Ньютона-Рафсона
    /// - Parameters:
    ///   - r: Радиальная позиция центра элемента
    ///   - dr: Радиальная ширина элемента
    ///   - blade: Геометрия лопасти
    ///   - airfoil: Данные профиля
    ///   - omega: Угловая скорость
    ///   - flightSpeed: Скорость полета вперед
    ///   - numberOfBlades: Количество лопастей
    ///   - atmosphere: Атмосферные условия
    /// - Returns: Данные производительности и сходимости элемента
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
        
        // Вычисляем улучшенное начальное приближение для индуцированных скоростей
        let (initialAxial, initialTangential) = calculateImprovedInitialGuess(
            r: r, R: blade.radius, omega: omega, flightSpeed: flightSpeed,
            numberOfBlades: numberOfBlades, chord: blade.chordDistribution(r / blade.radius),
            twist: blade.twistDistribution(r / blade.radius), density: atmosphere.density
        )
        
        // Инициализируем переменные итераций
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
        
        // Цикл итерационного решения
        while residual > epsilon && iterations < maxIterations {
            iterations += 1
            
            // Выполняем итерацию Ньютона-Рафсона
            let (newAxial, newTangential, thrust, torque, alpha, cl, cd, reynolds, mach, currentResidual) = newtonRaphsonIteration(
                r: r, dr: dr, blade: blade, airfoil: airfoil, omega: omega,
                flightSpeed: flightSpeed, numberOfBlades: numberOfBlades,
                atmosphere: atmosphere,
                currentAxial: axialInduced, currentTangential: tangentialInduced
            )
            
            // Обновляем отслеживание сходимости
            residual = currentResidual
            residualHistory.append(residual)
            
            // Применяем адаптивную релаксацию для стабильности
            let relaxation = calculateAdaptiveRelaxation(
                iteration: iterations,
                residual: residual,
                residualHistory: residualHistory
            )
            
            // Обновляем индуцированные скорости
            axialInduced = axialInduced + relaxation * (newAxial - axialInduced)
            tangentialInduced = tangentialInduced + relaxation * (newTangential - tangentialInduced)
            
            // Сохраняем текущие результаты
            finalThrust = thrust
            finalTorque = torque
            finalAlpha = alpha
            finalCl = cl
            finalCd = cd
            finalReynolds = reynolds
            finalMach = mach
            
            // Проверяем на расходимость и применяем резервный метод если нужно
            if iterations > 10 && residual > 1.0 {
                return calculateBladeElementFallback(
                    r: r, dr: dr, blade: blade, airfoil: airfoil, omega: omega,
                    flightSpeed: flightSpeed, numberOfBlades: numberOfBlades,
                    atmosphere: atmosphere
                )
            }
        }
        
        // Возвращаем финальные сходящиеся результаты
        return (finalThrust, finalTorque, residual, iterations, residualHistory,
                finalAlpha, finalCl, finalCd, finalReynolds, finalMach)
    }
    
    /// ## Расчет улучшенного начального приближения
    /// Предоставляет интеллектуальные начальные значения для индуцированных скоростей
    /// Уменьшает количество итераций и улучшает стабильность сходимости
    /// - Parameters:
    ///   - r: Радиальная позиция
    ///   - R: Радиус лопасти
    ///   - omega: Угловая скорость
    ///   - flightSpeed: Скорость полета вперед
    ///   - numberOfBlades: Количество лопастей
    ///   - chord: Локальная длина хорды
    ///   - twist: Локальный угол крутки
    ///   - density: Плотность воздуха
    /// - Returns: Начальные приближения для осевой и тангенциальной индуцированных скоростей
    private func calculateImprovedInitialGuess(
        r: Double, R: Double, omega: Double, flightSpeed: Double,
        numberOfBlades: Int, chord: Double, twist: Double, density: Double
    ) -> (axial: Double, tangential: Double) {
        
        let tipSpeed = omega * R
        let localSpeed = omega * r  // Локальная окружная скорость на радиусе r
        
        if flightSpeed == 0 {
            // Режим зависания - эмпирическая формула на основе вихревой теории
            let solidity = (Double(numberOfBlades) * chord) / (2.0 * .pi * r)
            
            // Улучшенная оценка с использованием локальной скорости
            let axialGuess = localSpeed * 0.15 * (r/R) * (1.0 + 0.1 * solidity)
            
            // Учитываем эффекты сплошности и крутки
            let twistEffect = max(0.1, 1.0 - abs(twist - 0.2) / 0.5)
            let tangentialGuess = axialGuess * 0.4 * solidity * twistEffect * (r/R)
            
            return (axialGuess, tangentialGuess)
        } else {
            // Режим прямого полета - оценка на основе коэффициента прохождения
            let advanceRatio = flightSpeed / tipSpeed
            let radialPosition = r / R
            
            // Улучшенная модель с использованием локальной скорости
            let speedRatio = localSpeed / tipSpeed
            let axialGuess = flightSpeed * (0.08 + 0.04 * advanceRatio) * (1.0 - radialPosition) +
                            localSpeed * 0.02 * speedRatio
            let tangentialGuess = flightSpeed * (0.015 + 0.008 * advanceRatio) * radialPosition +
                                 localSpeed * 0.01 * (1.0 - speedRatio)
            
            return (axialGuess, tangentialGuess)
        }
    }
    
    /// ## Расчет адаптивной релаксации
    /// Динамически регулирует коэффициент релаксации на основе поведения сходимости
    /// Улучшает стабильность и ускоряет сходимость
    /// - Parameters:
    ///   - iteration: Текущий номер итерации
    ///   - residual: Текущее значение невязки
    ///   - residualHistory: История предыдущих невязок
    /// - Returns: Адаптивный коэффициент релаксации (от 0.0 до 1.0)
    private func calculateAdaptiveRelaxation(iteration: Int, residual: Double, residualHistory: [Double]) -> Double {
        let baseRelaxation = 0.3
        
        // Начинаем с консервативной релаксации
        if iteration < 3 {
            return 0.1
        }
        
        // Анализируем тренд сходимости
        if residualHistory.count >= 3 {
            let recentImprovement = residualHistory[residualHistory.count-3] - residual
            let improvementRatio = recentImprovement / residualHistory[residualHistory.count-3]
            
            if improvementRatio > 0.3 {
                // Быстрая сходимость - увеличиваем размер шага
                return min(0.8, baseRelaxation * 1.5)
            } else if improvementRatio < 0.05 {
                // Медленная сходимость - уменьшаем размер шага
                return max(0.1, baseRelaxation * 0.7)
            }
        }
        
        // Консервативная релаксация для больших невязок
        if residual > 1.0 {
            return 0.1
        }
        
        return baseRelaxation
    }
    
    /// ## Итерация Ньютона-Рафсона
    /// Выполняет одиночную итерацию метода Ньютона-Рафсона для уравнений BEMT
    /// Решает связанную систему для индуцированных скоростей
    /// - Parameters:
    ///   - r: Радиальная позиция
    ///   - dr: Ширина элемента
    ///   - blade: Геометрия лопасти
    ///   - airfoil: Данные профиля
    ///   - omega: Угловая скорость
    ///   - flightSpeed: Скорость полета вперед
    ///   - numberOfBlades: Количество лопастей
    ///   - atmosphere: Атмосферные условия
    ///   - currentAxial: Текущая осевая индуцированная скорость
    ///   - currentTangential: Текущая тангенциальная индуцированная скорость
    /// - Returns: Обновленные скорости, силы и данные сходимости
    private func newtonRaphsonIteration(
        r: Double, dr: Double, blade: BladeGeometry, airfoil: AirfoilData, omega: Double,
        flightSpeed: Double, numberOfBlades: Int,
        atmosphere: (temperature: Double, pressure: Double, density: Double, speedOfSound: Double, kinematicViscosity: Double),
        currentAxial: Double, currentTangential: Double
    ) -> (axial: Double, tangential: Double, thrust: Double, torque: Double, alpha: Double, cl: Double, cd: Double, reynolds: Double, mach: Double, residual: Double) {
        
        // Вычисляем силы и условия потока
        let (thrustBET, torqueBET, alpha, cl, cd, reynolds, mach) = calculateForces(
            r: r, dr: dr, blade: blade, airfoil: airfoil, omega: omega,
            flightSpeed: flightSpeed, numberOfBlades: numberOfBlades,
            atmosphere: atmosphere,
            axialInduced: currentAxial, tangentialInduced: currentTangential
        )
        
        // Вычисляем коэффициент потерь на конце
        let tipLossFactor = calculateTipLossFactor(
            r: r, R: blade.radius, numberOfBlades: numberOfBlades,
            inflowAngle: calculateInflowAngle(
                r: r, omega: omega, flightSpeed: flightSpeed,
                axialInduced: currentAxial, tangentialInduced: currentTangential
            )
        )
        
        // Уравнения теории импульса
        let thrustMT = 4.0 * .pi * atmosphere.density * r * dr *
                      (flightSpeed + currentAxial) * currentAxial * tipLossFactor
        let torqueMT = 4.0 * .pi * atmosphere.density * pow(r, 3) * dr *
                      omega * currentTangential * tipLossFactor
        
        // Вычисляем невязки
        let residual1 = thrustBET - thrustMT
        let residual2 = torqueBET - torqueMT
        let residual = max(abs(residual1), abs(residual2))
        
        // Решаем для новых индуцированных скоростей
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
    
    /// ## Вычислить аэродинамические силы
    /// Вычисляет вклады тяги и крутящего момента от элемента лопасти
    /// - Parameters:
    ///   - r: Радиальная позиция
    ///   - dr: Ширина элемента
    ///   - blade: Геометрия лопасти
    ///   - airfoil: Данные профиля
    ///   - omega: Угловая скорость
    ///   - flightSpeed: Скорость полета вперед
    ///   - numberOfBlades: Количество лопастей
    ///   - atmosphere: Атмосферные условия
    ///   - axialInduced: Осевая индуцированная скорость
    ///   - tangentialInduced: Тангенциальная индуцированная скорость
    /// - Returns: Силы, углы и условия потока
    private func calculateForces(
        r: Double, dr: Double, blade: BladeGeometry, airfoil: AirfoilData, omega: Double,
        flightSpeed: Double, numberOfBlades: Int,
        atmosphere: (temperature: Double, pressure: Double, density: Double, speedOfSound: Double, kinematicViscosity: Double),
        axialInduced: Double, tangentialInduced: Double
    ) -> (thrust: Double, torque: Double, alpha: Double, cl: Double, cd: Double, reynolds: Double, mach: Double) {
        
        // Вычисляем локальные скорости
        let ut = omega * r - tangentialInduced
        let up = flightSpeed + axialInduced
        
        // Вычисляем угол притекания и угол атаки
        let inflowAngle = atan2(up, ut)
        let bladeTwist = blade.twistDistribution(r / blade.radius)
        var alpha = bladeTwist - inflowAngle
        
        // Ограничиваем угол атаки разумным диапазоном
        alpha = max(-0.35, min(0.35, alpha))
        
        // Получаем локальную геометрию
        let chord = blade.chordDistribution(r / blade.radius)
        let w = sqrt(ut * ut + up * up)
        
        // Вычисляем параметры потока
        let reynolds = w * chord / atmosphere.kinematicViscosity
        let mach = w / atmosphere.speedOfSound
        
        // Получаем аэродинамические коэффициенты
        var (cl, cd, _) = AirfoilCalculator.getCoefficients(for: airfoil, alpha: alpha, reynolds: reynolds)
        
        // Применяем поправку на сжимаемость
        (cl, cd) = AirfoilCalculator.applyCompressibilityCorrection(cl: cl, cd: cd, mach: mach)
        
        // Вычисляем силы
        let dynamicPressure = 0.5 * atmosphere.density * w * w
        let dL = dynamicPressure * chord * dr * cl
        let dD = dynamicPressure * chord * dr * cd
        
        // Разлагаем силы на тягу и крутящий момент
        let thrust = Double(numberOfBlades) * (dL * cos(inflowAngle) - dD * sin(inflowAngle))
        let torque = Double(numberOfBlades) * r * (dL * sin(inflowAngle) + dD * cos(inflowAngle))
        
        return (thrust, torque, alpha, cl, cd, reynolds, mach)
    }
    
    // MARK: - Вспомогательные методы
    
    /// ## Вычислить коэффициент потерь на конце
    /// Поправка коэффициента потерь на конце Прандтля
    /// Учитывает конечное количество лопастей и концевые вихри
    private func calculateTipLossFactor(r: Double, R: Double, numberOfBlades: Int, inflowAngle: Double) -> Double {
        let f = Double(numberOfBlades) * (R - r) / (2.0 * r * sin(inflowAngle))
        return (2.0 / .pi) * acos(exp(-f))
    }
    
    /// ## Вычислить угол притекания
    /// Угол между плоскостью вращения и результирующим потоком
    private func calculateInflowAngle(r: Double, omega: Double, flightSpeed: Double, axialInduced: Double, tangentialInduced: Double) -> Double {
        let ut = omega * r - tangentialInduced
        let up = flightSpeed + axialInduced
        return atan2(up, ut)
    }
    
    /// ## Решить для осевой индуцированной скорости
    /// Аналитическое решение для осевой индуцированной скорости из теории импульса
    private func solveForAxialInduced(thrustBET: Double, flightSpeed: Double, r: Double, dr: Double, density: Double, tipLossFactor: Double) -> Double {
        if thrustBET <= 0 { return 0.0 }
        
        let term = thrustBET / (4.0 * .pi * density * r * dr * tipLossFactor)
        if flightSpeed == 0 {
            return sqrt(term) / 2.0
        } else {
            return (-flightSpeed + sqrt(flightSpeed * flightSpeed + 4.0 * term)) / 2.0
        }
    }
    
    /// ## Решить для тангенциальной индуцированной скорости
    /// Аналитическое решение для тангенциальной индуцированной скорости из теории импульса
    private func solveForTangentialInduced(torqueBET: Double, omega: Double, r: Double, dr: Double, density: Double, tipLossFactor: Double) -> Double {
        if torqueBET <= 0 { return 0.0 }
        return torqueBET / (4.0 * .pi * density * pow(r, 3) * dr * omega * tipLossFactor)
    }
    
    /// ## Резервный метод расчета
    /// Упрощенный расчет когда итерационный метод не сходится
    /// Предоставляет разумные оценки без итераций
    private func calculateBladeElementFallback(
        r: Double, dr: Double, blade: BladeGeometry, airfoil: AirfoilData, omega: Double,
        flightSpeed: Double, numberOfBlades: Int,
        atmosphere: (temperature: Double, pressure: Double, density: Double, speedOfSound: Double, kinematicViscosity: Double)
    ) -> (thrust: Double, torque: Double, residual: Double, iterations: Int, residualHistory: [Double], alpha: Double, cl: Double, cd: Double, reynolds: Double, mach: Double) {
        
        // Упрощенный расчет без индуцированных скоростей
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
    
    /// ## Вычислить эффективность пропеллера
    /// Вычисляет метрику эффективности для текущих рабочих условий
    /// Разные формулы для зависания и прямого полета
    private func calculateEfficiency(thrust: Double, power: Double, speed: Double, area: Double, density: Double) -> Double {
        guard power > 0 else { return 0.0 }
        
        if speed == 0 {
            // Показатель качества для зависания
            let idealPower = thrust * sqrt(thrust / (2.0 * density * area))
            return idealPower / power
        } else {
            // Движущая эффективность для прямого полета
            return (thrust * speed) / power
        }
    }
}
