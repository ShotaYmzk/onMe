//
//  OnboardingView.swift
//  onMe
//
//  Created by AI Assistant on 2025/09/22.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState
    @State private var currentPage = 0
    @State private var showingQuickStart = false
    
    private let pages = [
        OnboardingPage(
            title: "onMeへようこそ",
            subtitle: "旅行の割り勘を簡単に",
            description: "友達との旅行やイベントで発生した支出を記録し、誰が誰にいくら返せば良いかを自動で計算します",
            imageName: "person.3.fill",
            color: .blue
        ),
        OnboardingPage(
            title: "レシートを撮影するだけ",
            subtitle: "OCR機能で自動入力",
            description: "カメラでレシートを撮影すると、金額を自動で読み取り、支出記録が簡単に作成できます",
            imageName: "camera.fill",
            color: .green
        ),
        OnboardingPage(
            title: "多通貨対応",
            subtitle: "海外旅行も安心",
            description: "リアルタイムの為替レートで異なる通貨の支出も正確に管理。世界中どこでも使えます",
            imageName: "yensign.circle.fill",
            color: .orange
        ),
        OnboardingPage(
            title: "最適な清算方法を提案",
            subtitle: "複雑な計算はお任せ",
            description: "独自のアルゴリズムで、最小限の取引回数で全員の債務を清算する方法を自動で提案します",
            imageName: "arrow.left.arrow.right.circle.fill",
            color: .purple
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // ページインジケーター
            HStack {
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? pages[currentPage].color : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                
                Spacer()
                
                Button("スキップ") {
                    completeOnboarding()
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // メインコンテンツ
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            // ボトムエリア
            VStack(spacing: 16) {
                if currentPage == pages.count - 1 {
                    // 最後のページ: 開始ボタン
                    VStack(spacing: 12) {
                        Button(action: { showingQuickStart = true }) {
                            HStack {
                                Image(systemName: "rocket.fill")
                                    .font(.title3)
                                Text("すぐに始める")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        Button("後で設定する") {
                            completeOnboarding()
                        }
                        .foregroundColor(.secondary)
                        .font(.body)
                    }
                } else {
                    // 進行中のページ: 次へボタン
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    }) {
                        HStack {
                            Text("次へ")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                                .font(.body)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(pages[currentPage].color)
                        .cornerRadius(16)
                        .shadow(color: pages[currentPage].color.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(UIColor.systemBackground),
                    pages[currentPage].color.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .sheet(isPresented: $showingQuickStart) {
            QuickStartView()
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        dismiss()
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // アニメーション付きアイコン
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [page.color.opacity(0.1), page.color.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(isAnimated ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimated)
                
                Image(systemName: page.imageName)
                    .font(.system(size: 64))
                    .foregroundColor(page.color)
                    .rotationEffect(.degrees(isAnimated ? 5 : -5))
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimated)
            }
            
            // テキストコンテンツ
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(page.color)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation {
                isAnimated = true
            }
        }
    }
}

struct QuickStartView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState
    
    @State private var groupName = ""
    @State private var memberName = ""
    @State private var members: [String] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var currentStep = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // プログレスインジケーター
                HStack {
                    ForEach(0..<3, id: \.self) { step in
                        Circle()
                            .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                        
                        if step < 2 {
                            Rectangle()
                                .fill(step < currentStep ? Color.blue : Color.gray.opacity(0.3))
                                .frame(height: 2)
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 16)
                
                // ステップコンテンツ
                VStack(spacing: 32) {
                    switch currentStep {
                    case 0:
                        QuickStartStepView(
                            title: "グループ名を入力",
                            description: "旅行やイベントの名前を入力してください",
                            icon: "person.3.fill",
                            color: .blue
                        ) {
                            TextField("例: 沖縄旅行、忘年会", text: $groupName)
                                .textFieldStyle(.roundedBorder)
                                .font(.body)
                        }
                        
                    case 1:
                        QuickStartStepView(
                            title: "メンバーを追加",
                            description: "一緒に参加するメンバーの名前を入力してください",
                            icon: "person.badge.plus",
                            color: .green
                        ) {
                            VStack(spacing: 12) {
                                HStack {
                                    TextField("メンバー名", text: $memberName)
                                        .textFieldStyle(.roundedBorder)
                                        .onSubmit {
                                            addMember()
                                        }
                                    
                                    Button(action: addMember) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.green)
                                    }
                                    .disabled(memberName.trimmingCharacters(in: .whitespaces).isEmpty)
                                }
                                
                                if !members.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(members, id: \.self) { member in
                                                HStack(spacing: 4) {
                                                    Text(member)
                                                        .font(.caption)
                                                    Button(action: { removeMember(member) }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .font(.caption)
                                                            .foregroundColor(.red)
                                                    }
                                                }
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.green.opacity(0.1))
                                                .cornerRadius(12)
                                            }
                                        }
                                        .padding(.horizontal, 4)
                                    }
                                }
                            }
                        }
                        
                    case 2:
                        QuickStartStepView(
                            title: "設定完了！",
                            description: "グループが作成されました。支出の記録を始めましょう",
                            icon: "checkmark.circle.fill",
                            color: .blue
                        ) {
                            VStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("グループ名: \(groupName)")
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Text("メンバー: \(members.joined(separator: ", "))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        }
                        
                    default:
                        EmptyView()
                    }
                }
                
                Spacer()
                
                // ボタンエリア
                VStack(spacing: 12) {
                    if currentStep < 2 {
                        Button(action: nextStep) {
                            HStack {
                                Text(currentStep == 1 ? "完了" : "次へ")
                                    .fontWeight(.semibold)
                                if currentStep < 1 {
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                        .disabled(!canProceed)
                        
                        if currentStep > 0 {
                            Button("戻る") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep -= 1
                                }
                            }
                            .foregroundColor(.secondary)
                        }
                    } else {
                        Button(action: createGroupAndDismiss) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                Text("始める")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .navigationTitle("クイックスタート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("スキップ") {
                        completeOnboarding()
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .alert("エラー", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return !groupName.trimmingCharacters(in: .whitespaces).isEmpty
        case 1:
            return !members.isEmpty
        default:
            return true
        }
    }
    
    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentStep == 1 {
                // グループ作成
                createGroup()
            } else {
                currentStep += 1
            }
        }
    }
    
    private func addMember() {
        let trimmedName = memberName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        if !members.contains(trimmedName) {
            withAnimation(.easeInOut(duration: 0.2)) {
                members.append(trimmedName)
                memberName = ""
            }
        }
    }
    
    private func removeMember(_ member: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            members.removeAll { $0 == member }
        }
    }
    
    private func createGroup() {
        let newGroup = TravelGroup(context: viewContext)
        newGroup.id = UUID()
        newGroup.name = groupName.trimmingCharacters(in: .whitespaces)
        newGroup.currency = appState.preferredCurrency
        newGroup.createdDate = Date()
        newGroup.isActive = true
        
        // メンバーを追加
        for memberName in members {
            let member = GroupMember(context: viewContext)
            member.id = UUID()
            member.name = memberName
            member.createdDate = Date()
            member.isActive = true
            member.group = newGroup
        }
        
        do {
            try viewContext.save()
            appState.selectGroup(newGroup)
            currentStep = 2
        } catch {
            alertMessage = "グループの作成に失敗しました: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func createGroupAndDismiss() {
        completeOnboarding()
        dismiss()
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

struct QuickStartStepView<Content: View>: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, description: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // アイコン
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundColor(color)
                )
            
            // テキスト
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // コンテンツ
            content
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
