//
//  BladeSectionsView.swift
//  Calculator
//
//  Created by Константин Савялов on 15.11.2025.
//

import SwiftUI

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
