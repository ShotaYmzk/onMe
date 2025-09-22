//
//  GroupSharingView.swift
//  onMe
//
//  Created by AI Assistant on 2025/09/22.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct GroupSharingView: View {
    let group: TravelGroup
    @Environment(\.dismiss) private var dismiss
    @State private var shareURL = ""
    @State private var qrCodeImage: UIImage?
    @State private var showingShareSheet = false
    @State private var showingCopiedAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // ヘッダー情報
                    VStack(spacing: 16) {
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(spacing: 8) {
                            Text(group.name ?? "グループ")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("メンバーをグループに招待")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // QRコード
                    VStack(spacing: 16) {
                        Text("QRコードをスキャン")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if let qrCodeImage = qrCodeImage {
                            Image(uiImage: qrCodeImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 200, height: 200)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(1.5)
                                )
                        }
                        
                        Text("カメラでQRコードを読み取ってグループに参加")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // リンク共有
                    VStack(spacing: 16) {
                        Text("または、リンクを共有")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Text(shareURL)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                            
                            Button(action: copyToClipboard) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption)
                                    Text("コピー")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // 共有オプション
                    VStack(spacing: 16) {
                        Button(action: { showingShareSheet = true }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title3)
                                Text("他のアプリで共有")
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
                            .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        
                        HStack(spacing: 16) {
                            ShareOptionButton(
                                title: "LINE",
                                icon: "message.fill",
                                color: .green,
                                action: shareViaLine
                            )
                            
                            ShareOptionButton(
                                title: "メール",
                                icon: "envelope.fill",
                                color: .orange,
                                action: shareViaEmail
                            )
                            
                            ShareOptionButton(
                                title: "SMS",
                                icon: "message.circle.fill",
                                color: .blue,
                                action: shareViaSMS
                            )
                        }
                    }
                    
                    // 注意事項
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ご注意")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(
                                icon: "lock.shield.fill",
                                text: "招待リンクは24時間有効です"
                            )
                            
                            InfoRow(
                                icon: "person.badge.plus",
                                text: "最大20人まで招待できます"
                            )
                            
                            InfoRow(
                                icon: "eye.slash.fill",
                                text: "グループ管理者のみが招待できます"
                            )
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("グループを共有")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [shareURL])
            }
            .alert("コピーしました", isPresented: $showingCopiedAlert) {
                Button("OK") { }
            } message: {
                Text("招待リンクをクリップボードにコピーしました")
            }
        }
        .onAppear {
            generateShareURL()
            generateQRCode()
        }
    }
    
    private func generateShareURL() {
        // 実際の実装では、サーバーサイドでユニークなURLを生成
        let groupId = group.id?.uuidString ?? UUID().uuidString
        shareURL = "https://onme.app/join/\(groupId)"
    }
    
    private func generateQRCode() {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(shareURL.utf8)
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrCodeImage = UIImage(cgImage: cgImage)
            }
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = shareURL
        showingCopiedAlert = true
    }
    
    private func shareViaLine() {
        let text = "「\(group.name ?? "グループ")」に招待されました！\n\n\(shareURL)"
        if let url = URL(string: "line://msg/text/\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareViaEmail() {
        let subject = "「\(group.name ?? "グループ")」への招待"
        let body = """
        こんにちは！
        
        「\(group.name ?? "グループ")」にあなたを招待しました。
        以下のリンクをタップしてグループに参加してください。
        
        \(shareURL)
        
        onMeアプリで旅行の支出を一緒に管理しましょう！
        """
        
        if let url = URL(string: "mailto:?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareViaSMS() {
        let text = "「\(group.name ?? "グループ")」に招待されました！\n\(shareURL)"
        if let url = URL(string: "sms:&body=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }
}

struct ShareOptionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(color)
                    )
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let group = TravelGroup(context: context)
    group.id = UUID()
    group.name = "沖縄旅行"
    group.currency = "JPY"
    group.createdDate = Date()
    
    return GroupSharingView(group: group)
}
