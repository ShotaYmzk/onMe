//
//  ImageCache.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import UIKit
import Combine

protocol ImageCacheProtocol {
    func getImage(for key: String) -> UIImage?
    func setImage(_ image: UIImage, for key: String)
    func removeImage(for key: String)
    func clearCache()
    func getCacheSize() -> Int64
}

class ImageCache: ImageCacheProtocol {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let diskCache: DiskImageCache
    private let maxMemoryCacheSize: Int = 50 * 1024 * 1024 // 50MB
    private let maxDiskCacheSize: Int64 = 200 * 1024 * 1024 // 200MB
    
    private init() {
        self.diskCache = DiskImageCache()
        setupCache()
        observeMemoryWarnings()
    }
    
    private func setupCache() {
        cache.totalCostLimit = maxMemoryCacheSize
        cache.countLimit = 100
    }
    
    private func observeMemoryWarnings() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.cache.removeAllObjects()
        }
    }
    
    func getImage(for key: String) -> UIImage? {
        let nsKey = NSString(string: key)
        
        // メモリキャッシュから取得を試行
        if let image = cache.object(forKey: nsKey) {
            return image
        }
        
        // ディスクキャッシュから取得を試行
        if let image = diskCache.getImage(for: key) {
            // メモリキャッシュに保存
            let cost = image.jpegData(compressionQuality: 0.8)?.count ?? 0
            cache.setObject(image, forKey: nsKey, cost: cost)
            return image
        }
        
        return nil
    }
    
    func setImage(_ image: UIImage, for key: String) {
        let nsKey = NSString(string: key)
        let cost = image.jpegData(compressionQuality: 0.8)?.count ?? 0
        
        // メモリキャッシュに保存
        cache.setObject(image, forKey: nsKey, cost: cost)
        
        // ディスクキャッシュに非同期で保存
        Task {
            await diskCache.setImage(image, for: key)
        }
    }
    
    func removeImage(for key: String) {
        cache.removeObject(forKey: NSString(string: key))
        Task {
            await diskCache.removeImage(for: key)
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
        Task {
            await diskCache.clearCache()
        }
    }
    
    func getCacheSize() -> Int64 {
        return diskCache.getCacheSize()
    }
}

class DiskImageCache {
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.travelsettle.diskcache", qos: .utility)
    
    init() {
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cacheDir.appendingPathComponent("ImageCache")
        
        createCacheDirectoryIfNeeded()
    }
    
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    private func fileURL(for key: String) -> URL {
        let hashedKey = key.sha256
        return cacheDirectory.appendingPathComponent(hashedKey)
    }
    
    func getImage(for key: String) -> UIImage? {
        let fileURL = fileURL(for: key)
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        // ファイルのアクセス時間を更新（LRU用）
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: fileURL.path)
        
        return image
    }
    
    func setImage(_ image: UIImage, for key: String) async {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let fileURL = fileURL(for: key)
        
        await withCheckedContinuation { continuation in
            queue.async {
                try? data.write(to: fileURL)
                continuation.resume()
            }
        }
        
        // キャッシュサイズをチェックし、必要に応じてクリーンアップ
        await cleanupIfNeeded()
    }
    
    func removeImage(for key: String) async {
        let fileURL = fileURL(for: key)
        
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                try? self?.fileManager.removeItem(at: fileURL)
                continuation.resume()
            }
        }
    }
    
    func clearCache() async {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                try? self.fileManager.removeItem(at: self.cacheDirectory)
                self.createCacheDirectoryIfNeeded()
                continuation.resume()
            }
        }
    }
    
    func getCacheSize() -> Int64 {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = resourceValues.fileSize {
                totalSize += Int64(fileSize)
            }
        }
        
        return totalSize
    }
    
    private func cleanupIfNeeded() async {
        let currentSize = getCacheSize()
        let maxSize: Int64 = 200 * 1024 * 1024 // 200MB
        
        if currentSize > maxSize {
            await performCleanup(targetSize: maxSize * 3 / 4) // 75%まで削減
        }
    }
    
    private func performCleanup(targetSize: Int64) async {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                // ファイルを最終アクセス時間順にソート
                guard let enumerator = self.fileManager.enumerator(
                    at: self.cacheDirectory,
                    includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
                ) else {
                    continuation.resume()
                    return
                }
                
                var files: [(URL, Date, Int64)] = []
                
                for case let fileURL as URL in enumerator {
                    if let resourceValues = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
                       let modificationDate = resourceValues.contentModificationDate,
                       let fileSize = resourceValues.fileSize {
                        files.append((fileURL, modificationDate, Int64(fileSize)))
                    }
                }
                
                // 古いファイルから順にソート
                files.sort { $0.1 < $1.1 }
                
                var currentSize = files.reduce(0) { $0 + $1.2 }
                
                // targetSizeになるまでファイルを削除
                for file in files {
                    if currentSize <= targetSize { break }
                    
                    try? self.fileManager.removeItem(at: file.0)
                    currentSize -= file.2
                }
                
                continuation.resume()
            }
        }
    }
}

extension String {
    var sha256: String {
        let data = self.data(using: .utf8)!
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

import CryptoKit

extension SHA256.Digest {
    var hexString: String {
        return self.compactMap { String(format: "%02x", $0) }.joined()
    }
}
