//
//  ParameterRow.swift
//  Calculator
//
//  Created by Константин Савялов on 15.11.2025.
//

import SwiftUI

struct ParameterRow: View {
    let title: String
    @Binding var value: String
    let defaultValue: String
    
    var body: some View {
        HStack {
            Text(title)
                .frame(width: 180, alignment: .leading)
            Spacer()
            TextField("", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 100)
            
            Button("⟲") {
                value = defaultValue
            }
            .buttonStyle(BorderlessButtonStyle())
            .help("Восстановить значение по умолчанию")
            .font(.system(size: 14, weight: .bold))
        }
    }
}
