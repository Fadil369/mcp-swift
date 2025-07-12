import Foundation
import ArgumentParser
import BrainSAITMCP
import Logging
import ServiceLifecycle

/// BrainSAIT Healthcare MCP Server - Production deployment executable
@main
struct BrainSAITHealthcareServerCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "brainsait-healthcare-server",
        abstract: "BrainSAIT Healthcare MCP Server for medical AI services",
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
    
    @Option(name: .long, help: "Supported languages (comma-separated)")
    var languages: String = "en,ar"
    
    @Option(name: .long, help: "Application name")
    var applicationName: String = "BrainSAIT-Healthcare-Server"
    
    func run() async throws {
        // Configure logging
        let logger = Logger(label: "com.brainsait.mcp.server.main")
        
        let parsedLogLevel = Logger.Level(rawValue: logLevel) ?? .info
        LoggingSystem.bootstrap { _ in
            var handler = StreamLogHandler.standardOutput(label: $0)
            handler.logLevel = parsedLogLevel
            return handler
        }
        
        // Parse configuration
        let supportedLanguages = languages.split(separator: ",").map(String.init)
        
        let configuration = BrainSAITConfiguration(
            applicationName: applicationName,
            version: "1.0.0",
            supportedLanguages: supportedLanguages,
            hipaaCompliant: hipaaCompliant,
            encryptionEnabled: encryption,
            logLevel: parsedLogLevel
        )
        
        logger.info("Starting BrainSAIT Healthcare MCP Server", metadata: [
            "host": .string(host),
            "port": .stringConvertible(port),
            "transport": .string(transport),
            "hipaa_mode": .stringConvertible(hipaaCompliant),
            "encryption": .stringConvertible(encryption),
            "languages": .string(languages)
        ])
        
        // Create transport
        let transportType = try parseTransportType()
        let mcpTransport = try BrainSAITTransportFactory.createTransport(
            type: transportType,
            configuration: configuration
        )
        
        // Validate transport security for healthcare
        try TransportConfiguration.validateTransportSecurity(
            type: transportType,
            configuration: configuration
        )
        
        // Create and configure server
        let server = BrainSAITHealthcareServer(
            configuration: configuration
        )
        
        // Setup service lifecycle for production deployment
        let serviceGroup = ServiceGroup(
            configuration: ServiceGroupConfiguration(
                services: [
                    .init(service: HealthcareServerService(server: server, transport: mcpTransport), successTerminationBehavior: .ignore)
                ],
                gracefulShutdownSignals: [.sigterm, .sigint],
                logger: logger
            )
        )
        
        do {
            try await serviceGroup.run()
        } catch {
            logger.error("Server error", metadata: ["error": .string(error.localizedDescription)])
            throw error
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
}

/// Service wrapper for healthcare server
actor HealthcareServerService: Service {
    private let server: BrainSAITHealthcareServer
    private let transport: any Transport
    private let logger = Logger(label: "com.brainsait.mcp.server.service")
    
    init(server: BrainSAITHealthcareServer, transport: any Transport) {
        self.server = server
        self.transport = transport
    }
    
    func run() async throws {
        logger.info("Healthcare server service starting")
        try await server.start(transport: transport)
        
        // Keep the service running
        try await Task.sleep(for: .seconds(Double.greatestFiniteMagnitude))
    }
    
    func gracefulShutdown() async {
        logger.info("Healthcare server service shutting down gracefully")
        await server.stop()
    }
}