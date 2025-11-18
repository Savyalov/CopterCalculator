//
//  AirfoilCalculator.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation

/// # Калькулятор коэффициентов аэродинамического профиля
/// Предоставляет услуги интерполяции и расчета аэродинамических коэффициентов профиля
/// Обрабатывает эффекты числа Рейнольдса и поправки на сжимаемость
public class AirfoilCalculator {
    
    // MARK: - Публичные методы
    
    /// ## Получить аэродинамические коэффициенты
    /// Получает интерполированные аэродинамические коэффициенты для указанных условий
    /// Выполняет билинейную интерполяцию по числу Рейнольдса и углу атаки
    /// - Parameters:
    ///   - airfoil: Данные профиля, содержащие таблицы коэффициентов
    ///   - alpha: Угол атаки в радианах
    ///   - reynolds: Число Рейнольдса на основе хорды и условий потока
    /// - Returns: Кортеж коэффициентов (cl, cd, cm)
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
    
    /// ## Применить поправку на сжимаемость
    /// Применяет поправку Прандтля-Глауэрта для эффектов сжимаемости при высоких числах Маха
    /// - Parameters:
    ///   - cl: Коэффициент подъемной силы для несжимаемой жидкости
    ///   - cd: Коэффициент сопротивления для несжимаемой жидкости
    ///   - mach: Число Маха потока
    /// - Returns: Коэффициенты (cl, cd) с поправкой на сжимаемость
    public static func applyCompressibilityCorrection(cl: Double, cd: Double, mach: Double) -> (cl: Double, cd: Double) {
        guard mach > 0.3 else { return (cl, cd) }
        
        let beta = sqrt(1 - mach * mach)
        return (cl / beta, cd / beta)
    }
    
    // MARK: - Приватные методы
    
    /// ## Найти индекс Рейнольдса
    /// Определяет соответствующий интервал числа Рейнольдса для интерполяции
    /// - Parameters:
    ///   - reynolds: Целевое число Рейнольдса
    ///   - reynoldsNumbers: Массив доступных чисел Рейнольдса
    /// - Returns: Нижний индекс интервала или nil, если вне диапазона
    private static func findReynoldsIndex(_ reynolds: Double, in reynoldsNumbers: [Double]) -> Int? {
        for i in 0..<reynoldsNumbers.count-1 {
            if reynolds >= reynoldsNumbers[i] && reynolds <= reynoldsNumbers[i+1] {
                return i
            }
        }
        return nil
    }
    
    /// ## Интерполяция для конкретного числа Рейнольдса
    /// Выполняет интерполяцию по углу атаки для фиксированного числа Рейнольдса
    /// - Parameters:
    ///   - airfoil: Данные профиля
    ///   - index: Индекс числа Рейнольдса
    ///   - alpha: Целевой угол атаки
    /// - Returns: Интерполированные коэффициенты (cl, cd, cm)
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
        return (0, 0.02, 0) // Значения по умолчанию, если вне диапазона
    }
    
    /// ## Интерполяция для одного числа Рейнольдса
    /// Резервный метод, когда число Рейнольдса находится вне доступного диапазона
    /// Использует данные ближайшего доступного числа Рейнольдса
    /// - Parameters:
    ///   - airfoil: Данные профиля
    ///   - alpha: Целевой угол атаки
    ///   - reynolds: Целевое число Рейнольдса
    /// - Returns: Коэффициенты из ближайшего числа Рейнольдса
    private static func interpolateForSingleReynolds(airfoil: AirfoilData, alpha: Double, reynolds: Double) -> (cl: Double, cd: Double, cm: Double) {
        let closestIndex = findClosestReynoldsIndex(reynolds, in: airfoil.reynoldsNumbers)
        return interpolateForReynolds(airfoil: airfoil, at: closestIndex, alpha: alpha)
    }
    
    /// ## Найти ближайший индекс Рейнольдса
    /// Определяет ближайшее доступное число Рейнольдса, когда точное совпадение недоступно
    /// - Parameters:
    ///   - reynolds: Целевое число Рейнольдса
    ///   - reynoldsNumbers: Массив доступных чисел Рейнольдса
    /// - Returns: Индекс ближайшего числа Рейнольдса
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
