//
//  ResultsView.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import SwiftUI

/// # Results View
/// Displays calculation results and visualization options
/// Shows performance metrics, convergence information, and blade visualizations
public struct ResultsView: View {
    
    // MARK: - Environment Objects
    
    /// ## Calculation View Model
    /// Provides access to calculation results and parameters
    @EnvironmentObject var calculationVM: CalculationViewModel
    
    /// ## Blade View Model
    /// Manages blade visualization state
    @EnvironmentObject var bladeVM: BladeViewModel
    
    // MARK: - Body Implementation
    
    public var body: some View {
        VStack(spacing: 0) {
            // Results header with efficiency badge
            HStack {
                Text("Результаты расчета")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Display efficiency badge if results available
                if let result = calculationVM.calculationResult {
                    EfficiencyBadge(efficiency: result.efficiency)
                }
            }
            .padding()
            .background(VisualEffectView(material: .headerView, blendingMode: .behindWindow))
            
            // Main content area
            HStack(spacing: 0) {
                // Numerical results sidebar
                ResultsSummaryView()
                    .frame(width: 300)
                    .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
                
                Divider()
                
                // Visualization area
                VisualizationTabsView()
                    .environmentObject(bladeVM)
            }
        }
    }
}

/// # Efficiency Badge
/// Displays propeller efficiency with color-coded visual indicator
public struct EfficiencyBadge: View {
    
    // MARK: - Properties
    
    /// ## Propeller Efficiency
    /// Efficiency value from 0.0 to 1.0 (0% to 100%)
    public let efficiency: Double
    
    // MARK: - Body Implementation
    
    public var body: some View {
        HStack {
            Image(systemName: "gauge.medium")
            Text(String(format: "КПД: %.1f%%", efficiency * 100))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            VisualEffectView(material: .selection, blendingMode: .behindWindow)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(6)
        )
        .foregroundColor(.green)
    }
}

/// # Results Summary View
/// Displays numerical results and performance metrics in scrollable sidebar
public struct ResultsSummaryView: View {
    
    // MARK: - Environment Objects
    
    /// ## Calculation View Model
    /// Provides access to calculation results
    @EnvironmentObject var calculationVM: CalculationViewModel
    
    // MARK: - Body Implementation
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let result = calculationVM.calculationResult {
                    // Thrust result card
                    ResultCard(
                        title: "Тяга",
                        value: String(format: "%.2f Н", result.thrust),
                        systemImage: "arrow.up"
                    )
                    
                    // Power result card
                    ResultCard(
                        title: "Мощность",
                        value: String(format: "%.1f Вт", result.power),
                        systemImage: "bolt"
                    )
                    
                    // Torque result card
                    ResultCard(
                        title: "Крутящий момент",
                        value: String(format: "%.3f Н·м", result.torque),
                        systemImage: "arrow.clockwise"
                    )
                    
                    // Convergence information
                    ConvergenceInfoView(convergenceInfo: result.convergenceInfo)
                    
                    // Element distribution if available
                    if let elementData = result.elementData {
                        ElementDistributionView(elements: elementData)
                    }
                }
            }
            .padding()
        }
    }
}

/// # Result Card
/// Individual metric display card with icon and formatted value
public struct ResultCard: View {
    
    // MARK: - Properties
    
    /// ## Metric Title
    /// Name of the performance metric
    public let title: String
    
    /// ## Formatted Value
    /// String representation of the metric value with units
    public let value: String
    
    /// ## System Image Name
    /// SF Symbol name for metric icon
    public let systemImage: String
    
    // MARK: - Body Implementation
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding()
        .background(VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

/// # Convergence Information View
/// Displays iterative solution convergence details
public struct ConvergenceInfoView: View {
    
    // MARK: - Properties
    
    /// ## Convergence Information
    /// Data about solution convergence and iteration statistics
    public let convergenceInfo: ConvergenceInfo
    
    // MARK: - Body Implementation
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Сходимость расчета")
                .font(.headline)
            
            HStack {
                StatusIndicator(isConverged: convergenceInfo.converged)
                
                VStack(alignment: .leading) {
                    Text(convergenceInfo.converged ? "Сходимость достигнута" : "Сходимость не достигнута")
                        .foregroundColor(convergenceInfo.converged ? .green : .orange)
                    
                    Text("\(convergenceInfo.iterations) итераций")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow))
        .cornerRadius(8)
    }
}

/// # Status Indicator
/// Color-coded dot indicating convergence status
public struct StatusIndicator: View {
    
    // MARK: - Properties
    
    /// ## Convergence Status
    /// Boolean indicating successful convergence
    public let isConverged: Bool
    
    // MARK: - Body Implementation
    
    public var body: some View {
        Circle()
            .fill(isConverged ? Color.green : Color.orange)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
    }
}

/// # Visualization Tabs View
/// Manages switching between 3D and 2D visualization modes
public struct VisualizationTabsView: View {
    
    // MARK: - Environment Objects
    
    /// ## Blade View Model
    /// Controls visualization state and blade data
    @EnvironmentObject var bladeVM: BladeViewModel
    
    // MARK: - State Properties
    
    /// ## Selected Tab Index
    /// Tracks currently active visualization tab (0 = 3D, 1 = 2D)
    @State private var selectedTab = 0
    
    // MARK: - Body Implementation
    
    public var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("", selection: $selectedTab) {
                Text("3D Модель").tag(0)
                Text("2D Чертеж").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Tab content
            Group {
                switch selectedTab {
                case 0:
                    Blade3DView()
                        .environmentObject(bladeVM)
                case 1:
                    Blade2DView()
                        .environmentObject(bladeVM)
                default:
                    EmptyView()
                }
            }
            .animation(.default, value: selectedTab)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// # Element Distribution View
/// Shows radial distribution of thrust along the blade
public struct ElementDistributionView: View {
    
    // MARK: - Properties
    
    /// ## Blade Element Data
    /// Array of element data points for distribution visualization
    public let elements: [BladeElementData]
    
    // MARK: - Body Implementation
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Распределение по радиусу")
                .font(.headline)
            
            // Simplified distribution chart
            GeometryReader { geometry in
                ZStack {
                    // Background
                    VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                    
                    // Thrust distribution line
                    Path { path in
                        let maxThrust = elements.map { $0.thrust }.max() ?? 1.0
                        let width = geometry.size.width
                        let height = geometry.size.height
                        
                        for (index, element) in elements.enumerated() {
                            let x = CGFloat(index) / CGFloat(elements.count - 1) * width
                            let y = height - (CGFloat(element.thrust / maxThrust) * height * 0.8)
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.blue, lineWidth: 2)
                }
            }
            .frame(height: 100)
            .cornerRadius(4)
        }
        .padding()
        .background(VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow))
        .cornerRadius(8)
    }
}

// MARK: - Preview Provider

struct ResultsView_Previews: PreviewProvider {
    static var previews: some View {
        ResultsView()
            .environmentObject(CalculationViewModel())
            .environmentObject(BladeViewModel())
    }
}
