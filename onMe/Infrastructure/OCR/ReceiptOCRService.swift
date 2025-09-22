//
//  ReceiptOCRService.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import Foundation
import Vision
import UIKit

protocol ReceiptOCRServiceProtocol {
    func extractTextFromImage(_ image: UIImage) async throws -> OCRResult
    func extractAmountFromText(_ text: String) -> [Decimal]
}

struct OCRResult {
    let fullText: String
    let detectedAmounts: [Decimal]
    let confidence: Float
    let boundingBoxes: [CGRect]
}

class ReceiptOCRService: ReceiptOCRServiceProtocol {
    
    func extractTextFromImage(_ image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let fullText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                let detectedAmounts = self.extractAmountFromText(fullText)
                
                let confidence = observations.reduce(0.0) { result, observation in
                    result + (observation.topCandidates(1).first?.confidence ?? 0.0)
                } / Float(observations.count)
                
                let boundingBoxes = observations.compactMap { observation in
                    observation.boundingBox
                }
                
                let result = OCRResult(
                    fullText: fullText,
                    detectedAmounts: detectedAmounts,
                    confidence: confidence,
                    boundingBoxes: boundingBoxes
                )
                
                continuation.resume(returning: result)
            }
            
            // 日本語と英語の認識を有効化
            request.recognitionLanguages = ["ja-JP", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func extractAmountFromText(_ text: String) -> [Decimal] {
        var amounts: [Decimal] = []
        
        // 日本語の金額パターン（円、¥）
        let japanesePatterns = [
            #"¥[\s]*([0-9,]+)"#,
            #"([0-9,]+)[\s]*円"#,
            #"金額[\s]*:?[\s]*([0-9,]+)"#,
            #"合計[\s]*:?[\s]*([0-9,]+)"#,
            #"小計[\s]*:?[\s]*([0-9,]+)"#
        ]
        
        // 英語の金額パターン（$、USD等）
        let englishPatterns = [
            #"\$[\s]*([0-9,]+\.?[0-9]*)"#,
            #"([0-9,]+\.?[0-9]*)[\s]*USD"#,
            #"Total[\s]*:?[\s]*\$?([0-9,]+\.?[0-9]*)"#,
            #"Amount[\s]*:?[\s]*\$?([0-9,]+\.?[0-9]*)"#
        ]
        
        let allPatterns = japanesePatterns + englishPatterns
        
        for pattern in allPatterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let matches = regex?.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            
            for match in matches ?? [] {
                if match.numberOfRanges > 1 {
                    let range = match.range(at: 1)
                    if let swiftRange = Range(range, in: text) {
                        let amountString = String(text[swiftRange])
                            .replacingOccurrences(of: ",", with: "")
                            .replacingOccurrences(of: " ", with: "")
                        
                        if let decimal = Decimal(string: amountString) {
                            amounts.append(decimal)
                        }
                    }
                }
            }
        }
        
        // 重複を除去し、降順でソート
        return Array(Set(amounts)).sorted(by: >)
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return NSLocalizedString("ocr.error.invalidImage", value: "無効な画像です", comment: "")
        case .noTextFound:
            return NSLocalizedString("ocr.error.noTextFound", value: "テキストが見つかりませんでした", comment: "")
        case .processingFailed:
            return NSLocalizedString("ocr.error.processingFailed", value: "処理に失敗しました", comment: "")
        }
    }
}
