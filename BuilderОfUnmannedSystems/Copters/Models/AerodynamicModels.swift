//
//  AerodynamicModels.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation

/// # Модель данных аэродинамического профиля
/// Содержит комплексные аэродинамические коэффициенты для различных чисел Рейнольдса и углов атаки
/// Используется для интерполяции и расчета коэффициентов подъемной силы, сопротивления и момента
public struct AirfoilData {
    
    // MARK: - Публичные свойства
    
    /// ## Массив чисел Рейнольдса
    /// Массив чисел Рейнольдса, для которых доступны аэродинамические данные
    /// Используется для интерполяции коэффициентов для промежуточных чисел Рейнольдса
    public let reynoldsNumbers: [Double]
    
    /// ## Массивы углов атаки
    /// Двумерный массив, содержащий углы атаки (в радианах) для каждого числа Рейнольдса
    /// Первое измерение: индекс числа Рейнольдса
    /// Второе измерение: углы атаки для этого числа Рейнольдса
    public let alpha: [[Double]]
    
    /// ## Массивы коэффициентов подъемной силы
    /// Двумерный массив, содержащий коэффициенты подъемной силы (Cl), соответствующие углам атаки
    /// Используется для расчета подъемной силы на элементах лопасти
    public let cl: [[Double]]
    
    /// ## Массивы коэффициентов сопротивления
    /// Двумерный массив, содержащий коэффициенты сопротивления (Cd), соответствующие углам атаки
    /// Используется для расчета силы сопротивления на элементах лопасти
    public let cd: [[Double]]
    
    /// ## Массивы коэффициентов момента
    /// Двумерный массив, содержащий коэффициенты момента (Cm), соответствующие углам атаки
    /// Используется для расчетов момента тангажа (опционально)
    public let cm: [[Double]]
    
    // MARK: - Инициализация
    
    /// ## Инициализатор
    /// Создает новый экземпляр AirfoilData с указанными аэродинамическими коэффициентами
    /// - Parameters:
    ///   - reynoldsNumbers: Массив чисел Рейнольдса
    ///   - alpha: Двумерный массив углов атаки в радианах
    ///   - cl: Двумерный массив коэффициентов подъемной силы
    ///   - cd: Двумерный массив коэффициентов сопротивления
    ///   - cm: Двумерный массив коэффициентов момента
    public init(reynoldsNumbers: [Double], alpha: [[Double]], cl: [[Double]], cd: [[Double]], cm: [[Double]]) {
        self.reynoldsNumbers = reynoldsNumbers
        self.alpha = alpha
        self.cl = cl
        self.cd = cd
        self.cm = cm
    }
    
    // MARK: - Публичные методы
    
    /// ## Получить аэродинамические коэффициенты
    /// Интерполирует аэродинамические коэффициенты для заданного угла атаки и числа Рейнольдса
    /// Использует билинейную интерполяцию между доступными точками данных
    /// - Parameters:
    ///   - alpha: Угол атаки в радианах
    ///   - reynolds: Число Рейнольдса
    /// - Returns: Кортеж, содержащий коэффициенты (cl, cd, cm)
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
    
    // MARK: - Приватные методы
    
    /// ## Найти индекс Рейнольдса
    /// Определяет соответствующий интервал числа Рейнольдса для интерполяции
    /// - Parameter reynolds: Целевое число Рейнольдса
    /// - Returns: Нижний индекс интервала числа Рейнольдса или nil, если вне диапазона
    private func findReynoldsIndex(_ reynolds: Double) -> Int? {
        for i in 0..<reynoldsNumbers.count-1 {
            if reynolds >= reynoldsNumbers[i] && reynolds <= reynoldsNumbers[i+1] {
                return i
            }
        }
        return nil
    }
    
    /// ## Интерполяция для конкретного числа Рейнольдса
    /// Выполняет линейную интерполяцию коэффициентов для конкретного индекса числа Рейнольдса
    /// - Parameters:
    ///   - index: Индекс числа Рейнольдса в массивах данных
    ///   - alpha: Целевой угол атаки
    /// - Returns: Интерполированные коэффициенты (cl, cd, cm)
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
        return (0, 0.02, 0) // Значения по умолчанию, если вне диапазона
    }
    
    /// ## Интерполяция для одного числа Рейнольдса
    /// Резервный метод, когда целевое число Рейнольдса находится вне доступных диапазонов
    /// Использует данные ближайшего доступного числа Рейнольдса
    /// - Parameters:
    ///   - alpha: Целевой угол атаки
    ///   - reynolds: Целевое число Рейнольдса
    /// - Returns: Коэффициенты из данных ближайшего числа Рейнольдса
    private func interpolateForSingleReynolds(alpha: Double, reynolds: Double) -> (cl: Double, cd: Double, cm: Double) {
        let closestIndex = findClosestReynoldsIndex(reynolds)
        return interpolateForReynolds(at: closestIndex, alpha: alpha)
    }
    
    /// ## Найти ближайший индекс Рейнольдса
    /// Определяет ближайшее доступное число Рейнольдса, когда точное совпадение недоступно
    /// - Parameter reynolds: Целевое число Рейнольдса
    /// - Returns: Индекс ближайшего числа Рейнольдса в массиве данных
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
