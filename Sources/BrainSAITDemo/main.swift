import Foundation
import BrainSAITMCP

/// Simple demonstration of BrainSAIT healthcare capabilities
@main
struct BrainSAITDemo {
    static func main() {
        print("🌟 BrainSAIT Healthcare AI System Demo 🌟")
        print()
        
        // Run language processing example
        BrainSAITExample.runLanguageExample()
        
        // Run medical consultation example
        BrainSAITExample.runMedicalConsultationExample()
        
        // Run drug interaction example
        BrainSAITExample.runDrugInteractionExample()
        
        print("\n✨ Demo completed! ✨")
        print("For full MCP server/client functionality, use:")
        print("  - brainsait-healthcare-server (when compilation issues are resolved)")
        print("  - brainsait-client (when compilation issues are resolved)")
    }
}