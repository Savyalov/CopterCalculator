//
//  PropellerShape.swift
//  Calculator
//
//  Created by Константин Савялов on 15.11.2025.
//

import SwiftUI

struct PropellerShape: View {
    let points: [CGPoint]
    let blades: Int
    let rotationAngle: Double
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ForEach(0..<blades, id: \.self) { bladeIndex in
                BladeShape(points: points)
                    .fill(bladeColor(for: bladeIndex))
                    .rotationEffect(.degrees(rotationAngle + Double(bladeIndex) * (360.0 / Double(blades))))
                    .position(center)
            }
        }
    }
    
    private func bladeColor(for index: Int) -> Color {
        let colors: [Color] = [.orange, .blue, .green, .purple, .red, .teal]
        return colors[index % colors.count].opacity(0.7)
    }
}
