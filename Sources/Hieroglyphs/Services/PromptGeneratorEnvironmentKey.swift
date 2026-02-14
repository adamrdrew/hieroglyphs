import SwiftUI

/// Environment key for PromptGenerating service injection.
struct PromptGeneratorEnvironmentKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: PromptGenerating? = nil
}

extension EnvironmentValues {
    var promptGenerator: PromptGenerating? {
        get { self[PromptGeneratorEnvironmentKey.self] }
        set { self[PromptGeneratorEnvironmentKey.self] = newValue }
    }
}
