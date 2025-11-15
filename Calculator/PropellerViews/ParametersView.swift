//
//  ParametersView.swift
//  Calculator
//
//  Created by Константин Савялов on 15.11.2025.
//

import SwiftUI

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
