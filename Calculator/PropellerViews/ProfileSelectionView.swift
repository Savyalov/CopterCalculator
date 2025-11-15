//
//  ProfileSelectionView.swift
//  Calculator
//
//  Created by Константин Савялов on 15.11.2025.
//

import SwiftUI

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
