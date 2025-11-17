//
//  BladeProfileView.swift
//  Calculator
//
//  Created by Константин Савялов on 15.11.2025.
//

import SwiftUI

struct BladeProfileView: View {
    let profile: BladeProfile
    let chordLength: Double
    let sectionIndex: Int
    
    // Масштаб для отображения (1 метр = 1000 точек)
    private var displayScale: Double { 1000.0 }
    
    var body: some View {
        VStack {
            Text("Профиль лопасти - Сечение \(sectionIndex + 1)")
                .font(.headline)
                .padding(.bottom, 8)
            
            ZStack {
                // Фон
                Rectangle()
                    .fill(Color.white)
                    .border(Color.gray)
                
                // Профиль лопасти в реальном масштабе
                BladeProfileShape(
                    profileType: profile.type,
                    thickness: profile.thicknessDistribution[sectionIndex]
                )
                .fill(profileGradient)
                .stroke(Color.black, lineWidth: 1)
                .frame(
                    width: chordLength * displayScale,
                    height: chordLength * profile.thicknessDistribution[sectionIndex] / 100 * displayScale
                )
                
                // Размеры и аннотации
                ProfileAnnotations(
                    chordLength: chordLength,
                    thickness: chordLength * profile.thicknessDistribution[sectionIndex] / 100,
                    twist: profile.twistDistribution[sectionIndex]
                )
            }
            .frame(height: 250)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(profile.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Радиус сечения: \((Double(sectionIndex) / 5.0) * chordLength * 6, specifier: "%.3f") м")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("Толщина материала: \(profile.materialThickness, specifier: "%.1f") мм")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .padding()
    }
    
    private var profileGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.8),
                Color.blue.opacity(0.4),
                Color.blue.opacity(0.2)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct BladeProfileShape: Shape {
    let profileType: BladeProfile.ProfileType
    let thickness: Double // толщина в % хорды
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        switch profileType {
        case .flatPlate:
            drawFlatPlate(in: rect, path: &path)
        case .clarkY:
            drawClarkY(in: rect, path: &path)
        case .naca0012:
            drawNACA0012(in: rect, path: &path)
        case .naca4412:
            drawNACA4412(in: rect, path: &path)
        case .eppler:
            drawEppler(in: rect, path: &path)
        case .custom:
            drawClarkY(in: rect, path: &path)
        }
        
        return path
    }
    
    private func drawFlatPlate(in rect: CGRect, path: inout Path) {
        let thicknessHeight = rect.height * 0.1
        path.move(to: CGPoint(x: rect.minX, y: rect.midY - thicknessHeight/2))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY - thicknessHeight/2))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY + thicknessHeight/2))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY + thicknessHeight/2))
        path.closeSubpath()
    }
    
    private func drawClarkY(in rect: CGRect, path: inout Path) {
        let width = rect.width
        let maxThickness = rect.height
        
        // Верхняя поверхность (выпуклая)
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        
        for x in stride(from: 0, through: width, by: width / 20) {
            let normalizedX = x / width
            // Формула профиля Clark Y
            let yc = 0.3 * (0.2969 * sqrt(normalizedX) - 0.1260 * normalizedX - 0.3516 * pow(normalizedX, 2) + 0.2843 * pow(normalizedX, 3) - 0.1015 * pow(normalizedX, 4))
            let y = -maxThickness * yc
            path.addLine(to: CGPoint(x: rect.minX + x, y: rect.midY + y))
        }
        
        // Нижняя поверхность (почти плоская)
        for x in stride(from: width, through: 0, by: -width / 20) {
            let normalizedX = x / width
            let yc = 0.3 * (0.2969 * sqrt(normalizedX) - 0.1260 * normalizedX - 0.3516 * pow(normalizedX, 2) + 0.2843 * pow(normalizedX, 3) - 0.1015 * pow(normalizedX, 4))
            let y = maxThickness * yc * 0.3 // Нижняя поверхность менее выпуклая
            path.addLine(to: CGPoint(x: rect.minX + x, y: rect.midY + y))
        }
        
        path.closeSubpath()
    }
    
    private func drawNACA0012(in rect: CGRect, path: inout Path) {
        let width = rect.width
        let maxThickness = rect.height
        
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        
        // Симметричный профиль NACA 00xx
        for x in stride(from: 0, through: width, by: width / 20) {
            let normalizedX = x / width
            let yt = 0.12 * (0.2969 * sqrt(normalizedX) - 0.1260 * normalizedX -
                           0.3516 * pow(normalizedX, 2) + 0.2843 * pow(normalizedX, 3) -
                           0.1015 * pow(normalizedX, 4))
            let y = -maxThickness * yt
            path.addLine(to: CGPoint(x: rect.minX + x, y: rect.midY + y))
        }
        
        for x in stride(from: width, through: 0, by: -width / 20) {
            let normalizedX = x / width
            let yt = 0.12 * (0.2969 * sqrt(normalizedX) - 0.1260 * normalizedX -
                           0.3516 * pow(normalizedX, 2) + 0.2843 * pow(normalizedX, 3) -
                           0.1015 * pow(normalizedX, 4))
            let y = maxThickness * yt
            path.addLine(to: CGPoint(x: rect.minX + x, y: rect.midY + y))
        }
        
        path.closeSubpath()
    }
    
    private func drawNACA4412(in rect: CGRect, path: inout Path) {
        let width = rect.width
        let maxThickness = rect.height
        
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        
        // Асимметричный профиль с камбром 4%
        for x in stride(from: 0, through: width, by: width / 20) {
            let normalizedX = x / width
            let yc = 0.04 * (2 * normalizedX - pow(normalizedX, 2))
            let yt = 0.12 * (0.2969 * sqrt(normalizedX) - 0.1260 * normalizedX -
                           0.3516 * pow(normalizedX, 2) + 0.2843 * pow(normalizedX, 3) -
                           0.1015 * pow(normalizedX, 4))
            let y = -maxThickness * (yc + yt)
            path.addLine(to: CGPoint(x: rect.minX + x, y: rect.midY + y))
        }
        
        for x in stride(from: width, through: 0, by: -width / 20) {
            let normalizedX = x / width
            let yc = 0.04 * (2 * normalizedX - pow(normalizedX, 2))
            let yt = 0.12 * (0.2969 * sqrt(normalizedX) - 0.1260 * normalizedX -
                           0.3516 * pow(normalizedX, 2) + 0.2843 * pow(normalizedX, 3) -
                           0.1015 * pow(normalizedX, 4))
            let y = maxThickness * (yt - yc)
            path.addLine(to: CGPoint(x: rect.minX + x, y: rect.midY + y))
        }
        
        path.closeSubpath()
    }
    
    private func drawEppler(in rect: CGRect, path: inout Path) {
        let width = rect.width
        let maxThickness = rect.height
        
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        
        // Упрощенная форма Eppler
        for x in stride(from: 0, through: width, by: width / 20) {
            let normalizedX = x / width
            let y = -maxThickness * 0.08 * sin(normalizedX * .pi) * (1.5 - normalizedX)
            path.addLine(to: CGPoint(x: rect.minX + x, y: rect.midY + y))
        }
        
        for x in stride(from: width, through: 0, by: -width / 20) {
            let normalizedX = x / width
            let y = maxThickness * 0.06 * sin(normalizedX * .pi) * (1.2 - normalizedX)
            path.addLine(to: CGPoint(x: rect.minX + x, y: rect.midY + y))
        }
        
        path.closeSubpath()
    }
}

