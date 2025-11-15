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

// MARK: - База данных профилей лопастей
struct BladeProfile: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var type: ProfileType
    var chordDistribution: [Double]
    var twistDistribution: [Double]
    var efficiencyRange: ClosedRange<Double>
    var recommendedApplications: [String]
    
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
            name: "Clark Y базовый",
            type: .clarkY,
            chordDistribution: [0.15, 0.13, 0.11, 0.09, 0.07, 0.05],
            twistDistribution: [45, 35, 25, 15, 8, 5],
            efficiencyRange: 0.65...0.78,
            recommendedApplications: ["Дроны", "Малые БПЛА"]
        ),
        BladeProfile(
            name: "NACA 0012 симметричный",
            type: .naca0012,
            chordDistribution: [0.12, 0.11, 0.10, 0.08, 0.06, 0.04],
            twistDistribution: [40, 30, 20, 12, 6, 3],
            efficiencyRange: 0.70...0.82,
            recommendedApplications: ["Акробатические дроны", "Вертолеты"]
        ),
        BladeProfile(
            name: "NACA 4412 несимметричный",
            type: .naca4412,
            chordDistribution: [0.14, 0.12, 0.10, 0.08, 0.06, 0.04],
            twistDistribution: [38, 28, 18, 10, 5, 2],
            efficiencyRange: 0.72...0.85,
            recommendedApplications: ["Тяговые винты", "Грузовые дроны"]
        ),
        BladeProfile(
            name: "Eppler 423 высокоэффективный",
            type: .eppler,
            chordDistribution: [0.13, 0.115, 0.095, 0.075, 0.055, 0.035],
            twistDistribution: [42, 32, 22, 13, 7, 4],
            efficiencyRange: 0.75...0.88,
            recommendedApplications: ["Спортивные дроны", "Гоночные БПЛА"]
        ),
        BladeProfile(
            name: "Плоская пластина",
            type: .flatPlate,
            chordDistribution: [0.16, 0.14, 0.12, 0.10, 0.08, 0.06],
            twistDistribution: [48, 38, 28, 18, 10, 6],
            efficiencyRange: 0.45...0.60,
            recommendedApplications: ["Учебные модели", "Прототипы"]
        )
    ]
    
    // Реализация Hashable через id
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: BladeProfile, rhs: BladeProfile) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Основная модель расчета
class PropellerModel: ObservableObject {
    
    // MARK: - Входные параметры
    @Published var thrust: String = "1.0" { didSet { calculate() } }
    @Published var diameter: String = "0.2" { didSet { calculate() } }
    @Published var velocity: String = "0.0" { didSet { calculate() } }
    @Published var rpm: String = "10000" { didSet { calculate() } }
    @Published var blades: String = "2" { didSet { calculate() } }
    @Published var density: String = "1.225" { didSet { calculate() } }
    @Published var selectedProfile: BladeProfile = BladeProfile.database[0] { didSet { calculate() } }
    
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
        // Комбинируем все параметры в группы
        let flightParams = Publishers.CombineLatest3($thrust, $velocity, $density)
        let geometryParams = Publishers.CombineLatest3($diameter, $blades, $rpm)
        let profileParam = $selectedProfile
        
        // Объединяем все группы
        Publishers.CombineLatest3(flightParams, geometryParams, profileParam)
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.calculate()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Основной расчет
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
        
