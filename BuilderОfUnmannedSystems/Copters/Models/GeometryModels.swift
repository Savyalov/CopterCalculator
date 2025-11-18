//
//  GeometryModels.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation
import CoreGraphics

/// # Модель характеристик дрона
/// Содержит все эксплуатационные параметры, необходимые для расчетов проектирования пропеллера
/// Представляет физические характеристики дрона и требования к производительности
public struct DroneSpecs {
    
    // MARK: - Публичные свойства
    
    /// ## Масса дрона
    /// Общая масса дрона включая все компоненты и полезную нагрузку в килограммах
    /// Используется для расчета необходимой тяги для зависания и маневров
    public let mass: Double
    
    /// ## Максимальная скорость
    /// Максимальная расчетная скорость полета в метрах в секунду
    /// Влияет на проектирование пропеллера для различных режимов полета
    public let maxSpeed: Double
    
    /// ## Количество лопастей на пропеллере
    /// Количество лопастей на каждом пропеллере
    /// Влияет на сплошность, эффективность и шумовые характеристики
    public let numberOfBlades: Int
    
    /// ## Количество моторов
    /// Общее количество моторов на дроне
    /// Используется для расчета распределения тяги на каждый мотор
    public let numberOfMotors: Int
    
    /// ## Рабочая высота
    /// Типичная рабочая высота в метрах над уровнем моря
    /// Влияет на плотность воздуха и производительность пропеллера
    public let operatingAltitude: Double
    
    // MARK: - Инициализация
    
    /// ## Инициализатор характеристик дрона
    /// Создает новый набор характеристик дрона
    /// - Parameters:
    ///   - mass: Общая масса дрона в кг
    ///   - maxSpeed: Максимальная скорость в м/с
    ///   - numberOfBlades: Количество лопастей на пропеллере
    ///   - numberOfMotors: Общее количество моторов
    ///   - operatingAltitude: Рабочая высота в метрах
    public init(mass: Double, maxSpeed: Double, numberOfBlades: Int, numberOfMotors: Int, operatingAltitude: Double) {
        self.mass = mass
        self.maxSpeed = maxSpeed
        self.numberOfBlades = numberOfBlades
        self.numberOfMotors = numberOfMotors
        self.operatingAltitude = operatingAltitude
    }
}

/// # Модель геометрии лопасти
/// Определяет геометрические свойства лопасти пропеллера включая радиус, распределение хорды и распределение крутки
/// Используется для расчетов и визуализации
public struct BladeGeometry: Equatable {
    
    // MARK: - Публичные свойства
    
    /// ## Радиус лопасти
    /// Полный радиус лопасти от центра до кончика в метрах
    /// Определяет ометаемую площадь и общий размер пропеллера
    public let radius: Double
    
    /// ## Вырез у корня
    /// Расстояние от центра вращения до начала аэродинамической секции лопасти в метрах
    /// Учитывает ступицу и монтажное оборудование
    public let rootCutout: Double
    
    // MARK: - Соответствие Equatable
    
