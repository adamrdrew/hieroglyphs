import SwiftUI

/// Environment key for injecting SearchProviding service.
private struct SearchServiceKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: SearchProviding = SpotlightService()
}

extension EnvironmentValues {
    /// Provides access to the search service via environment.
    var searchService: SearchProviding {
        get { self[SearchServiceKey.self] }
        set { self[SearchServiceKey.self] = newValue }
    }
}
