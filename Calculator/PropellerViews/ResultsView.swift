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
    
    private var bladeLength: Double {
        (Double(model.diameter) ?? 0.2) / 2.0
    }
    
    private var averageChord: Double {
        guard let profile = BladeProfile.database.first(where: { $0.id == model.selectedProfile.id }) else {
            return 0.1
        }
        return (profile.chordDistribution.reduce(0, +) / Double(profile.chordDistribution.count)) * bladeLength
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Три новых изображения лопасти
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    BladeProfileView(
                        profile: model.selectedProfile,
                        chordLength: averageChord, sectionIndex: 0
                    )
                    
                    BladeTopView(
                        profile: model.selectedProfile,
                        bladeLength: bladeLength
                    )
                    
                    Blade3DView(
                        profile: model.selectedProfile,
                        bladeLength: bladeLength,
                        twistDistribution: model.selectedProfile.twistDistribution
                    )
                }
                .padding(.horizontal)
                
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
