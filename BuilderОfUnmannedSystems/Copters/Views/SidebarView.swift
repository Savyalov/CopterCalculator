//
//  SidebarView.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import SwiftUI

/// # Application Sidebar View
/// Provides navigation between main application sections
/// Implements macOS-style sidebar with visual effects
public struct SidebarView: View {
    
    // MARK: - Properties
    
    /// ## Selected Sidebar Item Binding
    /// Two-way binding to track currently selected navigation item
    /// Coordinated with main view navigation state
    @Binding public var selectedItem: MainView.SidebarItem
    
    // MARK: - Body Implementation
    
    public var body: some View {
        List(selection: $selectedItem) {
            // Calculation section link
            NavigationLink(destination: EmptyView()) {
                SidebarRow(
                    title: "Расчет лопастей",
                    systemImage: "leaf.arrow.circlepath",
                    isSelected: selectedItem == .calculation
                )
            }
            .tag(MainView.SidebarItem.calculation)
            
            // Settings section link
            NavigationLink(destination: EmptyView()) {
                SidebarRow(
                    title: "Настройки",
                    systemImage: "gear",
                    isSelected: selectedItem == .settings
                )
            }
            .tag(MainView.SidebarItem.settings)
            
            // About section link
            NavigationLink(destination: EmptyView()) {
                SidebarRow(
                    title: "О нас",
                    systemImage: "info.circle",
                    isSelected: selectedItem == .about
                )
            }
            .tag(MainView.SidebarItem.about)
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
    }
}

/// # Sidebar Row Component
/// Individual navigation item in the sidebar
/// Highlights when selected and provides visual feedback
public struct SidebarRow: View {
    
    // MARK: - Properties
    
    /// ## Row Title
    /// Display text for the navigation item
    /// Describes the section or functionality
    public let title: String
    
    /// ## System Image Name
    /// SF Symbols icon name for visual representation
    /// Provides intuitive visual cue for section type
    public let systemImage: String
    
    /// ## Selection State
    /// Indicates whether this row is currently selected
    /// Controls highlight and accent color application
    public let isSelected: Bool
    
    // MARK: - Body Implementation
    
    public var body: some View {
        HStack {
            // Icon with selection-sensitive coloring
            Image(systemName: systemImage)
                .foregroundColor(isSelected ? .accentColor : .primary)
                .frame(width: 20)
            
            // Title with selection-sensitive coloring
            Text(title)
                .foregroundColor(isSelected ? .accentColor : .primary)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}
