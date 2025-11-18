//
//  Blade2DRenderer.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation
import SwiftUI

/// # 2D Визуализатор лопасти
/// Создает 2D технические чертежи лопастей пропеллера
/// Генерирует виды сверху, сечения и размерные обозначения
public class Blade2DRenderer {
    
    // MARK: - Публичные методы
    
    /// ## Создать контур вида сверху
    /// Генерирует путь в стиле SVG для проекции вида сверху лопасти
    /// Показывает форму в плане с точным распределением хорды
    /// - Parameters:
    ///   - geometry: Определение геометрии лопасти
    ///   - size: Размер холста для рисования
    /// - Returns: Path SwiftUI, представляющий вид сверху
    public static func createTopViewPath(geometry: BladeGeometry, size: CGSize) -> Path {
        var path = Path()
        let scale = min(size.width, size.height) / CGFloat(geometry.radius * 2.2)
        
        // Рисуем контур лопасти от корня к кончику и обратно
        let segments = 100
        for i in 0...segments {
            let r = geometry.rootCutout + (geometry.radius - geometry.rootCutout) * Double(i) / Double(segments)
            let chord = geometry.chordDistribution(r / geometry.radius)
            
            let x = CGFloat(r) * scale + size.width / 2
            let yTop = size.height / 2 - CGFloat(chord / 2) * scale
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: yTop))
            } else {
                path.addLine(to: CGPoint(x: x, y: yTop))
            }
        }
        
        for i in (0...segments).reversed() {
            let r = geometry.rootCutout + (geometry.radius - geometry.rootCutout) * Double(i) / Double(segments)
            let chord = geometry.chordDistribution(r / geometry.radius)
            
            let x = CGFloat(r) * scale + size.width / 2
            let yBottom = size.height / 2 + CGFloat(chord / 2) * scale
            
            path.addLine(to: CGPoint(x: x, y: yBottom))
        }
        
        path.closeSubpath()
        return path
    }
    
    /// ## Создать контур сечения
    /// Генерирует вид сечения на указанной радиальной позиции
    /// Показывает форму профиля с соответствующей толщиной и кривизной
    /// - Parameters:
    ///   - geometry: Определение геометрии лопасти
    ///   - size: Размер холста для рисования
    ///   - radiusFraction: Радиальная позиция (0 = корень, 1 = кончик)
    /// - Returns: Path SwiftUI, представляющий вид сечения
    public static func createSectionViewPath(geometry: BladeGeometry, size: CGSize, at radiusFraction: Double = 0.7) -> Path {
        var path = Path()
        
        // Вычисляем радиус и хорду для указанной позиции
        let r = geometry.rootCutout + (geometry.radius - geometry.rootCutout) * radiusFraction
        let normalizedRadius = (r - geometry.rootCutout) / (geometry.radius - geometry.rootCutout)
        let chord = geometry.chordDistribution(normalizedRadius)
        let twist = geometry.getTwist(at: normalizedRadius)
        
        let scale = min(size.width, size.height) / CGFloat(chord * 3)
        
        // Рисуем упрощенную форму профиля с учетом крутки
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        // Координаты верхней поверхности
        for i in 0...20 {
            let t = Double(i) / 20.0
            let x = CGFloat(t * chord) * scale
            let y = CGFloat(sin(t * .pi) * chord * 0.1) * scale // Упрощенная кривая профиля
            
            // Применяем поворот на угол крутки
            let rotatedX = x * CGFloat(cos(twist)) - y * CGFloat(sin(twist))
            let rotatedY = x * CGFloat(sin(twist)) + y * CGFloat(cos(twist))
            
            if i == 0 {
                path.move(to: CGPoint(x: centerX - CGFloat(chord/2) * scale + rotatedX,
                                    y: centerY - rotatedY))
            } else {
                path.addLine(to: CGPoint(x: centerX - CGFloat(chord/2) * scale + rotatedX,
                                       y: centerY - rotatedY))
            }
        }
        
        // Координаты нижней поверхности
        for i in (0...20).reversed() {
            let t = Double(i) / 20.0
            let x = CGFloat(t * chord) * scale
            let y = CGFloat(sin(t * .pi) * chord * 0.08) * scale // Другая кривая для нижней поверхности
            
            // Применяем поворот на угол крутки
            let rotatedX = x * CGFloat(cos(twist)) - y * CGFloat(sin(twist))
            let rotatedY = x * CGFloat(sin(twist)) + y * CGFloat(cos(twist))
            
            path.addLine(to: CGPoint(x: centerX - CGFloat(chord/2) * scale + rotatedX,
                                   y: centerY + rotatedY))
        }
        
        path.closeSubpath()
        
        // Добавляем линию, показывающую ориентацию сечения относительно оси вращения
        let referenceLineLength = CGFloat(chord) * scale * 1.5
        path.move(to: CGPoint(x: centerX - referenceLineLength / 2, y: centerY))
        path.addLine(to: CGPoint(x: centerX + referenceLineLength / 2, y: centerY))
        
        return path
    }
    
    /// ## Создать вид сбоку с круткой
    /// Генерирует вид сбоку лопасти, показывающий распределение крутки по радиусу
    /// - Parameters:
    ///   - geometry: Определение геометрии лопасти
    ///   - size: Размер холста для рисования
    /// - Returns: Path SwiftUI, представляющий вид сбоку с круткой
    public static func createTwistViewPath(geometry: BladeGeometry, size: CGSize) -> Path {
        var path = Path()
        let scale = min(size.width, size.height) / CGFloat(geometry.radius * 2.2)
        
        // Вычисляем крутку у корня и на конце для маркеров
        let rootTwist = geometry.getTwist(at: 0)
        let tipTwist = geometry.getTwist(at: 1.0)
        
        // Рисуем линию крутки от корня к кончику
        let segments = 100
        for i in 0...segments {
            let r = geometry.rootCutout + (geometry.radius - geometry.rootCutout) * Double(i) / Double(segments)
            let normalizedRadius = (r - geometry.rootCutout) / (geometry.radius - geometry.rootCutout)
            let twist = geometry.getTwist(at: normalizedRadius)
            
            // Преобразуем крутку в смещение по Y для визуализации
            let x = CGFloat(r) * scale + size.width / 4
            let y = size.height / 2 - CGFloat(twist) * scale * 50 // Масштабируем для наглядности
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            // Добавляем маркеры каждые 10% радиуса
            if i % 10 == 0 {
                let markerSize: CGFloat = 4
                path.addEllipse(in: CGRect(x: x - markerSize/2, y: y - markerSize/2,
                                         width: markerSize, height: markerSize))
                
                // Добавляем вертикальные линии от маркеров до оси
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x, y: size.height / 2))
            }
        }
        
        // Добавляем особые маркеры для крутки у корня и на конце
        let rootX = CGFloat(geometry.rootCutout) * scale + size.width / 4
        let rootY = size.height / 2 - CGFloat(rootTwist) * scale * 50
        let tipX = CGFloat(geometry.radius) * scale + size.width / 4
        let tipY = size.height / 2 - CGFloat(tipTwist) * scale * 50
        
        // Рисуем маркеры (кружки) в точках корня и конца
        path.addEllipse(in: CGRect(x: rootX - 3, y: rootY - 3, width: 6, height: 6))
        path.addEllipse(in: CGRect(x: tipX - 3, y: tipY - 3, width: 6, height: 6))
        
        // Добавляем опорные линии для шкалы крутки
        // Линия нулевой крутки
        let zeroY = size.height / 2
        path.move(to: CGPoint(x: size.width / 4, y: zeroY))
        path.addLine(to: CGPoint(x: size.width / 4 + CGFloat(geometry.radius) * scale, y: zeroY))
        
        // Линии для отметки значений крутки у корня и на конце
        path.move(to: CGPoint(x: rootX - 10, y: rootY))
        path.addLine(to: CGPoint(x: rootX + 10, y: rootY))
        
        path.move(to: CGPoint(x: tipX - 10, y: tipY))
        path.addLine(to: CGPoint(x: tipX + 10, y: tipY))
        
        // Добавляем подписи для маркеров радиуса
        for i in 0...10 {
            let r = geometry.rootCutout + (geometry.radius - geometry.rootCutout) * Double(i) / 10.0
            let normalizedRadius = (r - geometry.rootCutout) / (geometry.radius - geometry.rootCutout)
            let twist = geometry.getTwist(at: normalizedRadius)
            
            let x = CGFloat(r) * scale + size.width / 4
            let y = size.height / 2 - CGFloat(twist) * scale * 50
            
            // Рисуем короткую горизонтальную линию у маркера
            path.move(to: CGPoint(x: x - 5, y: y))
            path.addLine(to: CGPoint(x: x + 5, y: y))
        }
        
        return path
    }
    
    /// ## Создать размерные линии
    /// Генерирует размерные обозначения для технических чертежей
    /// Добавляет измерительные линии с метками для ключевых геометрических параметров
    /// - Parameters:
    ///   - geometry: Определение геометрии лопасти
    ///   - size: Размер холста для рисования
    /// - Returns: Массив определений размерных линий
    public static func createDimensionLines(geometry: BladeGeometry, size: CGSize) -> [DimensionLine] {
        var dimensions: [DimensionLine] = []
        
        let scale = min(size.width, size.height) / CGFloat(geometry.radius * 2.2)
        
        // Размер радиуса лопасти
        dimensions.append(DimensionLine(
            start: CGPoint(x: size.width / 2 + CGFloat(geometry.rootCutout) * scale, y: size.height - 30),
            end: CGPoint(x: size.width / 2 + CGFloat(geometry.radius) * scale, y: size.height - 30),
            text: String(format: "%.0f мм", geometry.radius * 1000)
        ))
        
        // Размер хорды у корня
        let rootChord = geometry.chordDistribution(0)
        dimensions.append(DimensionLine(
            start: CGPoint(x: 30, y: size.height / 2 - CGFloat(rootChord/2) * scale),
            end: CGPoint(x: 30, y: size.height / 2 + CGFloat(rootChord/2) * scale),
            text: String(format: "%.0f мм", rootChord * 1000)
        ))
        
        // Добавляем размер хорды на радиусе 70% (где обычно максимальная хорда)
        let tipChord = geometry.chordDistribution(0.7)
        dimensions.append(DimensionLine(
            start: CGPoint(x: size.width - 30, y: size.height / 2 - CGFloat(tipChord/2) * scale),
            end: CGPoint(x: size.width - 30, y: size.height / 2 + CGFloat(tipChord/2) * scale),
            text: String(format: "%.0f мм", tipChord * 1000)
        ))
        
        // Добавляем размеры крутки
        let rootTwist = geometry.getTwist(at: 0)
        let tipTwist = geometry.getTwist(at: 1.0)
        
        dimensions.append(DimensionLine(
            start: CGPoint(x: 30, y: size.height / 2 - 100),
            end: CGPoint(x: 30, y: size.height / 2 - 100 - CGFloat(rootTwist) * 200),
            text: String(format: "Крутка у корня: %.1f°", rootTwist * 180 / .pi)
        ))
        
        dimensions.append(DimensionLine(
            start: CGPoint(x: size.width - 30, y: size.height / 2 - 100),
            end: CGPoint(x: size.width - 30, y: size.height / 2 - 100 - CGFloat(tipTwist) * 200),
            text: String(format: "Крутка на конце: %.1f°", tipTwist * 180 / .pi)
        ))
        
        return dimensions
    }
    
    /// ## Получить данные о распределении крутки
    /// Вычисляет значения крутки в различных радиальных позициях
    /// - Parameter geometry: Определение геометрии лопасти
    /// - Returns: Массив кортежей (радиус, крутка в радианах, крутка в градусах)
    public static func getTwistDistribution(geometry: BladeGeometry) -> [(radius: Double, twistRadians: Double, twistDegrees: Double)] {
        var distribution: [(Double, Double, Double)] = []
        
        let segments = 10
        for i in 0...segments {
            let r = geometry.rootCutout + (geometry.radius - geometry.rootCutout) * Double(i) / Double(segments)
            let normalizedRadius = (r - geometry.rootCutout) / (geometry.radius - geometry.rootCutout)
            let twist = geometry.getTwist(at: normalizedRadius)
            let twistDegrees = twist * 180 / .pi
            
            distribution.append((r, twist, twistDegrees))
        }
        
        return distribution
    }
    
    /// ## Получить информацию о сечении
    /// Генерирует детальную информацию о сечении на указанном радиусе
    /// - Parameters:
    ///   - geometry: Определение геометрии лопасти
    ///   - radiusFraction: Радиальная позиция (0 = корень, 1 = кончик)
    /// - Returns: Структура с детальной информацией о сечении
    public static func getSectionInfo(geometry: BladeGeometry, at radiusFraction: Double) -> SectionInfo {
        let r = geometry.rootCutout + (geometry.radius - geometry.rootCutout) * radiusFraction
        let normalizedRadius = (r - geometry.rootCutout) / (geometry.radius - geometry.rootCutout)
        let chord = geometry.chordDistribution(normalizedRadius)
        let twist = geometry.getTwist(at: normalizedRadius)
        
        return SectionInfo(
            radius: r,
            normalizedRadius: normalizedRadius,
            chord: chord,
            twistRadians: twist,
            twistDegrees: twist * 180 / .pi
        )
    }
}

