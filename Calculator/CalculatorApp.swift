//
//  CalculatorApp.swift
//  Calculator
//
//  Created by Константин Савялов on 14.11.2025.
//

import SwiftUI

@main
struct CalculatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(DefaultWindowStyle())
        .windowToolbarStyle(UnifiedWindowToolbarStyle())
        .commands {
            SidebarCommands()
        }
    }
}
