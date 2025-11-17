//
//  Models.swift
//  PropellerCalculator
//
//  Created by Константин Савялов on 14.11.2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Модели данных для сохранения
struct PropellerConfiguration: Codable, Identifiable {
    let id: UUID
    var name: String
    let date: Date
    var parameters: Parameters
    var results: Results?
    
    struct Parameters: Codable {
        var thrust: Double
        var diameter: Double
        var velocity: Double
        var rpm: Double
        var blades: Int
        var density: Double
        var profileType: BladeProfile.ProfileType
    }
    
    struct Results: Codable {
        var power: Double
        var torque: Double
        var efficiency: Double
        var pitch: Double
        var tipSpeed: Double
        var tipSpeedMach: Double
    }
}

/// MARK: - База данных профилей лопастей с реальными параметрами
struct BladeProfile: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var type: ProfileType
    var chordDistribution: [Double]  // в метрах, абсолютные значения
    var twistDistribution: [Double]  // в градусах
    var thicknessDistribution: [Double] // толщина профиля в % хорды
    var efficiencyRange: ClosedRange<Double>
    var recommendedApplications: [String]
    var materialThickness: Double // толщина материала в мм
    var rootChord: Double { chordDistribution.first ?? 0 }
    var tipChord: Double { chordDistribution.last ?? 0 }
    
    enum ProfileType: String, CaseIterable, Codable, Hashable {
        case flatPlate = "Плоская пластина"
        case clarkY = "Clark Y"
        case naca0012 = "NACA 0012"
        case naca4412 = "NACA 4412"
        case eppler = "Eppler 423"
        case custom = "Пользовательский"
    }
    
    static let database: [BladeProfile] = [
        BladeProfile(
            name: "Clark Y для дрона 10\"",
            type: .clarkY,
            chordDistribution: [0.035, 0.032, 0.029, 0.026, 0.023, 0.020], // в метрах
            twistDistribution: [28.0, 22.0, 16.0, 11.0, 7.0, 4.0], // в градусах
            thicknessDistribution: [11.7, 10.8, 9.8, 8.7, 7.6, 6.5], // % хорды
            efficiencyRange: 0.68...0.82,
            recommendedApplications: ["Квадрокоптеры 8-12\"", "ФПВ дроны"],
            materialThickness: 1.5 // мм
        ),
        BladeProfile(
            name: "NACA 0012 для гоночного дрона",
            type: .naca0012,
            chordDistribution: [0.030, 0.028, 0.025, 0.022, 0.019, 0.016],
            twistDistribution: [32.0, 25.0, 18.0, 12.0, 8.0, 5.0],
            thicknessDistribution: [12.0, 11.2, 10.3, 9.2, 8.0, 6.8],
            efficiencyRange: 0.65...0.78,
            recommendedApplications: ["Гоночные дроны 5-7\"", "Акробатика"],
            materialThickness: 1.2
        ),
        BladeProfile(
            name: "NACA 4412 для грузового дрона",
            type: .naca4412,
            chordDistribution: [0.045, 0.041, 0.037, 0.033, 0.029, 0.025],
            twistDistribution: [25.0, 19.0, 14.0, 10.0, 6.0, 3.0],
            thicknessDistribution: [12.0, 11.0, 10.0, 9.0, 8.0, 7.0],
            efficiencyRange: 0.72...0.85,
            recommendedApplications: ["Грузовые дроны", "Кинодроны"],
            materialThickness: 2.0
        ),
        BladeProfile(
            name: "Eppler 423 для марафонского дрона",
            type: .eppler,
            chordDistribution: [0.032, 0.030, 0.027, 0.024, 0.021, 0.018],
            twistDistribution: [26.0, 20.0, 15.0, 10.0, 6.0, 3.0],
            thicknessDistribution: [10.5, 9.8, 9.0, 8.1, 7.1, 6.0],
            efficiencyRange: 0.75...0.88,
            recommendedApplications: ["Марафонские дроны", "Долгий полет"],
            materialThickness: 1.0
        ),
        BladeProfile(
            name: "Плоская пластина для прототипа",
            type: .flatPlate,
            chordDistribution: [0.040, 0.037, 0.034, 0.031, 0.028, 0.025],
            twistDistribution: [35.0, 28.0, 21.0, 15.0, 10.0, 6.0],
            thicknessDistribution: [5.0, 5.0, 5.0, 5.0, 5.0, 5.0],
            efficiencyRange: 0.45...0.60,
            recommendedApplications: ["Прототипы", "Обучение"],
            materialThickness: 3.0
        )
    ]
}

