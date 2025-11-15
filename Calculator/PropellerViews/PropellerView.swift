//
//  PropellerView.swift
//  Calculator
//
//  Created by Константин Савялов on 15.11.2025.
//

import SwiftUI

// MARK: - Визуализация винта
struct PropellerView: View {
    @ObservedObject var model: PropellerModel
    
    var body: some View {
        VStack {
            HStack {
                Text("Геометрия воздушного винта")
                    .font(.headline)
                
                Spacer()
                
                // Управление анимацией
                Button(action: {
                    model.toggleAnimation()
                }) {
                    HStack {
                        Image(systemName: model.isAnimating ? "stop.circle.fill" : "play.circle.fill")
                        Text(model.isAnimating ? "Стоп" : "Старт")
                    }
                    .foregroundColor(model.isAnimating ? .red : .green)
                }
                .buttonStyle(BorderedButtonStyle())
            }
            .padding(.bottom)
            
            ZStack {
                // Фон
                Rectangle()
                    .fill(Color.white)
                    .border(Color.gray)
                
                // Вращающийся винт
                PropellerShape(
                    points: model.bladePoints,
                    blades: Int(model.blades) ?? 2,
                    rotationAngle: model.rotationAngle
                )
                
                // Статичные элементы
                PropellerStaticElements(
                    diameter: Double(model.diameter) ?? 0.2,
                    bladeSections: model.bladeSections
                )
            }
            .frame(width: 400, height: 300)
            
            // Индикатор скорости
            SpeedIndicatorView(model: model)
        }
        .padding()
    }
}
