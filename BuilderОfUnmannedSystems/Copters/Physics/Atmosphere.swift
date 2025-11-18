//
//  Atmosphere.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation

/// # Модель атмосферного слоя
/// Представляет слой в стандартной атмосфере с постоянным градиентом температуры
/// Используется для кусочно-непрерывного расчета атмосферных свойств
public struct AtmosphericLayer {
    
    // MARK: - Публичные свойства
    
    /// ## Базовая высота
    /// Высота в нижней части слоя в метрах над уровнем моря
    /// Опорная точка для расчетов температуры и давления
    public let baseAltitude: Double
    
    /// ## Базовая температура
    /// Температура в основании слоя в Кельвинах
    /// Опорная температура для расчетов градиента
    public let baseTemperature: Double
    
    /// ## Градиент температуры
    /// Скорость изменения температуры с высотой в К/м
    /// Положительный для инверсионных слоев, отрицательный для нормального градиента
    public let temperatureGradient: Double
    
    /// ## Базовое давление
    /// Давление в основании слоя в Паскалях
    /// Опорное давление для барометрических расчетов
    public let basePressure: Double
    
    // MARK: - Инициализация
    
    /// ## Инициализатор атмосферного слоя
    /// Создает новое определение атмосферного слоя
    /// - Parameters:
    ///   - baseAltitude: Базовая высота слоя в метрах
    ///   - baseTemperature: Базовая температура в Кельвинах
    ///   - temperatureGradient: Градиент температуры в К/м
    ///   - basePressure: Базовое давление в Паскалях
    public init(baseAltitude: Double, baseTemperature: Double, temperatureGradient: Double, basePressure: Double) {
        self.baseAltitude = baseAltitude
        self.baseTemperature = baseTemperature
        self.temperatureGradient = temperatureGradient
        self.basePressure = basePressure
    }
}

/// # Калькулятор стандартной атмосферы
/// Реализует модель Международной стандартной атмосферы (ISA)
/// Вычисляет атмосферные свойства на любой высоте до 86 км
public class StandardAtmosphere {
    
    // MARK: - Физические константы
    
    /// ## Газовая постоянная для воздуха
    /// Удельная газовая постоянная для сухого воздуха в Дж/(кг·К)
    /// Используется в расчетах по уравнению состояния идеального газа
    private let gasConstant = 287.05
    
    /// ## Гравитационное ускорение
    /// Стандартное гравитационное ускорение в м/с²
    /// Используется для расчетов по гидростатическому уравнению
    private let gravity = 9.80665
    
    /// ## Показатель адиабаты
    /// Отношение удельных теплоемкостей для воздуха (гамма = cp/cv)
    /// Используется для расчетов скорости звука
    private let gamma = 1.4
    
    /// ## Константа Сазерленда
    /// Константа Сазерленда для расчета вязкости в Кельвинах
    /// Используется в законе Сазерленда для динамической вязкости
    private let sutherlandConstant = 110.4
    
    /// ## Референсная динамическая вязкость
    /// Референсный коэффициент для расчета динамической вязкости в кг/(м·с·K^0.5)
    /// Используется в формуле вязкости Сазерленда
    private let referenceViscosity = 1.458e-6
    
    // MARK: - Атмосферные слои
    
