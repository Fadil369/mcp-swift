# BrainSAIT MCP Swift SDK Integration

🏥 **Complete Model Context Protocol (MCP) Swift SDK integration for BrainSAIT's healthcare ecosystem**

[![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20iOS%20|%20watchOS%20|%20tvOS%20|%20visionOS-lightgrey.svg)](https://developer.apple.com/swift/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## 🌟 Features

- **🏥 Healthcare-Focused**: Specialized for medical AI applications with HIPAA compliance
- **🌍 Bilingual Support**: Full Arabic/English language processing and RTL text support
- **🔒 Security**: Built-in encryption and HIPAA compliance validation
- **🚀 Multi-Platform**: Supports all Apple platforms plus Linux
- **⚡ Multiple Transports**: stdio, HTTP/SSE, Network, and Cloudflare Workers
- **🔧 Production-Ready**: Service lifecycle management and comprehensive logging

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   iOS/macOS     │    │   Raspberry Pi   │    │   Cloudflare    │
│   BrainSAIT     │◄──►│   MCP Server     │◄──►│   Workers/Edge  │
│   Client Apps   │    │   (Healthcare)   │    │   AI Services   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                        │
         │              ┌──────────────────┐              │
         └─────────────►│   Local Storage  │◄─────────────┘
                        │   OMV (8TB SSD)  │
                        │   Medical Data   │
                        └──────────────────┘
```

## 📦 Installation

Add this package to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/Fadil369/mcp-swift.git", from: "1.0.0")
]
```

## 🚀 Quick Start

### Healthcare MCP Client

```swift
import BrainSAITMCP

// Configure for healthcare use
let config = BrainSAITConfiguration(
    applicationName: "MyHealthcareApp",
    supportedLanguages: ["ar", "en"],
    hipaaCompliant: true,
    encryptionEnabled: true
)

// Create client
let client = BrainSAITHealthcareClient(configuration: config)

// Connect using HTTP transport
let transport = try BrainSAITTransportFactory.createTransport(
    type: .http(url: URL(string: "https://api.brainsait.com")!),
    configuration: config
)

try await client.connect(transport: transport)

// Execute medical consultation in Arabic
let result = try await client.executeMedicalConsultation(
    promptName: "arabic-medical-consultation",
    patientData: [
        "patient_symptoms": "صداع وحمى",
        "medical_history": "لا يوجد تاريخ مرضي سابق"
    ],
    language: .arabic
)

print(result) // Arabic medical consultation response
```

### Healthcare MCP Server

```swift
import BrainSAITMCP

// Configure server
let config = BrainSAITConfiguration(
    applicationName: "BrainSAIT-Healthcare-Server",
    hipaaCompliant: true,
    encryptionEnabled: true
)

// Create server
let server = BrainSAITHealthcareServer(configuration: config)

// Start with stdio transport
let transport = try BrainSAITTransportFactory.createTransport(
    type: .stdio,
    configuration: config
)

try await server.start(transport: transport)
```

## 🔧 Command Line Tools

### Healthcare Server

```bash
# Start server with HTTP transport
brainsait-healthcare-server --transport http --port 8080 --hipaa-compliant --encryption

# Start with Cloudflare Workers
brainsait-healthcare-server --transport cloudflare \
  --cloudflare-url https://worker.example.workers.dev \
  --cloudflare-token your-api-token \
  --hipaa-compliant
```

### Healthcare Client

```bash
# Interactive mode with Arabic support
brainsait-client --language ar --hipaa-compliant

# Execute specific medical consultation
brainsait-client --command consult \
  --prompt-name "clinical-decision-support" \
  --symptoms "headache,fever" \
  --history "no-previous-conditions"

# Drug interaction check
brainsait-client --command analyze \
  --tool-name "drug-interaction-checker" \
  --medications "aspirin,ibuprofen" \
  --age 45
```

## 🌍 Language Support

### Arabic Medical Terminology

```swift
// Automatic language detection
let arabicSymptoms = "صداع شديد وغثيان"
let language = LanguageProcessor.detectLanguage(from: arabicSymptoms)
// Returns: .arabic

// RTL text processing
let processedText = LanguageProcessor.processTextForDisplay(
    arabicSymptoms, 
    language: .arabic
)
```

### Available Medical Prompts

- `arabic-medical-consultation` - استشارة طبية باللغة العربية
- `clinical-decision-support` - Clinical decision support for healthcare professionals

### Healthcare Tools

- `drug-interaction-checker` - فحص التفاعلات الدوائية
- `symptom-analyzer` - تحليل الأعراض

## 🔒 Security & Compliance

### HIPAA Compliance

```swift
let config = BrainSAITConfiguration(
    hipaaCompliant: true,
    encryptionEnabled: true
)

// All medical data operations validate HIPAA requirements
try await client.accessMedicalResource(uri: "brainsait://medical/patient-data")
```

### Data Encryption

All healthcare data is automatically encrypted when `encryptionEnabled: true`:

- Patient data access requires encryption validation
- Medical resources are encrypted at rest
- Transport layer security for all communications

## 🚀 Deployment

### Raspberry Pi + Cloudflare

```swift
let environment = DeploymentEnvironment.raspberryPi(host: "192.168.1.100", port: 8080)
let transportType = TransportConfiguration.recommendedTransport(
    for: environment,
    configuration: config
)
```

### Docker Support

```dockerfile
FROM swift:6.0
COPY . /app
WORKDIR /app
RUN swift build -c release
CMD [".build/release/BrainSAITHealthcareServer"]
```

## 📚 Documentation

- [API Reference](docs/api-reference.md)
- [Arabic Medical Integration](docs/arabic-medical.md)
- [HIPAA Compliance Guide](docs/hipaa-compliance.md)
- [Deployment Guide](docs/deployment.md)

## 🧪 Testing

```bash
swift test
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Model Context Protocol](https://modelcontextprotocol.io/) team
- [Swift MCP SDK](https://github.com/modelcontextprotocol/swift-sdk) contributors
- BrainSAIT healthcare AI research team

---

**Built with ❤️ for healthcare innovation in the Arab world**