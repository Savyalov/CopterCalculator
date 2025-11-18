//
//  SettingsView.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import SwiftUI

/// # Settings View
/// Application settings and configuration
/// Allows user to customize export formats, calculation behavior, and rendering quality
public struct SettingsView: View {
    
    // MARK: - App Storage Properties
    
    /// ## Default Export Format
    /// User preference for default 3D export format
    /// Persists between application launches
    @AppStorage("defaultExportFormat") private var defaultExportFormat = "STL"
    
    /// ## Auto Recalculate Setting
    /// Whether to automatically recalculate when parameters change
    /// Improves workflow efficiency for iterative design
    @AppStorage("autoRecalculate") private var autoRecalculate = true
    
    /// ## High Quality Render Setting
    /// Whether to use high-quality rendering for 3D views
    /// Balance between visual quality and performance
    @AppStorage("highQualityRender") private var highQualityRender = true
    
    // MARK: - Body Implementation
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Settings header
                Text("Настройки")
                    .font(.largeTitle)
                    .padding(.bottom, 10)
                
                // Export settings group
                SettingsGroupView(title: "Экспорт") {
                    SettingsRow(
                        title: "Формат по умолчанию",
                        description: "Выберите предпочитаемый формат для экспорта 3D моделей"
                    ) {
                        Picker("", selection: $defaultExportFormat) {
                            Text("STL").tag("STL")
                            Text("OBJ").tag("OBJ")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 150)
                    }
                }
                
                // Calculation settings group
                SettingsGroupView(title: "Расчет") {
                    SettingsRow(
                        title: "Автоматический пересчет",
                        description: "Автоматически пересчитывать при изменении параметров"
                    ) {
                        Toggle("", isOn: $autoRecalculate)
                    }
                }
                
                // Visualization settings group
                SettingsGroupView(title: "Визуализация") {
                    SettingsRow(
                        title: "Высокое качество рендера",
                        description: "Использовать более детализированные модели для 3D отображения"
                    ) {
                        Toggle("", isOn: $highQualityRender)
                    }
                }
            }
            .padding()
        }
        .background(VisualEffectView(material: .contentBackground, blendingMode: .behindWindow))
    }
}

/// # Settings Group Container
/// Logical grouping of related settings with title and styling
public struct SettingsGroupView<Content: View>: View {
    
    // MARK: - Properties
    
    /// ## Group Title
    /// Descriptive title for the settings group
    public let title: String
    
    /// ## Group Content
    /// Child views containing setting rows
    public let content: Content
    
    // MARK: - Initialization
    
    /// ## Settings Group Initializer
    /// Creates a new settings group with title and content
    /// - Parameters:
    ///   - title: Group title string
    ///   - content: View builder for setting rows
    public init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    // MARK: - Body Implementation
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
        }
        .padding()
        .background(VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

/// # Settings Row
/// Individual setting with title, description, and control
public struct SettingsRow<Content: View>: View {
    
    // MARK: - Properties
    
    /// ## Setting Title
    /// Primary name of the setting
    public let title: String
    
    /// ## Setting Description
    /// Detailed explanation of the setting's purpose
    public let description: String
    
    /// ## Control Content
    /// Interactive control for the setting (toggle, picker, etc.)
    public let control: Content
    
    // MARK: - Initialization
    
    /// ## Settings Row Initializer
    /// Creates a new settings row with title, description, and control
    /// - Parameters:
    ///   - title: Setting title
    ///   - description: Setting description
    ///   - control: View builder for the control
    public init(title: String, description: String, @ViewBuilder control: () -> Content) {
        self.title = title
        self.description = description
        self.control = control()
    }
    
    // MARK: - Body Implementation
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            control
        }
    }
}

// MARK: - Preview Provider

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
