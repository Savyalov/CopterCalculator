//
//  MainView.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import SwiftUI

/// # Main Application View
/// Root view of the Propeller Designer application
/// Manages navigation and coordinates between different view components
public struct MainView: View {
    
    // MARK: - View Models
    
    /// ## Calculation View Model
    /// Manages propeller calculation logic and results
    /// Shared across calculation-related views
    @StateObject private var calculationVM = CalculationViewModel()
    
    /// ## Blade View Model
    /// Manages blade visualization and interaction
    /// Handles 2D/3D view state and camera controls
    @StateObject private var bladeVM = BladeViewModel()
    
    // MARK: - State Properties
    
    /// ## Selected Sidebar Item
    /// Tracks currently selected navigation item in sidebar
    /// Controls which main content view is displayed
    @State private var selectedSidebarItem: SidebarItem = .calculation
    
    // MARK: - Sidebar Items Enum
    
    /// ## Navigation Sidebar Items
    /// Defines available main sections of the application
    public enum SidebarItem: Hashable {
        case calculation    // Propeller calculation and design
        case settings      // Application settings and preferences
        case about         // About and information screen
    }
    
    // MARK: - Body Implementation
    
    public var body: some View {
        NavigationView {
            // Sidebar navigation
            SidebarView(selectedItem: $selectedSidebarItem)
            
            // Main content area
            Group {
                switch selectedSidebarItem {
                case .calculation:
                    CalculationView()
                        .environmentObject(calculationVM)
                        .environmentObject(bladeVM)
                case .settings:
                    SettingsView()
                case .about:
                    AboutView()
                }
            }
            .frame(minWidth: 800, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
        }
        .navigationTitle("Propeller Designer")
        .onAppear {
            // Set up initial connection between view models
            setupViewModelConnections()
        }
        .onChange(of: calculationVM.geometryUpdateTrigger) { _ in
            // React to geometry changes using the trigger
            if let geometry = calculationVM.bladeGeometry {
                updateBladeVisualization(with: geometry)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// ## Setup View Model Connections
    /// Establishes connections between view models for data flow
    /// Called when the view appears to ensure proper initialization
    private func setupViewModelConnections() {
        // If we already have geometry from previous calculations, update visualization
        if let existingGeometry = calculationVM.bladeGeometry {
            updateBladeVisualization(with: existingGeometry)
        }
    }
    
    /// ## Update Blade Visualization
    /// Synchronizes blade geometry between calculation and visualization view models
    /// - Parameter geometry: New blade geometry to visualize
    private func updateBladeVisualization(with geometry: BladeGeometry) {
        bladeVM.updateMesh(from: geometry)
    }
}

// MARK: - Preview Provider

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
