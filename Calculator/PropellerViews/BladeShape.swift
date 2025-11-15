//
//  BladeShape.swift
//  Calculator
//
//  Created by Константин Савялов on 15.11.2025.
//

import SwiftUI

struct BladeShape: Shape {
    let points: [CGPoint]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard !points.isEmpty else { return path }
        
        let scale = min(rect.width, rect.height) * 0.8
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        
        if let firstPoint = points.first {
            let startX = center.x + firstPoint.x * scale
            let startY = center.y + firstPoint.y * scale
            path.move(to: CGPoint(x: startX, y: startY))
        }
        
        for point in points.dropFirst() {
            let x = center.x + point.x * scale
            let y = center.y + point.y * scale
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.closeSubpath()
        return path
    }
}
