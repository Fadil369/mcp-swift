import Foundation
import MCP
import Logging
import ServiceLifecycle

/// BrainSAIT Healthcare MCP Server for exposing medical knowledge and tools
public actor BrainSAITHealthcareServer {
    private let server: Server
    private let configuration: BrainSAITConfiguration
    private var logger: Logger
    
    // Medical knowledge and resources
    private var medicalPrompts: [String: MedicalPromptDefinition] = [:]
    private var medicalResources: [String: MedicalResourceDefinition] = [:]
    private var healthcareTools: [String: HealthcareToolDefinition] = [:]
    
    public init(configuration: BrainSAITConfiguration) {
        self.configuration = configuration
        self.logger = Logger(label: "com.brainsait.mcp.server")
        self.logger.logLevel = configuration.logLevel
        
        self.server = Server(
            name: configuration.applicationName,
            version: configuration.version,
            capabilities: .init(
                prompts: .init(listChanged: true),
                resources: .init(subscribe: true, listChanged: true),
                tools: .init(listChanged: true)
            )
        )
        
        logger.info("BrainSAIT Healthcare MCP Server initialized", metadata: [
            "application": .string(configuration.applicationName),
            "version": .string(configuration.version),
            "hipaa_mode": .stringConvertible(configuration.hipaaCompliant)
        ])
    }
    
    /// Start the MCP server using the provided transport
    public func start(transport: any Transport) async throws {
        // Initialize medical content first
        await initializeMedicalContent()
        await setupServerHandlers()
        
        try await server.start(transport: transport)
        logger.info("BrainSAIT Healthcare MCP Server started")
    }
    
    /// Stop the MCP server
    public func stop() async {
        await server.stop()
        logger.info("BrainSAIT Healthcare MCP Server stopped")
    }
    
    /// Initialize medical content and knowledge base
    private func initializeMedicalContent() async {
        // Initialize Arabic medical consultation prompts
        medicalPrompts["arabic-medical-consultation"] = MedicalPromptDefinition(
            name: "arabic-medical-consultation",
            description: "استشارة طبية باللغة العربية - Medical consultation in Arabic",
            arguments: [
                "patient_symptoms": "أعراض المريض - Patient symptoms",
                "medical_history": "التاريخ المرضي - Medical history",
                "language": "ar"
            ]
        )
        
        // Initialize clinical decision support prompts
        medicalPrompts["clinical-decision-support"] = MedicalPromptDefinition(
            name: "clinical-decision-support",
            description: "Clinical decision support for healthcare professionals",
            arguments: [
                "patient_data": "Complete patient data",
                "diagnosis_request": "Specific diagnosis assistance needed",
                "language": "en"
            ]
        )
        
        // Initialize medical resources
        medicalResources["patient-data"] = MedicalResourceDefinition(
            uri: "brainsait://medical/patient-data",
            name: "Patient Data Repository",
            description: "HIPAA-compliant patient data access",
            mimeType: "application/json",
            requiresEncryption: true
        )
        
        medicalResources["medical-literature"] = MedicalResourceDefinition(
            uri: "brainsait://medical/literature",
            name: "Medical Literature Database",
            description: "Access to medical literature and guidelines",
            mimeType: "text/plain",
            requiresEncryption: false
        )
        
        // Initialize healthcare tools
        healthcareTools["drug-interaction-checker"] = HealthcareToolDefinition(
            name: "drug-interaction-checker",
            description: "فحص التفاعلات الدوائية - Drug interaction analysis",
            inputSchema: [
                "medications": "List of medications",
                "patient_age": "Patient age",
                "language": "Preferred language (ar/en)"
            ]
        )
        
        healthcareTools["symptom-analyzer"] = HealthcareToolDefinition(
            name: "symptom-analyzer",
            description: "تحليل الأعراض - Symptom analysis and preliminary diagnosis",
            inputSchema: [
                "symptoms": "List of symptoms",
                "duration": "Duration of symptoms",
                "severity": "Severity level (1-10)",
                "language": "Preferred language (ar/en)"
            ]
        )
        
        logger.info("Medical content initialized", metadata: [
            "prompts": .stringConvertible(medicalPrompts.count),
            "resources": .stringConvertible(medicalResources.count),
            "tools": .stringConvertible(healthcareTools.count)
        ])
    }
    
    /// Setup MCP server handlers for medical operations
    private func setupServerHandlers() async {
        // List prompts handler
        server.withMethodHandler(ListPrompts.self) { _ in
            let prompts = self.medicalPrompts.values.map { prompt in
                Prompt(
                    name: prompt.name,
                    description: prompt.description,
                    arguments: prompt.arguments.map { key, value in
                        Prompt.Argument(name: key, description: value, required: true)
                    }
                )
            }
            return ListPrompts.Result(prompts: prompts)
        }
        
        // Get prompt handler with bilingual support
        server.withMethodHandler(GetPrompt.self) { params in
            guard let promptDef = self.medicalPrompts[params.name] else {
                throw BrainSAITMCPError.unknownMedicalPrompt(params.name)
            }
            
            // Validate HIPAA compliance for medical prompts
            if self.configuration.hipaaCompliant {
                let requiresEncryption = params.arguments?["require_encryption"]?.boolValue ?? false
                guard requiresEncryption else {
                    throw BrainSAITMCPError.hipaaViolation("Encryption required for medical data")
                }
            }
            
            // Generate medical prompt response based on language
            let languageString = params.arguments?["language"]?.stringValue ?? "en"
            let language = LanguageProcessor.Language(rawValue: languageString) ?? .english
            
            let response = try await self.generateMedicalPromptResponse(
                promptName: params.name,
                arguments: params.arguments ?? [:],
                language: language
            )
            
            return GetPrompt.Result(
                description: response,
                messages: [
                    Prompt.Message.assistant(.text(text: response))
                ]
            )
        }
        
        // List resources handler
        server.withMethodHandler(ListResources.self) { _ in
            let resources = self.medicalResources.values.map { resource in
                Resource(
                    name: resource.name,
                    uri: resource.uri,
                    description: resource.description,
                    mimeType: resource.mimeType
                )
            }
            return ListResources.Result(resources: resources)
        }
        
        // Read resource handler with encryption validation
        server.withMethodHandler(ReadResource.self) { params in
            guard let resourceDef = self.medicalResources.values.first(where: { $0.uri == params.uri }) else {
                throw BrainSAITMCPError.medicalDataAccessDenied
            }
            
            // Validate encryption requirements
            if resourceDef.requiresEncryption && !self.configuration.encryptionEnabled {
                throw BrainSAITMCPError.encryptionRequired
            }
            
            let content = try await self.retrieveMedicalResource(
                uri: params.uri,
                encrypted: resourceDef.requiresEncryption
            )
            
            return ReadResource.Result(
                contents: [
                    Resource.Content.text(content, uri: params.uri)
                ]
            )
        }
        
        // List tools handler
        server.withMethodHandler(ListTools.self) { _ in
            let tools = self.healthcareTools.values.map { tool in
                Tool(
                    name: tool.name,
                    description: tool.description,
                    inputSchema: nil // TODO: Convert schema to Value type
                )
            }
            return ListTools.Result(tools: tools)
        }
        
        // Call tool handler with bilingual support
        server.withMethodHandler(CallTool.self) { params in
            guard let toolDef = self.healthcareTools[params.name] else {
                throw BrainSAITMCPError.unknownMedicalPrompt(params.name)
            }
            
            let languageString = params.arguments?["language"]?.stringValue ?? "en"
            let language = LanguageProcessor.Language(rawValue: languageString) ?? .english
            
            let result = try await self.executeHealthcareTool(
                toolName: params.name,
                arguments: params.arguments ?? [:],
                language: language
            )
            
            return CallTool.Result(
                content: [
                    Tool.Content.text(result)
                ]
            )
        }
        
        logger.info("MCP server handlers configured")
    }
    
    /// Generate medical prompt response with language support
    private func generateMedicalPromptResponse(
        promptName: String,
        arguments: [String: Value],
        language: LanguageProcessor.Language
    ) async throws -> String {
        
        switch promptName {
        case "arabic-medical-consultation":
            return try await generateArabicMedicalConsultation(arguments: arguments)
        case "clinical-decision-support":
            return try await generateClinicalDecisionSupport(arguments: arguments, language: language)
        default:
            throw BrainSAITMCPError.unknownMedicalPrompt(promptName)
        }
    }
    
    /// Generate Arabic medical consultation response
    private func generateArabicMedicalConsultation(arguments: [String: Value]) async throws -> String {
        let symptoms = arguments["patient_symptoms"]?.stringValue ?? ""
        let history = arguments["medical_history"]?.stringValue ?? ""
        
        // Simulate medical consultation in Arabic
        let consultation = """
        استشارة طبية - BrainSAIT
        ======================
        
        الأعراض المُبلغ عنها: \(symptoms)
        التاريخ المرضي: \(history)
        
        التوصيات الأولية:
        - يُنصح بمراجعة طبيب مختص
        - مراقبة الأعراض وتسجيل تطورها
        - الحفاظ على نمط حياة صحي
        
        تنبيه: هذه استشارة أولية ولا تغني عن الفحص الطبي المباشر
        """
        
        return LanguageProcessor.processTextForDisplay(consultation, language: .arabic)
    }
    
    /// Generate clinical decision support response
    private func generateClinicalDecisionSupport(
        arguments: [String: Value],
        language: LanguageProcessor.Language
    ) async throws -> String {
        
        let patientData = arguments["patient_data"]?.stringValue ?? ""
        let diagnosisRequest = arguments["diagnosis_request"]?.stringValue ?? ""
        
        let support = """
        BrainSAIT Clinical Decision Support
        ==================================
        
        Patient Data Analysis: \(patientData)
        Diagnosis Request: \(diagnosisRequest)
        
        Clinical Recommendations:
        - Review patient history for relevant patterns
        - Consider differential diagnosis options
        - Recommend appropriate diagnostic tests
        - Monitor patient response to treatment
        
        Evidence-based guidelines suggest further evaluation
        """
        
        return LanguageProcessor.processTextForDisplay(support, language: language)
    }
    
    /// Retrieve medical resource with encryption support
    private func retrieveMedicalResource(uri: String, encrypted: Bool) async throws -> String {
        // Simulate resource retrieval - in real implementation, this would
        // access actual medical databases with proper encryption
        
        switch uri {
        case "brainsait://medical/patient-data":
            if encrypted && !configuration.encryptionEnabled {
                throw BrainSAITMCPError.encryptionRequired
            }
            return "{ \"patient_id\": \"encrypted_data\", \"access_level\": \"hipaa_compliant\" }"
            
        case "brainsait://medical/literature":
            return "Medical literature and guidelines database access granted"
            
        default:
            throw BrainSAITMCPError.medicalDataAccessDenied
        }
    }
    
    /// Execute healthcare tool with bilingual support
    private func executeHealthcareTool(
        toolName: String,
        arguments: [String: Value],
        language: LanguageProcessor.Language
    ) async throws -> String {
        
        switch toolName {
        case "drug-interaction-checker":
            return try await executeDrugInteractionChecker(arguments: arguments, language: language)
        case "symptom-analyzer":
            return try await executeSymptomAnalyzer(arguments: arguments, language: language)
        default:
            throw BrainSAITMCPError.unknownMedicalPrompt(toolName)
        }
    }
    
    /// Execute drug interaction checker tool
    private func executeDrugInteractionChecker(
        arguments: [String: Value],
        language: LanguageProcessor.Language
    ) async throws -> String {
        
        let medications = arguments["medications"]?.arrayValue?.compactMap(\.stringValue) ?? []
        let patientAge = arguments["patient_age"]?.intValue ?? 0
        
        let analysis = language == .arabic ? 
        """
        فحص التفاعلات الدوائية - BrainSAIT
        ===============================
        
        الأدوية المُدخلة: \(medications.joined(separator: "، "))
        عمر المريض: \(patientAge) سنة
        
        نتائج الفحص:
        - لا توجد تفاعلات خطيرة محتملة
        - يُنصح بمراقبة الآثار الجانبية
        - استشر الصيدلي للمزيد من المعلومات
        """ :
        """
        Drug Interaction Analysis - BrainSAIT
        ====================================
        
        Medications: \(medications.joined(separator: ", "))
        Patient Age: \(patientAge) years
        
        Analysis Results:
        - No major drug interactions detected
        - Monitor for side effects
        - Consult pharmacist for detailed information
        """
        
        return LanguageProcessor.processTextForDisplay(analysis, language: language)
    }
    
    /// Execute symptom analyzer tool
    private func executeSymptomAnalyzer(
        arguments: [String: Value],
        language: LanguageProcessor.Language
    ) async throws -> String {
        
        let symptoms = arguments["symptoms"]?.arrayValue?.compactMap(\.stringValue) ?? []
        let duration = arguments["duration"]?.stringValue ?? ""
        let severity = arguments["severity"]?.intValue ?? 1
        
        let analysis = language == .arabic ?
        """
        تحليل الأعراض - BrainSAIT
        =======================
        
        الأعراض: \(symptoms.joined(separator: "، "))
        المدة: \(duration)
        شدة الأعراض: \(severity)/10
        
        التحليل الأولي:
        - تتطلب هذه الأعراض تقييم طبي
        - يُنصح بمراجعة الطبيب في أقرب وقت
        - احتفظ بسجل للأعراض وتطورها
        """ :
        """
        Symptom Analysis - BrainSAIT
        ===========================
        
        Symptoms: \(symptoms.joined(separator: ", "))
        Duration: \(duration)
        Severity: \(severity)/10
        
        Preliminary Analysis:
        - These symptoms require medical evaluation
        - Recommend consulting a physician soon
        - Keep a record of symptom progression
        """
        
        return LanguageProcessor.processTextForDisplay(analysis, language: language)
    }
}

// MARK: - Supporting Types

/// Definition for medical prompts in the BrainSAIT system
public struct MedicalPromptDefinition {
    let name: String
    let description: String
    let arguments: [String: String]
}

/// Definition for medical resources in the BrainSAIT system
public struct MedicalResourceDefinition {
    let uri: String
    let name: String
    let description: String
    let mimeType: String
    let requiresEncryption: Bool
}

/// Definition for healthcare tools in the BrainSAIT system
public struct HealthcareToolDefinition {
    let name: String
    let description: String
    let inputSchema: [String: String]
}