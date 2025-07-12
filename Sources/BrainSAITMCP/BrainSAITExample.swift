import Foundation

/// Simple example demonstrating BrainSAIT language processing
public struct BrainSAITExample {
    
    /// Run a simple Arabic/English language detection example
    public static func runLanguageExample() {
        print("🏥 BrainSAIT Healthcare Language Processing Example")
        print("=" * 50)
        
        // Test Arabic text
        let arabicText = "مرحبا بكم في نظام الذكاء الاصطناعي للرعاية الصحية"
        let arabicLanguage = LanguageProcessor.detectLanguage(from: arabicText)
        print("Arabic text: \(arabicText)")
        print("Detected language: \(arabicLanguage)")
        print("Processed for display: \(LanguageProcessor.processTextForDisplay(arabicText, language: arabicLanguage))")
        print()
        
        // Test English text
        let englishText = "Welcome to the BrainSAIT healthcare AI system"
        let englishLanguage = LanguageProcessor.detectLanguage(from: englishText)
        print("English text: \(englishText)")
        print("Detected language: \(englishLanguage)")
        print("Processed for display: \(LanguageProcessor.processTextForDisplay(englishText, language: englishLanguage))")
        print()
        
        // Test configuration
        let config = BrainSAITConfiguration()
        print("BrainSAIT Configuration:")
        print("  Application: \(config.applicationName)")
        print("  Version: \(config.version)")
        print("  Languages: \(config.supportedLanguages.joined(separator: ", "))")
        print("  HIPAA Compliant: \(config.hipaaCompliant)")
        print("  Encryption: \(config.encryptionEnabled)")
    }
    
    /// Run a medical consultation simulation
    public static func runMedicalConsultationExample() {
        print("\n🩺 Medical Consultation Simulation")
        print("=" * 50)
        
        // Simulate Arabic medical consultation
        let arabicSymptoms = "صداع شديد وحمى عالية"
        let arabicHistory = "لا يوجد تاريخ مرضي سابق"
        
        print("Patient Symptoms (Arabic): \(arabicSymptoms)")
        print("Medical History (Arabic): \(arabicHistory)")
        
        let consultation = """
        استشارة طبية أولية - BrainSAIT
        ==============================
        
        الأعراض المُبلغ عنها: \(arabicSymptoms)
        التاريخ المرضي: \(arabicHistory)
        
        التوصيات الأولية:
        - يُنصح بمراجعة طبيب مختص فوراً
        - قياس درجة الحرارة كل ساعتين
        - شرب السوائل بكثرة
        - الراحة التامة
        
        تنبيه مهم: هذه استشارة أولية ولا تغني عن الفحص الطبي المباشر
        """
        
        print("\nGenerated Consultation:")
        print(consultation)
    }
    
    /// Run drug interaction checker simulation
    public static func runDrugInteractionExample() {
        print("\n💊 Drug Interaction Checker Simulation")
        print("=" * 50)
        
        let medications = ["Aspirin", "Ibuprofen", "Acetaminophen"]
        let patientAge = 45
        
        print("Medications: \(medications.joined(separator: ", "))")
        print("Patient Age: \(patientAge) years")
        
        let analysis = """
        Drug Interaction Analysis - BrainSAIT
        ====================================
        
        Analyzed Medications: \(medications.joined(separator: ", "))
        Patient Age: \(patientAge) years
        
        Analysis Results:
        ⚠️  Potential Interaction Detected:
        - Aspirin + Ibuprofen: May increase risk of gastrointestinal bleeding
        - Recommended: Space doses at least 4 hours apart
        
        ✅ Safe Combinations:
        - Acetaminophen can be taken with either medication
        
        Recommendations:
        - Consult your pharmacist for personalized advice
        - Monitor for unusual symptoms
        - Follow prescribed dosing schedules
        """
        
        print(analysis)
    }
}

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}