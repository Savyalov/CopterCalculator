//
//  ResultsView.swift
//  Calculator
//
//  Created by Константин Савялов on 15.11.2025.
//

import SwiftUI

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
