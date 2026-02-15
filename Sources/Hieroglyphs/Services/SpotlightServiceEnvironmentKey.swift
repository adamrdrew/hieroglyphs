import SwiftUI

/// Environment key for injecting SearchProviding service.
private struct SearchServiceKey: EnvironmentKey {
    static let defaultValue: any SearchProviding = SpotlightService()
}

extension EnvironmentValues {
    /// Provides access to the search service via environment.
    var searchService: any SearchProviding {
        get { self[SearchServiceKey.self] }
        set { self[SearchServiceKey.self] = newValue }
    }
}
