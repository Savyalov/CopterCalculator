//
//  ContentView.swift
//  PropellerCalculator
//
//  Created by Константин Савялов on 14.11.2025.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Главное представление
struct ContentView: View {
    @StateObject private var propellerModel = PropellerModel()
    
    var body: some View {
        NavigationView {
            // Боковая панель с параметрами
            ScrollView {
                VStack(spacing: 16) {
                    ParametersView(model: propellerModel)
                    ProfileSelectionView(model: propellerModel)
                    ConfigurationView(model: propellerModel)
                }
                .padding()
            }
            .frame(minWidth: 400)
            
            // Основная область с результатами и графикой
            ResultsView(model: propellerModel)
        }
        .navigationTitle("Расчет воздушного винта")
        .frame(minWidth: 1200, minHeight: 800)
    }
}

// MARK: - Панель параметров
struct ParametersView: View {
    @ObservedObject var model: PropellerModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Параметры расчета")
                .font(.headline)
                .foregroundColor(.primary)
            
            Group {
                ParameterRow(title: "Тяга, кгс:", value: $model.thrust, defaultValue: "1.0")
                ParameterRow(title: "Скорость, м/с:", value: $model.velocity, defaultValue: "0.0")
                ParameterRow(title: "Диаметр, м:", value: $model.diameter, defaultValue: "0.2")
                ParameterRow(title: "Число лопастей:", value: $model.blades, defaultValue: "2")
                ParameterRow(title: "Обороты, об/мин:", value: $model.rpm, defaultValue: "10000")
                ParameterRow(title: "Плотность воздуха, кг/м³:", value: $model.density, defaultValue: "1.225")
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Методика расчета по статье:")
                    .font(.caption)
                Text("«Движитель - воздушный винт»")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("В.П. Кондратьев, «М-К» №12, 1988")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ParameterRow: View {
    let title: String
    @Binding var value: String
    let defaultValue: String
    
    var body: some View {
        HStack {
            Text(title)
                .frame(width: 180, alignment: .leading)
            Spacer()
            TextField("", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 100)
            
            Button("⟲") {
                value = defaultValue
            }
            .buttonStyle(BorderlessButtonStyle())
            .help("Восстановить значение по умолчанию")
            .font(.system(size: 14, weight: .bold))
        }
    }
}

/// MARK: - Выбор профиля (простая версия)
struct ProfileSelectionView: View {
    @ObservedObject var model: PropellerModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Профиль лопасти")
                .font(.headline)
                .foregroundColor(.primary)
            
            Picker("Профиль", selection: $model.selectedProfile) {
                ForEach(BladeProfile.database) { profile in
                    Text(profile.name).tag(profile)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .labelsHidden()
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Эффективность: \(model.selectedProfile.efficiencyRange.lowerBound * 100, specifier: "%.0f")-\(model.selectedProfile.efficiencyRange.upperBound * 100, specifier: "%.0f")%")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                HStack(alignment: .top) {
                    Image(systemName: "lightbulb")
                    Text("Рекомендации: \(model.selectedProfile.recommendedApplications.joined(separator: ", "))")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Управление конфигурациями
struct ConfigurationView: View {
    @ObservedObject var model: PropellerModel
    @State private var showingExportSheet = false
    @State private var exportData: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Управление конфигурациями")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Сохранение текущей конфигурации
            HStack {
                TextField("Название конфигурации", text: $model.currentConfigName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Сохранить") {
                    model.saveConfiguration()
                }
                .disabled(model.currentConfigName.isEmpty)
            }
            
            // Список сохраненных конфигураций
            if !model.savedConfigurations.isEmpty {
                VStack(alignment: .leading) {
                    Text("Сохраненные конфигурации:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    List {
                        ForEach(model.savedConfigurations) { config in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(config.name)
                                        .fontWeight(.medium)
                                    Text(config.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Загрузить") {
                                    model.loadConfiguration(config)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                
                                Button("Удалить") {
                                    model.deleteConfiguration(config)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .foregroundColor(.red)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .frame(height: 200)
                }
            } else {
                Text("Нет сохраненных конфигураций")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
            
            // Экспорт
            HStack {
                Button(action: {
                    exportData = model.exportToCSV()
                    showingExportSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Экспорт в CSV")
                    }
                }
                
                Spacer()
                
                Text("Версия 2.1")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .fileExporter(
            isPresented: $showingExportSheet,
            document: CSVDocument(text: exportData),
            contentType: UTType.commaSeparatedText,
            defaultFilename: "propeller_calculation_\(Date().formatted(date: .numeric, time: .shortened)).csv"
        ) { result in
            switch result {
            case .success:
                print("Экспорт успешен")
            case .failure(let error):
                print("Ошибка экспорта: \(error)")
            }
        }
    }
}

// MARK: - Представление результатов
struct ResultsView: View {
    @ObservedObject var model: PropellerModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Графическое представление с анимацией
                PropellerView(model: model)
                
                // Детальная информация о сечениях лопасти
                if !model.bladeSections.isEmpty {
                    BladeSectionsView(sections: model.bladeSections)
                }
                
                // Результаты расчета
                ResultsGridView(model: model)
                
                // Предупреждения
                WarningsView(model: model)
            }
            .padding()
        }
    }
}

// MARK: - Сетка результатов
struct ResultsGridView: View {
    @ObservedObject var model: PropellerModel
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ResultCard(title: "Мощность", value: model.power, unit: "Вт", specifier: "%.2f")
            ResultCard(title: "Крутящий момент", value: model.torque, unit: "Н·м", specifier: "%.4f")
            ResultCard(title: "КПД", value: model.efficiency * 100, unit: "%", specifier: "%.1f")
            ResultCard(title: "Шаг винта", value: model.pitch, unit: "м", specifier: "%.3f")
            ResultCard(title: "Окружная скорость", value: model.tipSpeed, unit: "м/с", specifier: "%.1f")
            ResultCard(title: "Число Маха", value: model.tipSpeedMach, unit: "", specifier: "%.3f")
        }
        .padding(.horizontal)
    }
}

// MARK: - Предупреждения
struct WarningsView: View {
    @ObservedObject var model: PropellerModel
    
    var body: some View {
        VStack(spacing: 8) {
            if model.tipSpeedMach > 0.7 {
                WarningView(message: "Внимание: Окружная скорость приближается к звуковой!")
            }
            
            if model.efficiency > 0.85 {
                WarningView(message: "Высокий КПД - проверьте корректность входных параметров", isWarning: false)
            }
            
            if model.power > 10000 {
                WarningView(message: "Высокая мощность - требуется проверка системы охлаждения")
            }
        }
    }
}

struct ResultCard: View {
    let title: String
    let value: Double
    let unit: String
    let specifier: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Text("\(value, specifier: specifier)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct WarningView: View {
    let message: String
    var isWarning: Bool = true
    
    var body: some View {
        HStack {
            Image(systemName: isWarning ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .foregroundColor(isWarning ? .orange : .blue)
            Text(message)
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .background(isWarning ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isWarning ? Color.orange : Color.blue, lineWidth: 1)
        )
    }
}

// MARK: - Визуализация винта
struct PropellerView: View {
    @ObservedObject var model: PropellerModel
    
    var body: some View {
        VStack {
            HStack {
                Text("Геометрия воздушного винта")
                    .font(.headline)
                
                Spacer()
                
                // Управление анимацией
                Button(action: {
                    model.toggleAnimation()
                }) {
                    HStack {
                        Image(systemName: model.isAnimating ? "stop.circle.fill" : "play.circle.fill")
                        Text(model.isAnimating ? "Стоп" : "Старт")
                    }
                    .foregroundColor(model.isAnimating ? .red : .green)
                }
                .buttonStyle(BorderedButtonStyle())
            }
            .padding(.bottom)
            
            ZStack {
                // Фон
                Rectangle()
                    .fill(Color.white)
                    .border(Color.gray)
                
                // Вращающийся винт
                PropellerShape(
                    points: model.bladePoints,
                    blades: Int(model.blades) ?? 2,
                    rotationAngle: model.rotationAngle
                )
                
                // Статичные элементы
                PropellerStaticElements(
                    diameter: Double(model.diameter) ?? 0.2,
                    bladeSections: model.bladeSections
                )
            }
            .frame(width: 400, height: 300)
            
            // Индикатор скорости
            SpeedIndicatorView(model: model)
        }
        .padding()
    }
}

// MARK: - Индикатор скорости
struct SpeedIndicatorView: View {
    @ObservedObject var model: PropellerModel
    
    var body: some View {
        if model.isAnimating {
            HStack {
                Image(systemName: "gauge")
                Text("\(model.rpm) об/мин")
                Text("•")
                Text("\(model.tipSpeed, specifier: "%.0f") м/с")
                Text("•")
                Text("Маха: \(model.tipSpeedMach, specifier: "%.2f")")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top, 8)
        }
    }
}

struct PropellerShape: View {
    let points: [CGPoint]
    let blades: Int
    let rotationAngle: Double
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ForEach(0..<blades, id: \.self) { bladeIndex in
                BladeShape(points: points)
                    .fill(bladeColor(for: bladeIndex))
                    .rotationEffect(.degrees(rotationAngle + Double(bladeIndex) * (360.0 / Double(blades))))
                    .position(center)
            }
        }
    }
    
    private func bladeColor(for index: Int) -> Color {
        let colors: [Color] = [.orange, .blue, .green, .purple, .red, .teal]
        return colors[index % colors.count].opacity(0.7)
    }
}

struct BladeShape: Shape {
    let points: [CGPoint]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard !points.isEmpty else { return path }
        
        let scale = min(rect.width, rect.height) * 0.8
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        
        if let firstPoint = points.first {
            let startX = center.x + firstPoint.x * scale
            let startY = center.y + firstPoint.y * scale
            path.move(to: CGPoint(x: startX, y: startY))
        }
        
        for point in points.dropFirst() {
            let x = center.x + point.x * scale
            let y = center.y + point.y * scale
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.closeSubpath()
        return path
    }
}

struct PropellerStaticElements: View {
    let diameter: Double
    let bladeSections: [PropellerModel.BladeSection]
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) * 0.4
            
            // Ось вращения
            Circle()
                .fill(Color.black)
                .frame(width: 12, height: 12)
                .position(center)
            
            // Окружность диаметра
            Circle()
                .stroke(Color.red, style: StrokeStyle(lineWidth: 1, dash: [5]))
                .frame(width: radius * 2, height: radius * 2)
                .position(center)
            
            // Секции лопасти для анализа
            ForEach(bladeSections.indices.prefix(3), id: \.self) { index in
                let section = bladeSections[index]
                let sectionRadius = (section.radius / (diameter / 2)) * radius
                
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    .frame(width: sectionRadius * 2, height: sectionRadius * 2)
                    .position(center)
            }
            
            // Подписи
            Text("D = \(diameter, specifier: "%.3f") м")
                .position(x: center.x + radius + 40, y: center.y)
                .font(.caption)
                .foregroundColor(.red)
        }
    }
}

// MARK: - Анализ сечений лопасти
struct BladeSectionsView: View {
    let sections: [PropellerModel.BladeSection]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Анализ сечений лопасти")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                Text("Радиус (м)").fontWeight(.medium)
                Text("Хорда (м)").fontWeight(.medium)
                Text("Угол (°)").fontWeight(.medium)
                Text("Cl").fontWeight(.medium)
                Text("Cd").fontWeight(.medium)
                
                ForEach(sections) { section in
                    Group {
                        Text("\(section.radius, specifier: "%.3f")")
                        Text("\(section.chord, specifier: "%.3f")")
                        Text("\(section.twist, specifier: "%.1f")")
                        Text("\(section.liftCoefficient, specifier: "%.3f")")
                        Text("\(section.dragCoefficient, specifier: "%.3f")")
                    }
                    .font(.system(.body, design: .monospaced))
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - Документ для экспорта CSV
struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    var text: String
    
    init(text: String) {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    ContentView()
}
