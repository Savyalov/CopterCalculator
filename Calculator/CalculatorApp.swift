//
//  CalculatorApp.swift
//  Calculator
//
//  Created by Константин Савялов on 14.11.2025.
//

import SwiftUI

@main
struct PropellerCalculatorApp: App {
    var body: some Scene {
        WindowGroup {
            SidebarMenu()
        }
        .windowStyle(DefaultWindowStyle())
        .windowToolbarStyle(UnifiedWindowToolbarStyle())
        .commands {
            SidebarCommands()
        }
    }
}
