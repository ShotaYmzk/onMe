//
//  DataEncryption.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import Foundation
import CryptoKit
import LocalAuthentication

protocol DataEncryptionProtocol {
    func encryptData(_ data: Data) throws -> Data
    func decryptData(_ encryptedData: Data) throws -> Data
    func encryptString(_ string: String) throws -> Data
    func decryptString(_ encryptedData: Data) throws -> String
}

class DataEncryption: DataEncryptionProtocol {
    private let keychain = KeychainManager()
    
    private var encryptionKey: SymmetricKey {
        get throws {
            if let keyData = keychain.getEncryptionKey() {
                return SymmetricKey(data: keyData)
            } else {
                let newKey = SymmetricKey(size: .bits256)
                let keyData = newKey.withUnsafeBytes { Data($0) }
                keychain.saveEncryptionKey(keyData)
                return newKey
            }
        }
    }
    
    func encryptData(_ data: Data) throws -> Data {
        let key = try encryptionKey
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    func decryptData(_ encryptedData: Data) throws -> Data {
        let key = try encryptionKey
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    func encryptString(_ string: String) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.invalidInput
        }
        return try encryptData(data)
    }
    
    func decryptString(_ encryptedData: Data) throws -> String {
        let decryptedData = try decryptData(encryptedData)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.invalidOutput
        }
        return string
    }
}

enum EncryptionError: LocalizedError {
    case keyGenerationFailed
    case encryptionFailed
    case decryptionFailed
    case invalidInput
    case invalidOutput
    
    var errorDescription: String? {
        switch self {
        case .keyGenerationFailed:
            return "暗号化キーの生成に失敗しました"
        case .encryptionFailed:
            return "データの暗号化に失敗しました"
        case .decryptionFailed:
            return "データの復号化に失敗しました"
        case .invalidInput:
            return "無効な入力データです"
        case .invalidOutput:
            return "無効な出力データです"
        }
    }
}

class KeychainManager {
    private let service = "com.travelsettle.encryption"
    private let account = "encryptionKey"
    
    func saveEncryptionKey(_ keyData: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // 既存のアイテムを削除
        SecItemDelete(query as CFDictionary)
        
        // 新しいアイテムを追加
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Keychain save error: \(status)")
        }
    }
    
    func getEncryptionKey() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        } else {
            return nil
        }
    }
    
    func deleteEncryptionKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Biometric Authentication
class BiometricAuthenticationManager {
    private let context = LAContext()
    
    func isBiometricAvailable() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func authenticateWithBiometrics() async throws -> Bool {
        let reason = "TravelSettleのデータにアクセスするために認証が必要です"
        
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                if success {
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(throwing: error ?? BiometricError.authenticationFailed)
                }
            }
        }
    }
    
    func getBiometricType() -> LABiometryType {
        var error: NSError?
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return context.biometryType
    }
}

enum BiometricError: LocalizedError {
    case notAvailable
    case authenticationFailed
    case userCancel
    case userFallback
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "生体認証が利用できません"
        case .authenticationFailed:
            return "認証に失敗しました"
        case .userCancel:
            return "ユーザーによってキャンセルされました"
        case .userFallback:
            return "パスコード認証にフォールバックしました"
        }
    }
}
