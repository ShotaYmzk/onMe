//
//  ContentView.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            GroupListView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("グループ")
                }
                .tag(AppState.Tab.groups)
            
            ExpenseListView()
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("支出")
                }
                .tag(AppState.Tab.expenses)
            
            SettlementView()
                .tabItem {
                    Image(systemName: "arrow.left.arrow.right")
                    Text("清算")
                }
                .tag(AppState.Tab.settlements)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("設定")
                }
                .tag(AppState.Tab.settings)
        }
        .accentColor(.blue)
        .preferredColorScheme(appState.isDarkModeEnabled ? .dark : .light)
        .onAppear {
            // タブバーの外観をカスタマイズ
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor.systemBackground
            
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