// MARK: - Основная модель расчета
class PropellerModel: ObservableObject {
    
    // MARK: - Входные параметры
    @Published var thrust: String = "1.0"
    @Published var diameter: String = "0.2"
    @Published var velocity: String = "0.0"
    @Published var rpm: String = "10000"
    @Published var blades: String = "2"
    @Published var density: String = "1.225"
    @Published var selectedProfile: BladeProfile = BladeProfile.database[0]
    
    // MARK: - Расчетные параметры
    @Published var power: Double = 0.0
    @Published var torque: Double = 0.0
    @Published var efficiency: Double = 0.0
    @Published var pitch: Double = 0.0
    @Published var tipSpeed: Double = 0.0
    @Published var tipSpeedMach: Double = 0.0
    
    // MARK: - Анимация
    @Published var rotationAngle: Double = 0.0
    @Published var isAnimating: Bool = false
    
    // MARK: - Геометрия лопасти
    @Published var bladePoints: [CGPoint] = []
    @Published var bladeSections: [BladeSection] = []
    
    // MARK: - Конфигурации
    @Published var savedConfigurations: [PropellerConfiguration] = []
    @Published var currentConfigName: String = "Новая конфигурация"
    
    struct BladeSection: Identifiable {
        let id = UUID()
        let radius: Double
        let chord: Double
        let twist: Double
        let liftCoefficient: Double
        let dragCoefficient: Double
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var animationTimer: Timer?
    
    init() {
        loadConfigurations()
        setupSubscriptions()
        calculate()
    }
    
    deinit {
        animationTimer?.invalidate()
    }
    
    // MARK: - Настройка подписок
    private func setupSubscriptions() {
        // Комбинируем параметры группами
        let group1 = Publishers.CombineLatest3($thrust, $diameter, $velocity)
        let group2 = Publishers.CombineLatest3($rpm, $blades, $density)
        
        Publishers.CombineLatest3(group1, group2, $selectedProfile)
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] (params1, params2, profile) in
                self?.calculate()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Основной расчет
    func calculate() {
        guard let T = Double(thrust),
              let D = Double(diameter),
              let V = Double(velocity),
              let N = Double(rpm),
              let B = Double(blades),
              let ρ = Double(density),
              T > 0, D > 0, N > 0, B > 0, ρ > 0 else {
            resetResults()
            return
        }
        
        let R = D / 2.0
        let ω = (2.0 * Double.pi * N) / 60.0
        
        // Расчет по улучшенной методике
        let (power, torque, efficiency, pitch) = calculateImprovedAerodynamics(
            thrust: T, diameter: D, velocity: V, rpm: N, blades: Int(B), density: ρ
        )
        
        self.power = power
        self.torque = torque
        self.efficiency = efficiency
        self.pitch = pitch
        self.tipSpeed = ω * R
        self.tipSpeedMach = tipSpeed / 340.0
        
        generateBladeGeometry(radius: R, profile: selectedProfile)
        updateAnimationSpeed(rpm: N)
    }
    
    // MARK: - Улучшенный аэродинамический расчет
    private func calculateImprovedAerodynamics(thrust T: Double, diameter D: Double, velocity V: Double,
                                             rpm N: Double, blades B: Int, density ρ: Double) -> (Double, Double, Double, Double) {
        let ω = (2.0 * Double.pi * N) / 60.0
        
        // Улучшенный расчет мощности
        let power = calculateOptimizedPower(thrust: T, diameter: D, velocity: V, rpm: N, density: ρ)
        let torque = power / ω
        
        // Расчет шага винта
        let pitch = calculateOptimizedPitch(thrust: T, diameter: D, velocity: V, rpm: N, density: ρ)
        
        // Расчет КПД с учетом профиля
        let efficiency = calculateOptimizedEfficiency(thrust: T, velocity: V, power: power, profile: selectedProfile)
        
        return (power, torque, efficiency, pitch)
    }
    
