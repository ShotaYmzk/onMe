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
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.unifiedPrimary, Color.unifiedPrimary.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: Color.unifiedPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
                            .scaleEffect(1.0)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 90) // タブバーの上に配置
                }
            }
        )
        .accentColor(.blue)
        .preferredColorScheme(appState.isDarkModeEnabled ? .dark : .light)
        .onAppear {
            // タブバーの外観を統一されたスタイルでカスタマイズ
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor.systemBackground
            
            // 選択されたタブのアクセントカラーを統一
            tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor.systemBlue,
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
            ]
            
            // 非選択タブのスタイル
            tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.secondaryLabel,
                .font: UIFont.systemFont(ofSize: 10, weight: .medium)
            ]
            
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
