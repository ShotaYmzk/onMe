//
//  UnifiedHeaderView.swift
//  onMe
//
//  Created by 山﨑彰太 on 2025/09/24.
//

import SwiftUI

// MARK: - 統一ヘッダーコンポーネント
struct UnifiedHeaderView: View {
    let title: String
    let subtitle: String?
    let primaryAction: (() -> Void)?
    let primaryActionTitle: String?
    let primaryActionIcon: String?
    let showStatistics: Bool
    let statisticsData: HeaderStatistics?
    
    init(
        title: String,
        subtitle: String? = nil,
        primaryAction: (() -> Void)? = nil,
        primaryActionTitle: String? = nil,
        primaryActionIcon: String? = nil,
        showStatistics: Bool = false,
        statisticsData: HeaderStatistics? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.primaryAction = primaryAction
        self.primaryActionTitle = primaryActionTitle
        self.primaryActionIcon = primaryActionIcon
        self.showStatistics = showStatistics
        self.statisticsData = statisticsData
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // メインヘッダー部分
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // プライマリアクションボタン
                    if let action = primaryAction {
                        Button(action: action) {
                            HStack(spacing: 6) {
                                if let icon = primaryActionIcon {
                                    Image(systemName: icon)
                                        .font(.title3)
                                }
                                if let actionTitle = primaryActionTitle {
                                    Text(actionTitle)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                            .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // 統計情報（表示する場合）
                if showStatistics, let stats = statisticsData {
                    HStack(spacing: 20) {
                        ForEach(stats.items, id: \.id) { item in
                            UnifiedStatCardView(
                                title: item.title,
                                value: item.value,
                                icon: item.icon,
                                color: item.color
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 16)
            .background(
                LinearGradient(
                    colors: [
                        Color(UIColor.systemBackground),
                        Color(UIColor.secondarySystemBackground).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

// MARK: - ヘッダー統計データ構造
struct HeaderStatistics {
    let items: [StatItem]
    
    struct StatItem: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let icon: String
        let color: Color
    }
}

// MARK: - 統一されたStatCardView
struct UnifiedStatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 統一されたナビゲーションスタイル
struct UnifiedNavigationStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarHidden(true)
            .background(Color(UIColor.systemBackground))
    }
}

extension View {
    func unifiedNavigationStyle() -> some View {
        modifier(UnifiedNavigationStyle())
    }
}

// MARK: - 統一されたボタンスタイル
struct UnifiedPrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: isEnabled ? [.blue, .blue.opacity(0.8)] : [.gray, .gray.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(
                color: (isEnabled ? Color.blue : Color.gray).opacity(0.3),
                radius: 4,
                x: 0,
                y: 2
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .disabled(!isEnabled)
    }
}

struct UnifiedSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(Color.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 統一されたカラーパレット
extension Color {
    static let unifiedPrimary = Color(.systemBlue)
    static let unifiedSecondary = Color(.systemGreen)
    static let unifiedAccent = Color(.systemOrange)
    static let unifiedWarning = Color(.systemRed)
    
    static let unifiedBackground = Color(UIColor.systemBackground)
    static let unifiedSecondaryBackground = Color(UIColor.secondarySystemBackground)
    static let unifiedTertiaryBackground = Color(UIColor.tertiarySystemBackground)
}

// MARK: - 統一されたタイポグラフィ
extension Font {
    static let unifiedLargeTitle = Font.largeTitle.weight(.bold)
    static let unifiedTitle = Font.title.weight(.semibold)
    static let unifiedHeadline = Font.headline.weight(.semibold)
    static let unifiedSubheadline = Font.subheadline.weight(.medium)
    static let unifiedBody = Font.body
    static let unifiedCaption = Font.caption
}

// MARK: - 統一されたスペーシング
enum UnifiedSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
}

// MARK: - 統一されたコーナーラジウス
enum UnifiedCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 20
}

// MARK: - プレビュー
#Preview {
    VStack {
        UnifiedHeaderView(
            title: "onMe",
            subtitle: "旅行の割り勘を簡単に",
            primaryAction: { },
            primaryActionTitle: "作成",
            primaryActionIcon: "plus.circle.fill",
            showStatistics: true,
            statisticsData: HeaderStatistics(items: [
                HeaderStatistics.StatItem(
                            title: "グループ数",
                            value: "3",
                            icon: "person.3.fill",
                            color: Color.blue
                        ),
                        HeaderStatistics.StatItem(
                            title: "総支出",
                            value: "¥15,000",
                            icon: "creditcard.fill",
                            color: Color.green
                )
            ])
        )
        
        Spacer()
    }
    .background(Color(UIColor.systemBackground))
}
