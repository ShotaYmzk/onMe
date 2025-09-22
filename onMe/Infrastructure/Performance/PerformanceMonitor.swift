//
//  PerformanceMonitor.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import Foundation
import UIKit
import Combine

protocol PerformanceMonitorProtocol {
    func startMonitoring()
    func stopMonitoring()
    func logEvent(_ event: String, duration: TimeInterval)
    func logMemoryUsage()
    func getCurrentMemoryUsage() -> UInt64
}

class PerformanceMonitor: PerformanceMonitorProtocol {
    static let shared = PerformanceMonitor()
    
    private var isMonitoring = false
    private var memoryTimer: Timer?
    private var performanceMetrics: [PerformanceMetric] = []
    private let maxMetricsCount = 1000
    
    private init() {}
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        startMemoryMonitoring()
        observeAppStateChanges()
        
        print("📊 PerformanceMonitor started")
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        memoryTimer?.invalidate()
        memoryTimer = nil
        
        print("📊 PerformanceMonitor stopped")
    }
    
    private func startMemoryMonitoring() {
        memoryTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.logMemoryUsage()
        }
    }
    
    private func observeAppStateChanges() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.logEvent("App_DidEnterBackground", duration: 0)
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.logEvent("App_WillEnterForeground", duration: 0)
        }
    }
    
    func logEvent(_ event: String, duration: TimeInterval) {
        guard isMonitoring else { return }
        
        let metric = PerformanceMetric(
            event: event,
            duration: duration,
            memoryUsage: getCurrentMemoryUsage(),
            timestamp: Date()
        )
        
        performanceMetrics.append(metric)
        
        // メトリクス数を制限
        if performanceMetrics.count > maxMetricsCount {
            performanceMetrics.removeFirst(performanceMetrics.count - maxMetricsCount)
        }
        
        // 重要なイベントをログ出力
        if duration > 1.0 || event.contains("Error") {
            print("⚠️ Performance Alert: \(event) took \(String(format: "%.3f", duration))s")
        }
        
        // メモリ使用量が多い場合の警告
        let memoryMB = Double(getCurrentMemoryUsage()) / 1024 / 1024
        if memoryMB > 100 {
            print("⚠️ Memory Alert: \(String(format: "%.1f", memoryMB))MB used")
        }
    }
    
    func logMemoryUsage() {
        let usage = getCurrentMemoryUsage()
        let usageMB = Double(usage) / 1024 / 1024
        
        if usageMB > 80 { // 80MB以上で警告
            print("📱 Memory Usage: \(String(format: "%.1f", usageMB))MB")
        }
    }
    
    func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
    
    func getPerformanceReport() -> PerformanceReport {
        let totalEvents = performanceMetrics.count
        let averageDuration = performanceMetrics.isEmpty ? 0 : performanceMetrics.reduce(0) { $0 + $1.duration } / Double(totalEvents)
        let maxMemoryUsage = performanceMetrics.max(by: { $0.memoryUsage < $1.memoryUsage })?.memoryUsage ?? 0
        let slowEvents = performanceMetrics.filter { $0.duration > 1.0 }
        
        return PerformanceReport(
            totalEvents: totalEvents,
            averageDuration: averageDuration,
            maxMemoryUsage: maxMemoryUsage,
            slowEventsCount: slowEvents.count,
            recentMetrics: Array(performanceMetrics.suffix(10))
        )
    }
    
    func clearMetrics() {
        performanceMetrics.removeAll()
    }
}

struct PerformanceMetric {
    let event: String
    let duration: TimeInterval
    let memoryUsage: UInt64
    let timestamp: Date
}

struct PerformanceReport {
    let totalEvents: Int
    let averageDuration: TimeInterval
    let maxMemoryUsage: UInt64
    let slowEventsCount: Int
    let recentMetrics: [PerformanceMetric]
}

// MARK: - Performance Measurement Utilities
extension PerformanceMonitor {
    func measureTime<T>(for operation: String, _ block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        logEvent(operation, duration: timeElapsed)
        return result
    }
    
    func measureTimeAsync<T>(for operation: String, _ block: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        logEvent(operation, duration: timeElapsed)
        return result
    }
}

// MARK: - SwiftUI Performance Helpers
import SwiftUI

struct PerformanceMeasuredView<Content: View>: View {
    let content: Content
    let operationName: String
    
    init(operationName: String, @ViewBuilder content: () -> Content) {
        self.operationName = operationName
        self.content = content()
    }
    
    var body: some View {
        content
            .onAppear {
                PerformanceMonitor.shared.logEvent("\(operationName)_ViewAppeared", duration: 0)
            }
            .onDisappear {
                PerformanceMonitor.shared.logEvent("\(operationName)_ViewDisappeared", duration: 0)
            }
    }
}

// MARK: - Core Data Performance Extensions
import CoreData

extension NSManagedObjectContext {
    func performAndMeasure<T>(_ operation: String, _ block: () throws -> T) rethrows -> T {
        return try PerformanceMonitor.shared.measureTime(for: "CoreData_\(operation)") {
            try block()
        }
    }
    
    func performAndMeasureAsync<T>(_ operation: String, _ block: () async throws -> T) async rethrows -> T {
        return try await PerformanceMonitor.shared.measureTimeAsync(for: "CoreData_\(operation)") {
            try await block()
        }
    }
}
