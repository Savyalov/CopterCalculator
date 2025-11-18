//
//  AboutView.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import SwiftUI

/// # About View
/// Application information, features, and credits
/// Provides overview of application capabilities and development information
public struct AboutView: View {
    
    // MARK: - Body Implementation
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header section
                VStack(spacing: 15) {
                    Image(systemName: "leaf.arrow.circlepath")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    Text("Propeller Designer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Версия 1.0")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 50)
                
                // Description section
                VStack(alignment: .leading, spacing: 15) {
                    Text("О приложении")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Propeller Designer - профессиональное приложение для расчета и проектирования воздушных лопастей беспилотных летательных аппаратов.")
                        .font(.body)
                        .lineSpacing(4)
                    
                    Text("Приложение использует современные методы расчета аэродинамики, включая теорию элемента лопасти и импульса (BEMT), для точного проектирования высокоэффективных пропеллеров.")
                        .font(.body)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 40)
                
                // Features grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
                    FeatureCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Точный расчет",
                        description: "Расчет по методу BEMT с учетом всех аэродинамических эффектов"
                    )
                    
                    FeatureCard(
                        icon: "cube.transparent",
                        title: "3D Визуализация",
                        description: "Фотографическое качество отображения лопастей в реальном времени"
                    )
                    
                    FeatureCard(
                        icon: "square.and.arrow.down",
                        title: "Экспорт",
                        description: "Сохранение в форматах STL и OBJ для 3D печати и моделирования"
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Footer section
                VStack(spacing: 10) {
                    Text("© 2024 Propeller Designer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Разработано с использованием SwiftUI и SceneKit")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 30)
            }
        }
        .background(VisualEffectView(material: .contentBackground, blendingMode: .behindWindow))
    }
}

/// # Feature Card
/// Individual feature description with icon and text
public struct FeatureCard: View {
    
    // MARK: - Properties
    
    /// ## Feature Icon
    /// SF Symbol name representing the feature
    public let icon: String
    
    /// ## Feature Title
    /// Brief title of the feature
    public let title: String
    
    /// ## Feature Description
    /// Detailed description of the feature
    public let description: String
    
    // MARK: - Body Implementation
    
    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.accentColor)
            
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding()
        .frame(height: 150)
        .background(VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Preview Provider

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