        // Практический расчет для реалистичных результатов
        let (power, torque, efficiency, pitch) = calculatePractical(
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

    // MARK: - Практический расчет
    private func calculatePractical(thrust T: Double, diameter D: Double, velocity V: Double,
                                  rpm N: Double, blades B: Int, density ρ: Double) -> (Double, Double, Double, Double) {
        let R = D / 2.0
        let ω = (2.0 * Double.pi * N) / 60.0
        let A = Double.pi * R * R
        
        // Мощность на основе практических данных
        let power = T * 800 + V * 50 // Практическая формула
        
        let torque = power / ω
        let pitch = (V + 0.7 * sqrt(T / (2.0 * ρ * A))) / (N / 60.0)
        
        // КПД на основе профиля и условий
        let baseEfficiency = selectedProfile.efficiencyRange.lowerBound + 0.2
        let speedFactor = min(V / 20.0, 1.0)
        let efficiency = baseEfficiency + speedFactor * 0.3
        
        return (power, torque, min(efficiency, 0.85), pitch)
    }
    
    // MARK: - Практический расчет для дронов
    private func calculateAerodynamics(thrust T: Double, diameter D: Double, velocity V: Double,
                                    rpm N: Double, blades B: Int, density ρ: Double) -> (Double, Double, Double, Double) {
        let R = D / 2.0
        let ω = (2.0 * Double.pi * N) / 60.0
        let A = Double.pi * R * R
        
        // Практические коэффициенты для дронов
        let powerLoading = 0.15 // Вт/г для типичного дрона
        let power = T * 1000 * powerLoading // Переводим кгс в граммы
        
        let torque = power / ω
        let pitch = (V + 0.7 * sqrt(T / (2.0 * ρ * A))) / (N / 60.0)
        
        // КПД рассчитываем на основе профиля и условий
        var efficiency: Double
        
        if V == 0 {
            // Статический КПД (взлет)
            efficiency = selectedProfile.efficiencyRange.lowerBound + 0.1
        } else if V < 10 {
            // Низкая скорость
            efficiency = selectedProfile.efficiencyRange.lowerBound + 0.2
        } else {
            // Крейсерская скорость
            efficiency = selectedProfile.efficiencyRange.upperBound - 0.1
        }
        
        // Корректируем КПД в зависимости от числа лопастей
        let bladeFactor = Double(B) / 2.0
        efficiency *= (1.0 - (bladeFactor - 1.0) * 0.05)
        
        return (power, torque, efficiency, pitch)
    }
    
    private func calculateProfileCoefficients(profile: BladeProfile, radiusRatio: Double,
                                           advanceRatio: Double, Reynolds: Double) -> (Cl: Double, Cd: Double) {
        let reFactor = min(Reynolds / 1e5, 2.0)
        
        switch profile.type {
        case .flatPlate:
            return (1.2 * reFactor, 0.1)
        case .clarkY:
            return (1.4 - radiusRatio * 0.4, 0.08 - radiusRatio * 0.03)
        case .naca0012:
            return (1.3 - radiusRatio * 0.3, 0.06 - radiusRatio * 0.02)
        case .naca4412:
            return (1.5 - radiusRatio * 0.5, 0.07 - radiusRatio * 0.025)
        case .eppler:
            return (1.6 - radiusRatio * 0.6, 0.05 - radiusRatio * 0.015)
        case .custom:
            return (1.4 - radiusRatio * 0.4, 0.08 - radiusRatio * 0.03)
        }
    }
    
    // MARK: - Анимация
    func toggleAnimation() {
            isAnimating.toggle()
            
            if isAnimating {
                startContinuousAnimation()
            } else {
                stopAnimation()
            }
        }
        
        private func startContinuousAnimation() {
            let rpmValue = Double(rpm) ?? 10000
            let duration = 60.0 / rpmValue // Время одного оборота в секундах
            
            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
        
        private func stopAnimation() {
            withAnimation(.easeOut) {
                rotationAngle = 0
            }
        }
    
    private func updateAnimationSpeed(rpm: Double) {
        animationTimer?.invalidate()
        
        guard isAnimating else { return }
        
        let rotationPerSecond = rpm / 60.0
        let timeInterval = 0.016 // ~60 FPS
        let angleIncrement = rotationPerSecond * 360.0 * timeInterval
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.rotationAngle += angleIncrement
                if self?.rotationAngle ?? 0 >= 360 {
                    self?.rotationAngle = 0
                }
            }
        }
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
    }
}
