import Foundation
import ArgumentParser
import BrainSAITMCP
import Logging

/// BrainSAIT MCP Client - Command-line client for healthcare AI services
@main
struct BrainSAITClientCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "brainsait-client",
        abstract: "BrainSAIT MCP Client for connecting to healthcare AI services",
        version: "1.0.0"
    )
    
    @Option(name: .long, help: "Server host address")
    var host: String = "localhost"
    
    @Option(name: .long, help: "Server port number")
    var port: Int = 8080
    
    @Option(name: .long, help: "Transport type (stdio, http, network, cloudflare)")
    var transport: String = "stdio"
    
    @Option(name: .long, help: "Cloudflare Worker URL (for cloudflare transport)")
    var cloudflareURL: String?
    
    @Option(name: .long, help: "Cloudflare API token (for cloudflare transport)")
    var cloudflareToken: String?
    
    @Option(name: .long, help: "Log level (trace, debug, info, notice, warning, error, critical)")
    var logLevel: String = "info"
    
    @Flag(name: .long, help: "Enable HIPAA compliance mode")
    var hipaaCompliant: Bool = false
    
    @Flag(name: .long, help: "Enable encryption for healthcare data")
    var encryption: Bool = false
    
    @Option(name: .long, help: "Language preference (ar, en)")
    var language: String = "en"
    
    @Option(name: .long, help: "Application name")
    var applicationName: String = "BrainSAIT-Client"
    
    // Command-specific options
    @Option(name: .long, help: "Command to execute (list-prompts, list-tools, list-resources, consult, analyze)")
    var command: String?
    
    @Option(name: .long, help: "Prompt name for consultation")
    var promptName: String?
    
    @Option(name: .long, help: "Tool name for analysis")
    var toolName: String?
    
    @Option(name: .long, help: "Patient symptoms (for consultation)")
    var symptoms: String?
    
    @Option(name: .long, help: "Medical history (for consultation)")
    var history: String?
    
    @Option(name: .long, help: "Medications list (comma-separated)")
    var medications: String?
    
    @Option(name: .long, help: "Patient age")
    var age: Int?
    
    func run() async throws {
        // Configure logging
        let parsedLogLevel = Logger.Level(rawValue: logLevel) ?? .info
        LoggingSystem.bootstrap { _ in
            var handler = StreamLogHandler.standardOutput(label: $0)
            handler.logLevel = parsedLogLevel
            return handler
        }
        
        let logger = Logger(label: "com.brainsait.mcp.client.main")
        
        // Parse configuration
        let configuration = BrainSAITConfiguration(
            applicationName: applicationName,
            version: "1.0.0",
            supportedLanguages: ["en", "ar"],
            hipaaCompliant: hipaaCompliant,
            encryptionEnabled: encryption,
            logLevel: parsedLogLevel
        )
        
        logger.info("Starting BrainSAIT MCP Client", metadata: [
            "host": .string(host),
            "port": .stringConvertible(port),
            "transport": .string(transport),
            "language": .string(language),
            "hipaa_mode": .stringConvertible(hipaaCompliant)
        ])
        
        // Create transport
        let transportType = try parseTransportType()
        let mcpTransport = try BrainSAITTransportFactory.createTransport(
            type: transportType,
            configuration: configuration
        )
        
        // Create client
        let client = BrainSAITHealthcareClient(
            configuration: configuration
        )
        
        // Connect to server
        try await client.connect(transport: mcpTransport)
        defer {
            Task {
                await client.disconnect()
            }
        }
        
        // Execute command
        if let command = command {
            try await executeCommand(command, client: client, logger: logger)
        } else {
            try await runInteractiveMode(client: client, logger: logger)
        }
    }
    
    private func parseTransportType() throws -> BrainSAITTransportFactory.TransportType {
        switch transport.lowercased() {
        case "stdio":
            return .stdio
            
        case "http":
            let url = URL(string: "http://\(host):\(port)")!
            return .http(url: url)
            
        case "network":
            return .network(host: host, port: port)
            
        case "cloudflare":
            guard let urlString = cloudflareURL,
                  let url = URL(string: urlString),
                  let token = cloudflareToken else {
                throw ValidationError("Cloudflare transport requires --cloudflare-url and --cloudflare-token")
            }
            return .cloudflare(workerURL: url, apiToken: token)
            
        default:
            throw ValidationError("Unknown transport type: \(transport)")
        }
    }
    
    private func executeCommand(_ command: String, client: BrainSAITHealthcareClient, logger: Logger) async throws {
        let lang = LanguageProcessor.Language(rawValue: language) ?? .english
        
        switch command.lowercased() {
        case "list-prompts":
            let prompts = try await client.getMedicalPrompts()
            print("Available Medical Prompts:")
            for prompt in prompts {
                print("  - \(prompt)")
            }
            
        case "list-tools":
            let tools = try await client.getHealthcareTools()
            print("Available Healthcare Tools:")
            for tool in tools {
                print("  - \(tool)")
            }
            
        case "list-resources":
            let resources = try await client.getMedicalResources()
            print("Available Medical Resources:")
            for resource in resources {
                print("  - \(resource.name): \(resource.description ?? "No description")")
            }
            
        case "consult":
            guard let promptName = promptName else {
                throw ValidationError("Consultation requires --prompt-name")
            }
            
            var patientData: [String: Any] = [:]
            if let symptoms = symptoms {
                patientData["patient_symptoms"] = symptoms
            }
            if let history = history {
                patientData["medical_history"] = history
            }
            
            let result = try await client.executeMedicalConsultation(
                promptName: promptName,
                patientData: patientData,
                language: lang
            )
            
            print("\nMedical Consultation Result:")
            print(result)
            
        case "analyze":
            guard let toolName = toolName else {
                throw ValidationError("Analysis requires --tool-name")
            }
            
            var parameters: [String: Any] = [:]
            
            if toolName == "drug-interaction-checker" {
                if let medications = medications {
                    parameters["medications"] = medications.split(separator: ",").map(String.init)
                }
                if let age = age {
                    parameters["patient_age"] = age
                }
            } else if toolName == "symptom-analyzer" {
                if let symptoms = symptoms {
                    parameters["symptoms"] = symptoms.split(separator: ",").map(String.init)
                }
                parameters["duration"] = "1 week"
                parameters["severity"] = 5
            }
            
            let result = try await client.executeHealthcareTool(
                toolName: toolName,
                parameters: parameters,
                language: lang
            )
            
            print("\nHealthcare Tool Analysis:")
            print(result)
            
        default:
            throw ValidationError("Unknown command: \(command)")
        }
    }
    
    private func runInteractiveMode(client: BrainSAITHealthcareClient, logger: Logger) async throws {
        print("🏥 BrainSAIT Healthcare MCP Client - Interactive Mode")
        print("Type 'help' for available commands, 'quit' to exit")
        print("Language: \(language == "ar" ? "العربية" : "English")")
        print()
        
        while true {
            print("brainsait> ", terminator: "")
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                continue
            }
            
            if input.isEmpty {
                continue
            }
            
            if input == "quit" || input == "exit" {
                break
            }
            
            if input == "help" {
                showHelp()
                continue
            }
            
            do {
                try await processInteractiveCommand(input, client: client, logger: logger)
            } catch {
                print("❌ Error: \(error.localizedDescription)")
            }
        }
        
        print("Goodbye! وداعاً")
    }
    
    private func processInteractiveCommand(_ input: String, client: BrainSAITHealthcareClient, logger: Logger) async throws {
        let lang = LanguageProcessor.Language(rawValue: language) ?? .english
        let parts = input.split(separator: " ", maxSplits: 1).map(String.init)
        
        guard let command = parts.first else { return }
        
        switch command.lowercased() {
        case "prompts":
            let prompts = try await client.getMedicalPrompts()
            print("📋 Available Medical Prompts:")
            for (index, prompt) in prompts.enumerated() {
                print("  \(index + 1). \(prompt)")
            }
            
        case "tools":
            let tools = try await client.getHealthcareTools()
            print("🔧 Available Healthcare Tools:")
            for (index, tool) in tools.enumerated() {
                print("  \(index + 1). \(tool)")
            }
            
        case "resources":
            let resources = try await client.getMedicalResources()
            print("📚 Available Medical Resources:")
            for (index, resource) in resources.enumerated() {
                print("  \(index + 1). \(resource.name)")
            }
            
        case "drug-check":
            print("💊 Drug Interaction Checker")
            print("Enter medications (comma-separated): ", terminator: "")
            guard let medicationsInput = readLine() else { return }
            
            print("Enter patient age: ", terminator: "")
            guard let ageInput = readLine(), let patientAge = Int(ageInput) else { return }
            
            let result = try await client.executeHealthcareTool(
                toolName: "drug-interaction-checker",
                parameters: [
                    "medications": medicationsInput.split(separator: ",").map(String.init),
                    "patient_age": patientAge
                ],
                language: lang
            )
            
            print("\n📊 Analysis Result:")
            print(result)
            
        case "symptom-check":
            print("🩺 Symptom Analyzer")
            print("Enter symptoms (comma-separated): ", terminator: "")
            guard let symptomsInput = readLine() else { return }
            
            let result = try await client.executeHealthcareTool(
                toolName: "symptom-analyzer",
                parameters: [
                    "symptoms": symptomsInput.split(separator: ",").map(String.init),
                    "duration": "recent",
                    "severity": 5
                ],
                language: lang
            )
            
            print("\n📊 Analysis Result:")
            print(result)
            
        default:
            print("❓ Unknown command: \(command)")
            print("Type 'help' for available commands")
        }
    }
    
    private func showHelp() {
        print("""
        📚 BrainSAIT Healthcare MCP Client Commands:
        
        General Commands:
          help          - Show this help message
          quit/exit     - Exit the client
          
        Healthcare Commands:
          prompts       - List available medical prompts
          tools         - List available healthcare tools
          resources     - List available medical resources
          drug-check    - Check drug interactions
          symptom-check - Analyze symptoms
          
        Language Support:
          Current language: \(language == "ar" ? "العربية (Arabic)" : "English")
          Use --language ar for Arabic or --language en for English
        """)
    }
}