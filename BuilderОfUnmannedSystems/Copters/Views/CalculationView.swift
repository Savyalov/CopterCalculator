//
//  CalculationView.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import SwiftUI
 
/// # Calculation View
/// Main view for propeller calculation and parameter input
/// Provides user interface for setting design parameters and initiating calculations
public struct CalculationView: View {
    
    // MARK: - Environment Objects
    
    /// ## Calculation View Model
    /// Manages calculation logic, parameters, and results
    @EnvironmentObject var calculationVM: CalculationViewModel
    
    /// ## Blade View Model
    /// Handles blade visualization and interaction
    @EnvironmentObject var bladeVM: BladeViewModel
    
    // MARK: - Body Implementation
    
    public var body: some View {
        VStack(spacing: 0) {
            // Parameters and controls section
            ParameterInputView()
                .environmentObject(calculationVM)
            
            Divider()
            
            // Results and visualization section
            if calculationVM.isCalculating {
                CalculationProgressView()
            } else if calculationVM.calculationResult != nil {
                ResultsView()
                    .environmentObject(calculationVM)
                    .environmentObject(bladeVM)
            } else {
                WelcomeView()
            }
        }
    }
}

// MARK: - Supporting Views

/// # Parameter Input View
/// Handles user input for all design parameters
/// Organized into logical groups with validation
public struct ParameterInputView: View {
    
    // MARK: - Environment Objects
    
    /// ## Calculation View Model
    /// Provides access to parameters and calculation methods
    @EnvironmentObject var calculationVM: CalculationViewModel
    
    // MARK: - Body Implementation
    
    public var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 20) {
                // Drone parameters group
                ParameterGroupView(title: "Параметры дрона") {
                    ParameterField(
                        title: "Масса (кг)",
                        value: $calculationVM.parameters.droneMass,
                        range: 0.1...10.0,
                        step: 1
                    )
                    ParameterField(
                        title: "Макс. скорость (м/с)",
                        value: $calculationVM.parameters.maxSpeed,
                        range: 1...100.0,
                        step: 1
                    )
                    ParameterField(
                        title: "Количество лопастей",
                        value: Binding(
                            get: { Double(calculationVM.parameters.numberOfBlades) },
                            set: { calculationVM.parameters.numberOfBlades = Int($0) }
                        ),
                        range: 1...8,
                        step: 1
                    )
                    ParameterField(
                        title: "Количество моторов",
                        value: Binding(
                            get: { Double(calculationVM.parameters.numberOfMotors) },
                            set: { calculationVM.parameters.numberOfMotors = Int($0) }
                        ),
                        range: 1...12,
                        step: 1
                    )
                }
                
                // Flight conditions group
                ParameterGroupView(title: "Условия полета") {
                    ParameterField(
                        title: "Высота полета (м)",
                        value: $calculationVM.parameters.operatingAltitude,
                        range: 1...5000.0,
                        step: 1
                    )
                    ParameterField(
                        title: "Целевые RPM",
                        value: $calculationVM.parameters.targetRPM,
                        range: 1000...20000.0,
                        step: 1
                    )
                }
                
                // Blade geometry group
                ParameterGroupView(title: "Геометрия лопасти") {
                    ParameterField(
                        title: "Радиус лопасти (м)",
                        value: $calculationVM.parameters.bladeRadius,
                        range: 0.05...0.5,
                        step: 1
                    )
                    ParameterField(
                        title: "Вырез корня (м)",
                        value: $calculationVM.parameters.rootCutout,
                        range: 0.01...0.1,
                        step: 1
                    )
                }
            }
            .padding()
            
            // Calculate button
            HStack {
                Spacer()
                
                Button(action: {
                    calculationVM.calculateBlade()
                }) {
                    HStack {
                        Image(systemName: "leaf.arrow.circlepath")
                        Text("Рассчитать лопасть")
                    }
                    .padding(.horizontal, 20)
                }
                .buttonStyle(LiquidGlassButtonStyle())
                .disabled(calculationVM.isCalculating)
            }
            .padding()
        }
        .background(VisualEffectView(material: .contentBackground, blendingMode: .behindWindow))
    }
}

/// # Parameter Group Container
/// Wrapper for logically grouped parameters with title and styling
public struct ParameterGroupView<Content: View>: View {
    
    // MARK: - Properties
    
    /// ## Group Title
    /// Descriptive title for the parameter group
    public let title: String
    
    /// ## Group Content
    /// Child views containing parameter fields
    public let content: Content
    
    // MARK: - Initialization
    
    /// ## Parameter Group Initializer
    /// Creates a new parameter group with title and content
    /// - Parameters:
    ///   - title: Group title string
    ///   - content: View builder for parameter fields
    public init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    // MARK: - Body Implementation
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
        }
        .padding()
        .background(VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

/// # Parameter Input Field
/// Individual parameter input with label, slider, and text field
public struct ParameterField: View {
    
    public init(title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double = 0.1) {
        self.title = title
        self._value = value
        
        // Проверяем и корректируем диапазон
        let lower = range.lowerBound
        let upper = range.upperBound
        if lower <= upper {
            self.range = range
        } else {
            // Если диапазон инвертирован, исправляем его
            self.range = upper...lower
            print("⚠️ Предупреждение: Диапазон исправлен с \(lower)...\(upper) на \(upper)...\(lower)")
        }
        
        // Проверяем и корректируем шаг
        self.step = max(step, 0.001) // Минимальный положительный шаг
        if step <= 0 {
            print("⚠️ Предупреждение: Шаг исправлен с \(step) на \(self.step)")
        }
    }
    
    // MARK: - Properties
    
    /// ## Field Title
    /// Descriptive label for the parameter
    public let title: String
    
    /// ## Parameter Value Binding
    /// Two-way binding to the parameter value
    @Binding public var value: Double
    
    /// ## Value Range
    /// Valid range for the parameter value
    public let range: ClosedRange<Double>
    
    /// ## Slider Step
    /// Increment step for the slider control
    public let step: Double
    
    // MARK: - Initialization
    
    /// ## Parameter Field Initializer
    /// Creates a new parameter input field
    /// - Parameters:
    ///   - title: Field label text
    ///   - value: Binding to parameter value
    ///   - range: Valid value range
    ///   - step: Slider increment step
//    public init(title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double = 0.1) {
//        self.title = title
//        self._value = value
//        self.range = range
//        self.step = step
//    }
    
    // MARK: - Body Implementation
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                // Slider for coarse adjustment
                Slider(value: $value, in: range, step: step)
                    .accentColor(.accentColor)
                
                // Text field for precise input
                TextField("", value: $value, formatter: NumberFormatter.decimalFormatter)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 60)
            }
        }
    }
}

/// # Calculation Progress View
/// Displays progress indicator during calculation
public struct CalculationProgressView: View {
    
    // MARK: - Body Implementation
    
    public var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Выполняется расчет...")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Это может занять несколько секунд")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// # Welcome View
/// Initial state view with application introduction
public struct WelcomeView: View {
    
    // MARK: - Body Implementation
    
    public var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "leaf.arrow.circlepath")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("Propeller Designer")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Введите параметры и нажмите 'Рассчитать лопасть' для начала")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview Provider

struct CalculationView_Previews: PreviewProvider {
    static var previews: some View {
        CalculationView()
            .environmentObject(CalculationViewModel())
            .environmentObject(BladeViewModel())
    }
}
