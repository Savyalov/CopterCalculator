//
//  BladeTopView.swift
//  Calculator
//
//  Created by Константин Савялов on 15.11.2025.
//

import SwiftUI

import SwiftUI

struct BladeTopView: View {
    let profile: BladeProfile
    let bladeLength: Double // длина лопасти в метрах
    
    private var displayScale: Double { 800.0 } // масштаб отображения
    
    var body: some View {
        VStack {
            Text("Геометрия лопасти - Вид сверху")
                .font(.headline)
                .padding(.bottom, 8)
            
            ZStack {
                // Фон
                Rectangle()
                    .fill(Color.white)
                    .border(Color.gray)
                
                // Лопасть сверху
                BladeTopShape(
                    chordDistribution: profile.chordDistribution,
                    length: bladeLength
                )
                .fill(bladeGradient)
                .stroke(Color.black, lineWidth: 1)
                
                // Размеры и аннотации
                TopViewAnnotations(
                    bladeLength: bladeLength,
                    chordDistribution: profile.chordDistribution,
                    twistDistribution: profile.twistDistribution
                )
                
                // Сетка координат
                CoordinateGrid()
            }
            .frame(height: 300)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(profile.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Длина лопасти: \(bladeLength * 1000, specifier: "%.0f") мм")
                    Text("•")
                    Text("Корневая хорда: \(profile.rootChord * 1000, specifier: "%.1f") мм")
                    Text("•")
                    Text("Концевая хорда: \(profile.tipChord * 1000, specifier: "%.1f") мм")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .padding()
    }
    
    private var bladeGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.green.opacity(0.8),
                Color.green.opacity(0.4),
                Color.green.opacity(0.2)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct BladeTopShape: Shape {
    let chordDistribution: [Double]
    let length: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let steps = chordDistribution.count
        let widthScale = rect.width / length
        
        // Правая сторона лопасти (от корня к концу)
        for i in 0..<steps {
            let r = Double(i) / Double(steps) * length
            let chord = chordDistribution[i]
            let x = r * widthScale
            let y = chord * widthScale / 2 // масштабируем хорду
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: rect.midY + y))
            } else {
                path.addLine(to: CGPoint(x: x, y: rect.midY + y))
            }
        }
        
        // Левая сторона лопасти (от конца к корню)
        for i in (0..<steps).reversed() {
            let r = Double(i) / Double(steps) * length
            let chord = chordDistribution[i]
            let x = r * widthScale
            let y = chord * widthScale / 2
            
            path.addLine(to: CGPoint(x: x, y: rect.midY - y))
        }
        
        path.closeSubpath()
        return path
    }
}

struct TopViewAnnotations: View {
    let bladeLength: Double
    let chordDistribution: [Double]
    let twistDistribution: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let midY = geometry.size.height / 2  // Вычисляем середину
            
            // Длина лопасти
            Path { path in
                path.move(to: CGPoint(x: 0, y: height - 40))
                path.addLine(to: CGPoint(x: width, y: height - 40))
            }
            .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5]))
            
            // Подпись длины
            HStack {
                Image(systemName: "arrow.left")
                Text("Длина: \(bladeLength * 1000, specifier: "%.0f") мм")
                    .font(.system(size: 12, weight: .medium))
                Image(systemName: "arrow.right")
            }
            .foregroundColor(.blue)
            .position(x: width / 2, y: height - 25)
            
            // Сечения с углами
            ForEach(Array(chordDistribution.indices), id: \.self) { i in
                let x = (Double(i) / Double(chordDistribution.count - 1)) * width
                let chord = chordDistribution[i] * width / bladeLength
                let twist = twistDistribution[i]
                
                // Линия сечения
                Path { path in
                    path.move(to: CGPoint(x: x, y: midY - chord/2))
                    path.addLine(to: CGPoint(x: x, y: midY + chord/2))
                }
                .stroke(Color.orange.opacity(0.6), lineWidth: 1)
                
                // Подпись сечения
                VStack(spacing: 2) {
                    Text("\(i+1)")
                        .font(.system(size: 8, weight: .bold))
                    Text("\(twist, specifier: "%.0f")°")
                        .font(.system(size: 8))
                    Text("\(chordDistribution[i] * 1000, specifier: "%.0f")мм")
                        .font(.system(size: 8))
                }
                .foregroundColor(.orange)
                .position(x: x, y: midY + chord/2 + 25)
            }
        }
    }
}

struct CoordinateGrid: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                // Вертикальные линии
                for i in 0...10 {
                    let x = geometry.size.width * Double(i) / 10
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
                // Горизонтальные линии
                for i in 0...5 {
                    let y = geometry.size.height * Double(i) / 5
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        }
    }
}

#Preview {
    BladeTopView(
        profile: BladeProfile.database[0],
        bladeLength: 0.125 // 125 мм для 10" пропеллера
    )
    .frame(width: 600, height: 400)
}