/// # Информация о сечении
/// Содержит детальные данные о геометрии сечения лопасти
public struct SectionInfo {
    
    // MARK: - Публичные свойства
    
    /// ## Абсолютный радиус
    /// Радиус сечения от центра вращения в метрах
    public let radius: Double
    
    /// ## Нормализованный радиус
    /// Радиус сечения в нормализованных координатах (0-1)
    public let normalizedRadius: Double
    
    /// ## Длина хорды
    /// Длина хорды сечения в метрах
    public let chord: Double
    
    /// ## Угол крутки
    /// Угол крутки сечения в радианах
    public let twistRadians: Double
    
    /// ## Угол крутки
    /// Угол крутки сечения в градусах
    public let twistDegrees: Double
    
    // MARK: - Инициализация
    
    /// ## Инициализатор информации о сечении
    /// Создает новую структуру с информацией о сечении
    /// - Parameters:
    ///   - radius: Абсолютный радиус
    ///   - normalizedRadius: Нормализованный радиус
    ///   - chord: Длина хорды
    ///   - twistRadians: Угол крутки в радианах
    ///   - twistDegrees: Угол крутки в градусах
    public init(radius: Double, normalizedRadius: Double, chord: Double, twistRadians: Double, twistDegrees: Double) {
        self.radius = radius
        self.normalizedRadius = normalizedRadius
        self.chord = chord
        self.twistRadians = twistRadians
        self.twistDegrees = twistDegrees
    }
}

/// # Модель размерной линии
/// Представляет размерное обозначение в технических чертежах
/// Содержит данные о позиции и текстовую метку для отображения измерений
public struct DimensionLine {
    
    // MARK: - Публичные свойства
    
    /// ## Начальная точка
    /// Начальная координата размерной линии в координатах чертежа
    /// Обычно соединяется с одним концом измеряемого элемента
    public let start: CGPoint
    
    /// ## Конечная точка
    /// Конечная координата размерной линии в координатах чертежа
    /// Обычно соединяется с другим концом измеряемого элемента
    public let end: CGPoint
    
    /// ## Размерный текст
    /// Текстовая метка, отображающая измеренное значение с единицами
    /// Форматируется в соответствии с инженерными стандартами
    public let text: String
    
    // MARK: - Инициализация
    
    /// ## Инициализатор размерной линии
    /// Создает новое размерное обозначение
    /// - Parameters:
    ///   - start: Координата начальной точки
    ///   - end: Координата конечной точки
    ///   - text: Текстовая метка размера
    public init(start: CGPoint, end: CGPoint, text: String) {
        self.start = start
        self.end = end
        self.text = text
    }
}
