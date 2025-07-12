import Foundation
import MCP
import Logging

/// BrainSAIT Healthcare MCP Client for connecting to medical AI services
public actor BrainSAITHealthcareClient {
    private let client: Client
    private let configuration: BrainSAITConfiguration
    private var logger: Logger
    
    public init(configuration: BrainSAITConfiguration) {
        self.configuration = configuration
        self.logger = Logger(label: "com.brainsait.mcp.client")
        self.logger.logLevel = configuration.logLevel
        
        self.client = Client(
            name: configuration.applicationName,
            version: configuration.version
        )
        
        logger.info("BrainSAIT Healthcare MCP Client initialized", metadata: [
            "application": .string(configuration.applicationName),
            "version": .string(configuration.version),
            "languages": .array(configuration.supportedLanguages.map { .string($0) })
        ])
    }
    
    /// Connect to the MCP server using the provided transport
    public func connect(transport: any Transport) async throws {
        try await client.connect(transport: transport)
        logger.info("Connected to MCP server")
    }
    
    /// Disconnect from the MCP server
    public func disconnect() async {
        await client.disconnect()
        logger.info("Disconnected from MCP server")
    }
    
    /// Get available medical prompts from the server
    public func getMedicalPrompts() async throws -> [String] {
        let prompts = try await client.listPrompts()
        let medicalPrompts = prompts.prompts.map { $0.name }
        
        logger.debug("Retrieved medical prompts", metadata: [
            "count": .stringConvertible(medicalPrompts.count)
        ])
        
        return medicalPrompts
    }
    
    /// Execute a medical consultation prompt with bilingual support
    public func executeMedicalConsultation(
        promptName: String,
        patientData: [String: Any],
        language: LanguageProcessor.Language = .english
    ) async throws -> String {
        
        // Validate HIPAA compliance
        guard configuration.hipaaCompliant else {
            throw BrainSAITMCPError.hipaaViolation("HIPAA compliance not enabled")
        }
        
        // Prepare arguments with language specification and convert to Value type
        var arguments: [String: Value] = [:]
        for (key, value) in patientData {
            if let stringValue = value as? String {
                arguments[key] = .string(stringValue)
            } else if let intValue = value as? Int {
                arguments[key] = .int(intValue)
            } else if let boolValue = value as? Bool {
                arguments[key] = .bool(boolValue)
            } else {
                arguments[key] = .string(String(describing: value))
            }
        }
        arguments["language"] = .string(language.rawValue)
        arguments["require_encryption"] = .bool(configuration.encryptionEnabled)
        
        let result = try await client.getPrompt(
            name: promptName,
            arguments: arguments
        )
        
        // Process the response based on language
        let description = result.description ?? "No response"
        let processedResponse = LanguageProcessor.processTextForDisplay(
            description,
            language: language
        )
        
        logger.info("Medical consultation completed", metadata: [
            "prompt": .string(promptName),
            "language": .string(language.rawValue),
            "patient_data_fields": .stringConvertible(patientData.keys.count)
        ])
        
        return processedResponse
    }
    
    /// Get medical resources (patient data, literature, etc.)
    public func getMedicalResources() async throws -> [Resource] {
        let resources = try await client.listResources()
        
        logger.debug("Retrieved medical resources", metadata: [
            "count": .stringConvertible(resources.resources.count)
        ])
        
        return resources.resources
    }
    
    /// Access specific medical resource with encryption validation
    public func accessMedicalResource(uri: String) async throws -> Data {
        guard configuration.encryptionEnabled else {
            throw BrainSAITMCPError.encryptionRequired
        }
        
        let resource = try await client.readResource(uri: uri)
        
        // Validate that we received content for medical data
        guard let contents = resource.contents.first else {
            throw BrainSAITMCPError.medicalDataAccessDenied
        }
        
        logger.info("Medical resource accessed", metadata: [
            "uri": .string(uri),
            "encrypted": .stringConvertible(configuration.encryptionEnabled)
        ])
        
        // Convert content to Data based on type
        if let textContent = contents.text {
            return Data(textContent.utf8)
        } else if let blobContent = contents.blob {
            return Data(base64Encoded: blobContent) ?? Data()
        }
        
        return Data()
    }
    
    /// Execute healthcare tools (drug interaction, symptom analysis, etc.)
    public func executeHealthcareTool(
        toolName: String,
        parameters: [String: Any],
        language: LanguageProcessor.Language = .english
    ) async throws -> String {
        
        // Add language and compliance parameters and convert to Value type
        var toolParameters: [String: Value] = [:]
        for (key, value) in parameters {
            if let stringValue = value as? String {
                toolParameters[key] = .string(stringValue)
            } else if let intValue = value as? Int {
                toolParameters[key] = .int(intValue)
            } else if let boolValue = value as? Bool {
                toolParameters[key] = .bool(boolValue)
            } else if let arrayValue = value as? [String] {
                toolParameters[key] = .array(arrayValue.map { .string($0) })
            } else {
                toolParameters[key] = .string(String(describing: value))
            }
        }
        toolParameters["language"] = .string(language.rawValue)
        toolParameters["hipaa_mode"] = .bool(configuration.hipaaCompliant)
        
        let result = try await client.callTool(
            name: toolName,
            arguments: toolParameters
        )
        
        // Process tool response for bilingual display
        let response = result.content.compactMap { content in
            switch content {
            case .text(let text):
                return text
            default:
                return nil
            }
        }.joined(separator: "\n")
        
        let processedResponse = LanguageProcessor.processTextForDisplay(
            response,
            language: language
        )
        
        logger.info("Healthcare tool executed", metadata: [
            "tool": .string(toolName),
            "language": .string(language.rawValue),
            "parameters": .stringConvertible(parameters.keys.count)
        ])
        
        return processedResponse
    }
    
    /// Get available healthcare tools
    public func getHealthcareTools() async throws -> [String] {
        let tools = try await client.listTools()
        let toolNames = tools.tools.map { $0.name }
        
        logger.debug("Retrieved healthcare tools", metadata: [
            "count": .stringConvertible(toolNames.count)
        ])
        
        return toolNames
    }
}