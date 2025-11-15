//
//  ConfigurationView.swift
//  Calculator
//
//  Created by Константин Савялов on 15.11.2025.
//

import SwiftUI
import UniformTypeIdentifiers

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
