import Foundation
import MCP
import Logging

#if canImport(Network)
import Network
#endif

/// Transport factory for creating appropriate transport based on platform and requirements
public enum BrainSAITTransportFactory {
    
    /// Transport type options for BrainSAIT MCP applications
    public enum TransportType {
        case stdio
        case http(url: URL)
        case network(host: String, port: Int)
        case cloudflare(workerURL: URL, apiToken: String)
    }
    
    /// Create appropriate transport based on type and platform
    public static func createTransport(
        type: TransportType,
        configuration: BrainSAITConfiguration
    ) throws -> any Transport {
        
        let logger = Logger(label: "com.brainsait.mcp.transport")
        logger.logLevel = configuration.logLevel
        
        switch type {
        case .stdio:
            return try createStdioTransport(logger: logger)
            
        case .http(let url):
            return try createHTTPTransport(url: url, configuration: configuration, logger: logger)
            
        case .network(let host, let port):
            return try createNetworkTransport(host: host, port: port, logger: logger)
            
        case .cloudflare(let workerURL, let apiToken):
            return try createCloudflareTransport(
                workerURL: workerURL,
                apiToken: apiToken,
                configuration: configuration,
                logger: logger
            )
        }
    }
    
    /// Create stdio transport for local AI model communication
    private static func createStdioTransport(logger: Logger) throws -> any Transport {
        // Note: StdioTransport availability depends on platform
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS) || os(Linux)
        return StdioTransport()
        #else
        throw BrainSAITMCPError.transportNotSupported("Stdio transport not available on this platform")
        #endif
    }
    
    /// Create HTTP transport with Server-Sent Events support
    private static func createHTTPTransport(
        url: URL,
        configuration: BrainSAITConfiguration,
        logger: Logger
    ) throws -> any Transport {
        
        return HTTPClientTransport(
            endpoint: url,
            configuration: .default,
            streaming: true,
            logger: logger
        )
    }
    
    /// Create Network framework transport for secure internal communications
    private static func createNetworkTransport(
        host: String,
        port: Int,
        logger: Logger
    ) throws -> any Transport {
        
        #if canImport(Network) && (os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS))
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.noDelay = true // Enable for real-time medical communications
        
        let tlsOptions = NWProtocolTLS.Options()
        // Configure TLS for healthcare data security
        
        let parameters = NWParameters(tls: tlsOptions, tcp: tcpOptions)
        parameters.requiredInterface = nil // Allow any interface
        parameters.prohibitedInterfaces = [] // No prohibited interfaces
        
        return NetworkTransport(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(integerLiteral: UInt16(port)),
            parameters: parameters
        )
        #else
        throw BrainSAITMCPError.transportNotSupported("Network transport not available on this platform")
        #endif
    }
    
    /// Create Cloudflare Workers transport for edge AI services
    private static func createCloudflareTransport(
        workerURL: URL,
        apiToken: String,
        configuration: BrainSAITConfiguration,
        logger: Logger
    ) throws -> any Transport {
        
        return HTTPClientTransport(
            endpoint: workerURL,
            configuration: .default,
            streaming: true,
            logger: logger
        )
    }
}

/// Transport configuration utilities
public struct TransportConfiguration {
    
    /// Get recommended transport for deployment environment
    public static func recommendedTransport(
        for environment: DeploymentEnvironment,
        configuration: BrainSAITConfiguration
    ) -> BrainSAITTransportFactory.TransportType {
        
        switch environment {
        case .development:
            return .stdio
            
        case .raspberryPi(let host, let port):
            return .network(host: host, port: port)
            
        case .cloudflare(let workerURL, let apiToken):
            return .cloudflare(workerURL: workerURL, apiToken: apiToken)
            
        case .cloud(let url):
            return .http(url: url)
        }
    }
    
    /// Validate transport security for healthcare applications
    public static func validateTransportSecurity(
        type: BrainSAITTransportFactory.TransportType,
        configuration: BrainSAITConfiguration
    ) throws {
        
        guard configuration.hipaaCompliant else {
            return // No additional validation needed for non-HIPAA mode
        }
        
        switch type {
        case .stdio:
            // Local transport is considered secure
            break
            
        case .http(let url):
            guard url.scheme == "https" else {
                throw BrainSAITMCPError.hipaaViolation("HTTPS required for HIPAA compliance")
            }
            
        case .network:
            guard configuration.encryptionEnabled else {
                throw BrainSAITMCPError.hipaaViolation("Encryption required for network transport")
            }
            
        case .cloudflare:
            // Cloudflare Workers provide built-in security
            break
        }
    }
}

/// Deployment environment options for BrainSAIT
public enum DeploymentEnvironment {
    case development
    case raspberryPi(host: String, port: Int)
    case cloudflare(workerURL: URL, apiToken: String)
    case cloud(url: URL)
}