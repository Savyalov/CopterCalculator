//
//  ResultsGridView.swift
//  Calculator
//
//  Created by Константин Савялов on 15.11.2025.
//

import SwiftUI

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
