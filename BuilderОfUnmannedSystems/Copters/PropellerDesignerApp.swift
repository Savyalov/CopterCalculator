//
//  PropellerDesignerApp.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import SwiftUI

/// # Propeller Designer Application
/// Main application entry point for macOS propeller design tool
/// Configures window and manages application lifecycle
@main
public struct PropellerDesignerApp: App {
    
    // MARK: - Body Implementation
    
    public var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(DefaultWindowStyle())
        .windowToolbarStyle(UnifiedWindowToolbarStyle())
        
        // Additional windows can be added here for documentation, etc.
    }
    
    // MARK: - Initialization
    
    /// ## Application Initializer
    /// Sets up application-wide configuration and defaults
    public init() {
        configureApplication()
    }
    
    // MARK: - Private Methods
    
    /// ## Configure Application Settings
    /// Sets up application-wide preferences and defaults
    private func configureApplication() {
        // Configure user defaults
        UserDefaults.standard.register(defaults: [
            "defaultExportFormat": "STL",
            "autoRecalculate": true,
            "highQualityRender": true
        ])
        
        // Additional application setup can go here
        // Such as analytics, crash reporting, etc.
    }
}