    /// ## Атмосферные слои ISA
    /// Массив атмосферных слоев согласно ICAO Standard Atmosphere
    /// Охватывает высоты от уровня моря до 86 км с соответствующими градиентами
    private let layers: [AtmosphericLayer] = [
        // 0: Тропосфера (0-11 км)
        AtmosphericLayer(baseAltitude: 0, baseTemperature: 288.15, temperatureGradient: -0.0065, basePressure: 101325),
        // 1: Тропопауза (11-20 км)
        AtmosphericLayer(baseAltitude: 11000, baseTemperature: 216.65, temperatureGradient: 0.0, basePressure: 22632),
        // 2: Нижняя стратосфера (20-32 км)
        AtmosphericLayer(baseAltitude: 20000, baseTemperature: 216.65, temperatureGradient: 0.001, basePressure: 5474.9),
        // 3: Верхняя стратосфера (32-47 км)
        AtmosphericLayer(baseAltitude: 32000, baseTemperature: 228.65, temperatureGradient: 0.0028, basePressure: 868.02),
        // 4: Стратопауза (47-51 км)
        AtmosphericLayer(baseAltitude: 47000, baseTemperature: 270.65, temperatureGradient: 0.0, basePressure: 110.91),
        // 5: Нижняя мезосфера (51-71 км)
        AtmosphericLayer(baseAltitude: 51000, baseTemperature: 270.65, temperatureGradient: -0.0028, basePressure: 66.94),
        // 6: Верхняя мезосфера (71-86 км)
        AtmosphericLayer(baseAltitude: 71000, baseTemperature: 214.65, temperatureGradient: -0.002, basePressure: 3.96)
    ]
    
    // MARK: - Публичные методы
    
    /// ## Вычислить атмосферные условия
    /// Вычисляет полные атмосферные свойства на указанной высоте
    /// Использует модель ISA с кусочно-непрерывными слоями
    /// - Parameter altitude: Высота над уровнем моря в метрах
    /// - Returns: Кортеж, содержащий температуру, давление, плотность, скорость звука и кинематическую вязкость
    public func calculateConditions(altitude: Double) -> (temperature: Double, pressure: Double, density: Double, speedOfSound: Double, kinematicViscosity: Double) {
        var currentAltitude = max(0.0, altitude)
        let maxAltitude = 86000.0 // Максимальная высота модели
        
        // Ограничиваем высоту пределами модели
        if currentAltitude > maxAltitude {
            currentAltitude = maxAltitude
        }
        
        // Находим соответствующий атмосферный слой
        var layerIndex = 0
        for i in (0..<layers.count).reversed() {
            if currentAltitude >= layers[i].baseAltitude {
                layerIndex = i
                break
            }
        }
        
        let layer = layers[layerIndex]
        let deltaAltitude = currentAltitude - layer.baseAltitude
        
        // Вычисляем температуру с использованием градиента слоя
        let temperature = layer.baseTemperature + layer.temperatureGradient * deltaAltitude
        
        // Вычисляем давление в зависимости от типа слоя
        let pressure: Double
        if abs(layer.temperatureGradient) < 1e-10 {
            // Изотермический слой - экспоненциальный спад давления
            pressure = layer.basePressure * exp(-gravity * deltaAltitude / (gasConstant * layer.baseTemperature))
        } else {
            // Политропный слой - степенная зависимость давления
            let exponent = -gravity / (layer.temperatureGradient * gasConstant)
            pressure = layer.basePressure * pow(temperature / layer.baseTemperature, exponent)
        }
        
        // Вычисляем плотность по уравнению состояния идеального газа
        let density = pressure / (gasConstant * temperature)
        
        // Вычисляем скорость звука
        let speedOfSound = sqrt(gamma * gasConstant * temperature)
        
        // Вычисляем динамическую вязкость по формуле Сазерленда
        let dynamicViscosity = referenceViscosity * pow(temperature, 1.5) / (temperature + sutherlandConstant)
        
        // Вычисляем кинематическую вязкость
        let kinematicViscosity = dynamicViscosity / density
        
        return (temperature, pressure, density, speedOfSound, kinematicViscosity)
    }
    
    /// ## Сгенерировать таблицу атмосферных свойств
    /// Создает таблицу атмосферных свойств на указанных высотах
    /// Полезно для анализа и визуализации эффектов высоты
    /// - Parameter altitudes: Массив высот в метрах
    /// - Returns: Массив кортежей, содержащих высоту, температуру, давление и плотность
    public func getAtmosphericTable(altitudes: [Double]) -> [(altitude: Double, temperature: Double, pressure: Double, density: Double)] {
        return altitudes.map { altitude in
            let conditions = calculateConditions(altitude: altitude)
            return (altitude, conditions.temperature, conditions.pressure, conditions.density)
        }
    }
}
