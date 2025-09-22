//
//  ContentView.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingExpenseForm = false
    @State private var showingOnboarding = false
    
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
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingExpenseForm = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 90) // タブバーの上に配置
                }
            }
        )
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
        .sheet(isPresented: $showingExpenseForm) {
            ExpenseFormView(preselectedGroup: appState.selectedGroup)
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView()
        }
        .onAppear {
            checkOnboardingStatus()
        }
    }
    
    private func checkOnboardingStatus() {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if !hasCompletedOnboarding {
            showingOnboarding = true
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
