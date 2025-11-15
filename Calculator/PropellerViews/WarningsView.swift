//
//  WarningsView.swift
//  Calculator
//
//  Created by Константин Савялов on 15.11.2025.
//

import SwiftUI

// MARK: - Предупреждения
struct WarningsView: View {
    @ObservedObject var model: PropellerModel
    
    var body: some View {
        VStack(spacing: 8) {
            if model.tipSpeedMach > 0.7 {
                WarningView(message: "Внимание: Окружная скорость приближается к звуковой!")
            }
            
            if model.efficiency > 0.85 {
                WarningView(message: "Высокий КПД - проверьте корректность входных параметров", isWarning: false)
            }
            
            if model.power > 10000 {
                WarningView(message: "Высокая мощность - требуется проверка системы охлаждения")
            }
        }
    }
}
