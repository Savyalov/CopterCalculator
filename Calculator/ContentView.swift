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
        .navigationTitle("Конструктор лопасти")
        .frame(minWidth: 1200, minHeight: 800)
    }
}

#Preview {
    ContentView()
}
