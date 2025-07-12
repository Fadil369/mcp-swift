import Foundation
import MCP
import Logging
import ServiceLifecycle

/// BrainSAIT MCP Configuration for healthcare applications
public struct BrainSAITConfiguration {
    /// Healthcare application identifier
    public let applicationName: String
    
    /// Version of the BrainSAIT integration
    public let version: String
    
    /// Supported languages (Arabic/English)
    public let supportedLanguages: [String]
    
    /// HIPAA compliance mode
    public let hipaaCompliant: Bool
    
    /// Encryption settings for healthcare data
    public let encryptionEnabled: Bool
    
    /// Logger configuration
    public let logLevel: Logger.Level
    
    public init(
        applicationName: String = "BrainSAIT-Healthcare",
        version: String = "1.0.0",
        supportedLanguages: [String] = ["ar", "en"],
        hipaaCompliant: Bool = true,
        encryptionEnabled: Bool = true,
        logLevel: Logger.Level = .info
    ) {
        self.applicationName = applicationName
        self.version = version
        self.supportedLanguages = supportedLanguages
        self.hipaaCompliant = hipaaCompliant
        self.encryptionEnabled = encryptionEnabled
        self.logLevel = logLevel
    }
}

/// Language detection and processing utilities for Arabic/English support
public struct LanguageProcessor {
    public enum Language: String, CaseIterable {
        case arabic = "ar"
        case english = "en"
        case unknown = "unknown"
    }
    
    /// Detect language from text input
    public static func detectLanguage(from text: String) -> Language {
        // Simple heuristic: check for Arabic Unicode range
        let arabicRange = "\u{0600}"..."\u{06FF}"
        let containsArabic = text.unicodeScalars.contains { arabicRange.contains($0) }
        
        if containsArabic {
            return .arabic
        } else if text.range(of: #"[a-zA-Z]"#, options: .regularExpression) != nil {
            return .english
        }
        
        return .unknown
    }
    
    /// Process text for RTL (Arabic) or LTR (English) display
    public static func processTextForDisplay(_ text: String, language: Language) -> String {
        switch language {
        case .arabic:
            // Add RTL markers for Arabic text
            return "\u{202E}" + text + "\u{202C}"
        case .english:
            // Ensure LTR for English text
            return "\u{202D}" + text + "\u{202C}"
        case .unknown:
            return text
        }
    }
}

/// Error types specific to BrainSAIT MCP operations
public enum BrainSAITMCPError: Swift.Error, LocalizedError {
    case invalidLanguage
    case hipaaViolation
    case encryptionRequired
    case medicalDataAccessDenied
    case unknownMedicalPrompt
    case arabicProcessingError
    case transportNotSupported
    
    public var errorDescription: String? {
        switch self {
        case .invalidLanguage:
            return "Unsupported language specified"
        case .hipaaViolation:
            return "HIPAA compliance violation detected"
        case .encryptionRequired:
            return "Encryption is required for healthcare data"
        case .medicalDataAccessDenied:
            return "Access to medical data denied"
        case .unknownMedicalPrompt:
            return "Unknown medical prompt requested"
        case .arabicProcessingError:
            return "Arabic text processing error occurred"
        case .transportNotSupported:
            return "Transport type not supported on this platform"
        }
    }
    
    /// Helper methods to create errors with additional context
    public static func invalidLanguage(_ details: String) -> BrainSAITMCPError {
        return .invalidLanguage
    }
    
    public static func hipaaViolation(_ details: String) -> BrainSAITMCPError {
        return .hipaaViolation
    }
    
    public static func unknownMedicalPrompt(_ prompt: String) -> BrainSAITMCPError {
        return .unknownMedicalPrompt
    }
    
    public static func arabicProcessingError(_ error: String) -> BrainSAITMCPError {
        return .arabicProcessingError
    }
    
    public static func transportNotSupported(_ details: String) -> BrainSAITMCPError {
        return .transportNotSupported
    }
}