    /// ## Реализация Equatable
    /// Сравнивает два экземпляра BladeGeometry на равенство
    /// Примечание: Нельзя сравнивать распределения на основе замыканий, поэтому сравниваем на основе sampled значений
    public static func == (lhs: BladeGeometry, rhs: BladeGeometry) -> Bool {
        // Сравниваем основные свойства
        guard lhs.radius == rhs.radius,
              lhs.rootCutout == rhs.rootCutout else {
            return false
        }
        
        // Сэмплируем функции распределения в ключевых точках для сравнения
        let samplePoints = [0.0, 0.25, 0.5, 0.75, 1.0]
        
        for point in samplePoints {
            // Сэмплируем распределение хорды
            let lhsChord = lhs.getChord(at: point)
            let rhsChord = rhs.getChord(at: point)
            
            // Сэмплируем распределение крутки
            let lhsTwist = lhs.getTwist(at: point)
            let rhsTwist = rhs.getTwist(at: point)
            
            // Сравниваем sampled значения с допуском
            if abs(lhsChord - rhsChord) > 1e-10 || abs(lhsTwist - rhsTwist) > 1e-10 {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Приватные свойства (распределения на основе замыканий)
    
    /// ## Функция распределения хорды
    /// Функция, определяющая как длина хорды меняется вдоль радиуса лопасти
    /// - Parameter radialPosition: Нормализованная радиальная позиция (0 у корня, 1 на кончике)
    /// - Returns: Длина хорды в метрах в указанной радиальной позиции
    let chordDistribution: (Double) -> Double
    
    /// ## Функция распределения крутки
    /// Функция, определяющая как крутка лопасти меняется вдоль радиуса
    /// - Parameter radialPosition: Нормализованная радиальная позиция (0 у корня, 1 на кончике)
    /// - Returns: Угол крутки в радианах в указанной радиальной позиции
    let twistDistribution: (Double) -> Double
    
    // MARK: - Инициализация
    
    /// ## Инициализатор геометрии лопасти
    /// Создает новое определение геометрии лопасти
    /// - Parameters:
    ///   - radius: Полный радиус лопасти в метрах
    ///   - rootCutout: Расстояние выреза у корня в метрах
    ///   - chordDistribution: Функция определения распределения длины хорды
    ///   - twistDistribution: Функция определения распределения крутки
    public init(radius: Double, rootCutout: Double,
                chordDistribution: @escaping (Double) -> Double,
                twistDistribution: @escaping (Double) -> Double) {
        self.radius = radius
        self.rootCutout = rootCutout
        self.chordDistribution = chordDistribution
        self.twistDistribution = twistDistribution
    }
    
    // MARK: - Публичные методы
    
    /// ## Получить хорду в позиции
    /// Публичный доступ к функции распределения хорды
    /// - Parameter radialPosition: Нормализованная радиальная позиция (0-1)
    /// - Returns: Длина хорды в метрах
    public func getChord(at radialPosition: Double) -> Double {
        return chordDistribution(radialPosition)
    }
    
    /// ## Получить крутку в позиции
    /// Публичный доступ к функции распределения крутки
    /// - Parameter radialPosition: Нормализованная радиальная позиция (0-1)
    /// - Returns: Угол крутки в радианах
    public func getTwist(at radialPosition: Double) -> Double {
        return twistDistribution(radialPosition)
    }
}

/// # Структура 3D точки
/// Представляет точку в 3D пространстве с координатами двойной точности
/// Используется для генерации сетки и 3D моделирования
public struct BladePoint3D {
    
    // MARK: - Публичные свойства
    
    /// ## Координата X
    /// Координата вдоль продольной оси (обычно радиальное направление лопасти)
    public let x: Double
    
    /// ## Координата Y
    /// Координата вдоль горизонтальной оси (обычно направление вдоль хорды)
    public let y: Double
    
    /// ## Координата Z
    /// Координата вдоль вертикальной оси (обычно направление толщины)
    public let z: Double
    
    // MARK: - Инициализация
    
    /// ## Инициализатор 3D точки
    /// Создает новую 3D точку с указанными координатами
    /// - Parameters:
    ///   - x: Значение координаты X
    ///   - y: Значение координаты Y
    ///   - z: Значение координаты Z
    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

/// # Модель сетки лопасти
/// Полное 3D представление сетки лопасти пропеллера
/// Содержит вершины, грани и нормали для 3D рендеринга и экспорта
public struct BladeMesh {
    
    // MARK: - Публичные свойства
    
    /// ## Вершины сетки
    /// Массив 3D точек определяющих позиции вершин сетки
    /// Каждая вершина представляет угловую точку поверхности лопасти
    public let vertices: [BladePoint3D]
    
    /// ## Грани сетки
    /// Двумерный массив определяющий треугольные грани сетки
    /// Каждая грань содержит 3 индекса указывающих на массив вершин
    public let faces: [[Int]]
    
    /// ## Нормали вершин
    /// Массив векторов нормалей для каждой вершины
    /// Используется для расчетов освещения и сглаженного затенения
    public let normals: [BladePoint3D]
    
    // MARK: - Инициализация
    
    /// ## Инициализатор сетки лопасти
    /// Создает полное представление сетки лопасти
    /// - Parameters:
    ///   - vertices: Массив позиций вершин
    ///   - faces: Массив определений граней
    ///   - normals: Массив нормалей вершин
    public init(vertices: [BladePoint3D], faces: [[Int]], normals: [BladePoint3D]) {
        self.vertices = vertices
        self.faces = faces
        self.normals = normals
    }
}