    private func calculateOptimizedPower(thrust T: Double, diameter D: Double, velocity V: Double,
                                       rpm N: Double, density ρ: Double) -> Double {
        let R = D / 2.0
        let ω = (2.0 * Double.pi * N) / 60.0
        let tipSpeed = ω * R
        
        if V == 0 {
            // Статический режим (взлет)
            let idealPower = T * sqrt(T / (2.0 * ρ * Double.pi * R * R))
            let figureOfMerit = selectedProfile.efficiencyRange.upperBound * 0.9
            return idealPower / figureOfMerit
        } else {
            // Динамический режим
            let advanceRatio = V / tipSpeed
            let profileEfficiency = selectedProfile.efficiencyRange.lowerBound + (selectedProfile.efficiencyRange.upperBound - selectedProfile.efficiencyRange.lowerBound) * (1.0 - advanceRatio)
            return (T * V) / profileEfficiency
        }
    }
    
    private func calculateOptimizedPitch(thrust T: Double, diameter D: Double, velocity V: Double,
                                       rpm N: Double, density ρ: Double) -> Double {
        let R = D / 2.0
        let A = Double.pi * R * R
        
        let inducedVelocity = 0.7 * sqrt(T / (2.0 * ρ * A))
        let pitch = (V + inducedVelocity) / (N / 60.0)
        
        // Ограничиваем шаг разумными пределами
        return min(max(pitch, D * 0.3), D * 1.5)
    }
    
    private func calculateOptimizedEfficiency(thrust T: Double, velocity V: Double, power: Double, profile: BladeProfile) -> Double {
        var efficiency: Double
        
        if V > 0 {
            efficiency = (T * V) / max(power, 1e-10)
        } else {
            // При нулевой скорости используем характеристику профиля
            efficiency = profile.efficiencyRange.lowerBound + 0.15
        }
        
        // Ограничиваем КПД разумными пределами
        return min(max(efficiency, 0.1), profile.efficiencyRange.upperBound)
    }
    
    // MARK: - Анимация
    func toggleAnimation() {
        isAnimating.toggle()
        
        if isAnimating {
            let rpmValue = Double(rpm) ?? 10000
            startAnimation(rpm: rpmValue)
        } else {
            stopAnimation()
        }
    }
    
    private func startAnimation(rpm: Double) {
        stopAnimation()
        
        let rotationPerSecond = rpm / 60.0
        let timeInterval = 0.016
        let angleIncrement = rotationPerSecond * 360.0 * timeInterval
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.rotationAngle += angleIncrement
                if self.rotationAngle >= 360 {
                    self.rotationAngle -= 360
                }
                self.objectWillChange.send()
            }
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    // MARK: - Экспорт в CSV
    func exportToCSV() -> String {
        var csv = "Параметр;Значение;Единицы измерения\n"
        csv += "Тяга;\(thrust);кгс\n"
        csv += "Диаметр;\(diameter);м\n"
        csv += "Скорость;\(velocity);м/с\n"
        csv += "Обороты;\(rpm);об/мин\n"
        csv += "Лопасти;\(blades);шт\n"
        csv += "Плотность;\(density);кг/м³\n"
        csv += "Профиль;\(selectedProfile.name);-\n"
        csv += "\nРезультаты расчета:\n"
        csv += "Мощность;\(String(format: "%.2f", power));Вт\n"
        csv += "Крутящий момент;\(String(format: "%.4f", torque));Н·м\n"
        csv += "КПД;\(String(format: "%.1f", efficiency * 100));%\n"
        csv += "Шаг винта;\(String(format: "%.3f", pitch));м\n"
        csv += "Окружная скорость;\(String(format: "%.1f", tipSpeed));м/с\n"
        csv += "Число Маха;\(String(format: "%.3f", tipSpeedMach));-\n"
        
        if !bladeSections.isEmpty {
            csv += "\nСечения лопасти:\n"
            csv += "Радиус;Хорда;Угол установки;Coef подъемной;Coef сопротивления\n"
            for section in bladeSections {
                csv += "\(String(format: "%.3f", section.radius));\(String(format: "%.3f", section.chord));\(String(format: "%.1f", section.twist));\(String(format: "%.3f", section.liftCoefficient));\(String(format: "%.3f", section.dragCoefficient))\n"
            }
        }
        
        return csv
    }
    
