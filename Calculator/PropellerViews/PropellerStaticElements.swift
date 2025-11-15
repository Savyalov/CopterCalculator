//
//  PropellerStaticElements.swift
//  Calculator
//
//  Created by Константин Савялов on 15.11.2025.
//

import SwiftUI

struct PropellerStaticElements: View {
    let diameter: Double
    let bladeSections: [PropellerModel.BladeSection]
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) * 0.4
            
            // Ось вращения
            Circle()
                .fill(Color.black)
                .frame(width: 12, height: 12)
                .position(center)
            
            // Окружность диаметра
            Circle()
                .stroke(Color.red, style: StrokeStyle(lineWidth: 1, dash: [5]))
                .frame(width: radius * 2, height: radius * 2)
                .position(center)
            
            // Секции лопасти для анализа
            ForEach(bladeSections.indices.prefix(3), id: \.self) { index in
                let section = bladeSections[index]
                let sectionRadius = (section.radius / (diameter / 2)) * radius
                
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    .frame(width: sectionRadius * 2, height: sectionRadius * 2)
                    .position(center)
            }
            
            // Подписи
            Text("D = \(diameter, specifier: "%.3f") м")
                .position(x: center.x + radius + 40, y: center.y)
                .font(.caption)
                .foregroundColor(.red)
        }
    }
}
