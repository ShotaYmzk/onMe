//
//  GroupMemberManagementView.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import SwiftUI
import CoreData

struct GroupMemberManagementView: View {
    let group: TravelGroup
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var newMemberName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var memberToDelete: GroupMember?
    @State private var showingDeleteConfirmation = false
    
    private var members: [GroupMember] {
        group.members?.allObjects
            .compactMap { $0 as? GroupMember }
            .filter { $0.isActive }
            .sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // メンバー追加セクション
                VStack(spacing: 16) {
                    HStack {
                        TextField("新しいメンバーの名前", text: $newMemberName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textInputAutocapitalization(.words)
                        
                        Button(action: addMember) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(newMemberName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Divider()
                }
                
                // メンバーリスト
                if members.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("メンバーがいません")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("上のフィールドから新しいメンバーを追加してください")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(members, id: \.id) { member in
                            MemberRowView(member: member) {
                                memberToDelete = member
                                showingDeleteConfirmation = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("メンバー管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("エラー", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .alert("メンバーを削除", isPresented: $showingDeleteConfirmation) {
                Button("削除", role: .destructive) {
                    if let member = memberToDelete {
                        deleteMember(member)
                    }
                }
                Button("キャンセル", role: .cancel) {
                    memberToDelete = nil
                }
            } message: {
                Text("「\(memberToDelete?.name ?? "")」を削除しますか？\n\nこの操作は元に戻せません。")
            }
        }
    }
    
    private func addMember() {
        let memberName = newMemberName.trimmingCharacters(in: .whitespaces)
        
        // 重複チェック
        if members.contains(where: { $0.name?.lowercased() == memberName.lowercased() }) {
            alertMessage = "同じ名前のメンバーが既に存在します"
            showingAlert = true
            return
        }
        
        let newMember = GroupMember(context: viewContext)
        newMember.id = UUID()
        newMember.name = memberName
        newMember.createdDate = Date()
        newMember.isActive = true
        newMember.group = group
        
        do {
            try viewContext.save()
            newMemberName = ""
        } catch {
            alertMessage = "メンバーの追加に失敗しました: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func deleteMember(_ member: GroupMember) {
        // 論理削除（isActive = false）
        member.isActive = false
        
        do {
            try viewContext.save()
            memberToDelete = nil
        } catch {
            alertMessage = "メンバーの削除に失敗しました: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

struct MemberRowView: View {
    let member: GroupMember
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // アバター
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(member.name?.prefix(1) ?? "?").uppercased())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name ?? "")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                if let createdDate = member.createdDate {
                    Text("追加日: \(createdDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.body)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    let group = TravelGroup()
    group.name = "サンプルグループ"
    
    return GroupMemberManagementView(group: group)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