    // MARK: - Сохранение/загрузка конфигураций
    func saveConfiguration() {
        guard let thrustVal = Double(thrust),
              let diameterVal = Double(diameter),
              let velocityVal = Double(velocity),
              let rpmVal = Double(rpm),
              let bladesVal = Int(blades),
              let densityVal = Double(density) else { return }
        
        let parameters = PropellerConfiguration.Parameters(
            thrust: thrustVal,
            diameter: diameterVal,
            velocity: velocityVal,
            rpm: rpmVal,
            blades: bladesVal,
            density: densityVal,
            profileType: selectedProfile.type
        )
        
        let results = PropellerConfiguration.Results(
            power: power,
            torque: torque,
            efficiency: efficiency,
            pitch: pitch,
            tipSpeed: tipSpeed,
            tipSpeedMach: tipSpeedMach
        )
        
        let config = PropellerConfiguration(
            id: UUID(),
            name: currentConfigName,
            date: Date(),
            parameters: parameters,
            results: results
        )
        
        savedConfigurations.append(config)
        saveConfigurations()
    }
    
    func loadConfiguration(_ config: PropellerConfiguration) {
        thrust = String(config.parameters.thrust)
        diameter = String(config.parameters.diameter)
        velocity = String(config.parameters.velocity)
        rpm = String(config.parameters.rpm)
        blades = String(config.parameters.blades)
        density = String(config.parameters.density)
        
        if let profile = BladeProfile.database.first(where: { $0.type == config.parameters.profileType }) {
            selectedProfile = profile
        }
        
        currentConfigName = config.name
        calculate()
    }
    
    func deleteConfiguration(_ config: PropellerConfiguration) {
        savedConfigurations.removeAll { $0.id == config.id }
        saveConfigurations()
    }
    
    private func saveConfigurations() {
        if let encoded = try? JSONEncoder().encode(savedConfigurations) {
            UserDefaults.standard.set(encoded, forKey: "savedConfigurations")
        }
    }
    
    private func loadConfigurations() {
        if let data = UserDefaults.standard.data(forKey: "savedConfigurations"),
           let decoded = try? JSONDecoder().decode([PropellerConfiguration].self, from: data) {
            savedConfigurations = decoded
        }
    }
    
    // MARK: - Вспомогательные методы
    private func resetResults() {
        power = 0.0
        torque = 0.0
        efficiency = 0.0
        pitch = 0.0
        tipSpeed = 0.0
        tipSpeedMach = 0.0
        bladePoints = []
        bladeSections = []
    }
    
    private func updateAnimationSpeed(rpm: Double) {
        if isAnimating {
            stopAnimation()
            startAnimation(rpm: rpm)
        }
    }
    
    private func generateBladeGeometry(radius: Double, profile: BladeProfile) {
        var points: [CGPoint] = []
        let steps = profile.chordDistribution.count
        
        for i in 0..<steps {
            let r = Double(i) / Double(steps) * radius
            let chord = profile.chordDistribution[i] * radius
            
            let x = r / radius
            let y = chord / (2.0 * radius)
            
            points.append(CGPoint(x: x, y: y))
        }
        
        for i in (0..<steps).reversed() {
            let r = Double(i) / Double(steps) * radius
            let chord = profile.chordDistribution[i] * radius
            
            let x = r / radius
            let y = -chord / (2.0 * radius)
            
            points.append(CGPoint(x: x, y: y))
        }
        
        bladePoints = points
        
        // Генерируем сечения для отображения
        bladeSections = (0..<min(6, steps)).map { i in
            let r = Double(i) / Double(steps) * radius
            let chord = profile.chordDistribution[i] * radius
            let twist = profile.twistDistribution[i]
            
            return BladeSection(
                radius: r,
                chord: chord,
                twist: twist,
                liftCoefficient: 1.3 - Double(i) * 0.15,
                dragCoefficient: 0.06 - Double(i) * 0.008
            )
        }
    }
}
