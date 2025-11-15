//
//  ContentView.swift
//  PropellerCalculator
//
//  Created by Константин Савялов on 14.11.2025.
//

import SwiftUI

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

#Preview {
    ContentView()
}
