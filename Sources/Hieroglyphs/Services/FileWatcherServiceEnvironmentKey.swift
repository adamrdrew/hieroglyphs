import SwiftUI

/// Environment key for FileWatching service injection.
private struct FileWatcherServiceKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: FileWatching = FileWatcherService()
}

extension EnvironmentValues {
    var fileWatcher: FileWatching {
        get { self[FileWatcherServiceKey.self] }
        set { self[FileWatcherServiceKey.self] = newValue }
    }
}
