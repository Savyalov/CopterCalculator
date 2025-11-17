//
//  Blade3DView.swift
//  Calculator
//
//  Created by Константин Савялов on 15.11.2025.
//

import SwiftUI

import SwiftUI

struct Blade3DView: View {
    let profile: BladeProfile
    let bladeLength: Double
    let twistDistribution: [Double]
    
    var body: some View {
        VStack {
            Text("3D модель лопасти")
                .font(.headline)
                .padding(.bottom, 8)
            
            ZStack {
                // Фон с перспективой
                Rectangle()
                    .fill(backgroundGradient)
                    .border(Color.gray)
                
                // 3D лопасть
                Blade3DShape(
                    profile: profile,
                    length: bladeLength,
                    twists: twistDistribution
                )
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 2, y: 2)
                
                // Освещение и эффекты
                Blade3DEffects()
            }
            .frame(height: 250)
            
            Text("Объемная визуализация")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
    }
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.gray.opacity(0.1),
                Color.gray.opacity(0.05),
                Color.gray.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct Blade3DShape: View {
    let profile: BladeProfile
    let length: Double
    let twists: [Double]
    
    var body: some View {
        ZStack {
            // Основная лопасть с перспективой
            ForEach(0..<5) { layer in
                BladeLayerShape(
                    profile: profile,
                    length: length,
                    twists: twists,
                    layerIndex: layer,
                    totalLayers: 5
                )
                .fill(layerGradient(for: layer))
                .offset(z: CGFloat(layer) * 2)
                .opacity(1.0 - Double(layer) * 0.15)
            }
            
            // Кромки и выделения
            BladeEdgesShape(profile: profile, length: length, twists: twists)
        }
    }
    
    private func layerGradient(for layer: Int) -> LinearGradient {
        let opacity = 0.8 - Double(layer) * 0.15
        return LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(opacity),
                Color.teal.opacity(opacity * 0.8),
                Color.green.opacity(opacity * 0.6)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct BladeLayerShape: Shape {
    let profile: BladeProfile
    let length: Double
    let twists: [Double]
    let layerIndex: Int
    let totalLayers: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let steps = profile.chordDistribution.count
        let widthScale = rect.width / length
        let depthOffset = Double(layerIndex) * 0.1
        
        // Правая сторона лопасти (от корня к концу)
        for i in 0..<steps {
            let r = Double(i) / Double(steps) * length
            let chord = profile.chordDistribution[i] * length
            let twist = twists[i] * .pi / 180.0 // Преобразуем в радианы
            
            let baseX = r * widthScale
            let baseY = chord * rect.height * 0.4
            
            // Применяем крутку
            let twistedX = baseX * cos(twist) - baseY * sin(twist) * depthOffset
            let twistedY = baseX * sin(twist) + baseY * cos(twist)
            
            if i == 0 {
                path.move(to: CGPoint(x: twistedX, y: rect.midY + twistedY))
            } else {
                path.addLine(to: CGPoint(x: twistedX, y: rect.midY + twistedY))
            }
        }
        
        // Левая сторона лопасти (от конца к корню)
        for i in (0..<steps).reversed() {
            let r = Double(i) / Double(steps) * length
            let chord = profile.chordDistribution[i] * length
            let twist = twists[i] * .pi / 180.0
            
            let baseX = r * widthScale
            let baseY = chord * rect.height * 0.4
            
            let twistedX = baseX * cos(twist) - (-baseY) * sin(twist) * depthOffset
            let twistedY = baseX * sin(twist) + (-baseY) * cos(twist)
            
            path.addLine(to: CGPoint(x: twistedX, y: rect.midY + twistedY))
        }
        
        path.closeSubpath()
        return path
    }
}

struct BladeEdgesShape: View {
    let profile: BladeProfile
    let length: Double
    let twists: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Передняя кромка
                BladeEdgeShape(
                    profile: profile,
                    length: length,
                    twists: twists,
                    isLeadingEdge: true
                )
                .stroke(Color.white, lineWidth: 2)
                
                // Задняя кромка
                BladeEdgeShape(
                    profile: profile,
                    length: length,
                    twists: twists,
                    isLeadingEdge: false
                )
                .stroke(Color.white, lineWidth: 2)
            }
        }
    }
}

struct BladeEdgeShape: Shape {
    let profile: BladeProfile
    let length: Double
    let twists: [Double]
    let isLeadingEdge: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let steps = profile.chordDistribution.count
        let widthScale = rect.width / length
        
        for i in 0..<steps {
            let r = Double(i) / Double(steps) * length
            let chord = profile.chordDistribution[i] * length
            let twist = twists[i] * .pi / 180.0
            
            let x = r * widthScale * cos(twist)
            let y = (isLeadingEdge ? 1 : -1) * chord * rect.height * 0.4 * sin(twist)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: rect.midY + y))
            } else {
                path.addLine(to: CGPoint(x: x, y: rect.midY + y))
            }
        }
        
        return path
    }
}

struct Blade3DEffects: View {
    var body: some View {
        GeometryReader { geometry in
            // Эффект освещения
            Rectangle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.clear
                        ]),
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: geometry.size.width * 0.8
                    )
                )
            
            // Эффект тени
            Rectangle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.1),
                            Color.clear
                        ]),
                        center: .bottomTrailing,
                        startRadius: 0,
                        endRadius: geometry.size.width * 0.6
                    )
                )
        }
    }
}

// Расширение для поддержки offset z
extension View {
    func offset(z: CGFloat) -> some View {
        self.transformEffect(.init(translationX: 0, y: z))
    }
}

#Preview {
    Blade3DView(
        profile: BladeProfile.database[0], // Clark Y
        bladeLength: 0.15,
        twistDistribution: [45, 35, 25, 15, 8, 5]
    )
    .frame(width: 400, height: 300)
}