struct ProfileAnnotations: View {
    let chordLength: Double
    let thickness: Double
    let twist: Double
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            // Линия хорды
            Path { path in
                path.move(to: CGPoint(x: 0, y: height - 30))
                path.addLine(to: CGPoint(x: width, y: height - 30))
            }
            .stroke(Color.red, style: StrokeStyle(lineWidth: 2, dash: [5]))
            
            // Подпись хорды
            HStack {
                Image(systemName: "arrow.left")
                Text("Хорда: \(chordLength * 1000, specifier: "%.1f") мм")
                    .font(.system(size: 12, weight: .medium))
                Image(systemName: "arrow.right")
            }
            .foregroundColor(.red)
            .position(x: width / 2, y: height - 15)
            
            // Толщина профиля
            VStack {
                Image(systemName: "arrow.up")
                Text("Толщина: \(thickness * 1000, specifier: "%.1f") мм")
                    .font(.system(size: 10, weight: .medium))
                Image(systemName: "arrow.down")
            }
            .foregroundColor(.green)
            .position(x: width * 0.3, y: height / 2)
            
            // Угол установки
            VStack {
                Text("Угол: \(twist, specifier: "%.1f")°")
                    .font(.system(size: 10, weight: .medium))
                    .rotationEffect(.degrees(-90))
            }
            .foregroundColor(.blue)
            .position(x: width - 20, y: height / 2)
            
            // Масштабная сетка
            Path { path in
                for i in 0...10 {
                    let x = width * Double(i) / 10
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                for i in 0...5 {
                    let y = height * Double(i) / 5
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        }
    }
}

#Preview {
    BladeProfileView(
        profile: BladeProfile.database[0],
        chordLength: 0.035,
        sectionIndex: 0
    )
    .frame(width: 500, height: 350)
}
