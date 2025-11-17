//
//  SidebarMenu.swift
//  Calculator
//
//  Created by Константин Савялов on 16.11.2025.
//

import SwiftUI

struct SidebarMenu: View {
    @State private var selectedView = 0
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: ContentView()) {
                    Label("Конструктор лопасти", systemImage: "house")
                }
                NavigationLink(destination: HelpView()) {
                    Label("Помощь", systemImage: "questionmark")
                }
                NavigationLink(destination: SettingView()) {
                    Label("Настройки", systemImage: "star")
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Меню")
            
            // Стартовый экран при запуске
            ContentView()
        }
    }
}
