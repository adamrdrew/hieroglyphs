import Foundation

/// Concrete implementation of FileWatching using FSEventStream.
///
/// Monitors a directory tree for file system events and invokes a callback
/// when changes are detected. Uses macOS native FSEvents API for efficient
/// monitoring without polling.
final class FileWatcherService: FileWatching {
    private var stream: FSEventStreamRef?
    fileprivate var onChange: ((URL) -> Void)?
    fileprivate var phasesStream: FSEventStreamRef?
    fileprivate var onPhasesChange: ((URL) -> Void)?
    fileprivate var pharaohStream: FSEventStreamRef?
    fileprivate var onPharaohChange: ((URL) -> Void)?

    deinit {
        stopWatching()
        stopWatchingPhases()
        stopWatchingPharaoh()
    }

    func startWatching(path: String, onChange: @escaping (URL) -> Void) {
        stopWatching()

        self.onChange = onChange

        guard let streamRef = createStream(path: path) else {
            return
        }

        self.stream = streamRef
        FSEventStreamSetDispatchQueue(streamRef, DispatchQueue.main)

        guard FSEventStreamStart(streamRef) else {
            cleanupStream()
            return
        }
    }

    func stopWatching() {
        cleanupStream()
        onChange = nil
    }

    func startWatchingPhases(path: String, onChange: @escaping (URL) -> Void) {
        stopWatchingPhases()

        self.onPhasesChange = onChange

        guard let streamRef = createStream(path: path) else {
            return
        }

        self.phasesStream = streamRef
        FSEventStreamSetDispatchQueue(streamRef, DispatchQueue.main)

        guard FSEventStreamStart(streamRef) else {
            cleanupPhasesStream()
            return
        }
    }

    func stopWatchingPhases() {
        cleanupPhasesStream()
        onPhasesChange = nil
    }

    func startWatchingPharaoh(path: String, onChange: @escaping (URL) -> Void) {
        stopWatchingPharaoh()

        self.onPharaohChange = onChange

        guard let streamRef = createStream(path: path) else {
            return
        }

        self.pharaohStream = streamRef
        FSEventStreamSetDispatchQueue(streamRef, DispatchQueue.main)

        guard FSEventStreamStart(streamRef) else {
            cleanupPharaohStream()
            return
        }
    }

    func stopWatchingPharaoh() {
        cleanupPharaohStream()
        onPharaohChange = nil
    }

    private func createStream(path: String) -> FSEventStreamRef? {
        let pathsToWatch = [path] as CFArray
        let latency: CFTimeInterval = 0.5

        let flags = UInt32(kFSEventStreamCreateFlagFileEvents)
            | UInt32(kFSEventStreamCreateFlagUseCFTypes)

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        var context = FSEventStreamContext(
            version: 0,
            info: selfPointer,
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        return withUnsafeMutablePointer(to: &context) { contextPointer in
            FSEventStreamCreate(
                kCFAllocatorDefault,
                eventCallback,
                contextPointer,
                pathsToWatch,
                FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
                latency,
                flags
            )
        }
    }

    private func cleanupStream() {
        guard let streamRef = stream else { return }

        FSEventStreamStop(streamRef)
        FSEventStreamInvalidate(streamRef)
        FSEventStreamRelease(streamRef)

        stream = nil
    }

    private func cleanupPhasesStream() {
        guard let streamRef = phasesStream else { return }

        FSEventStreamStop(streamRef)
        FSEventStreamInvalidate(streamRef)
        FSEventStreamRelease(streamRef)

        phasesStream = nil
    }

    private func cleanupPharaohStream() {
        guard let streamRef = pharaohStream else { return }

        FSEventStreamStop(streamRef)
        FSEventStreamInvalidate(streamRef)
        FSEventStreamRelease(streamRef)

        pharaohStream = nil
    }
}

private func eventCallback(
    streamRef: ConstFSEventStreamRef,
    clientCallBackInfo: UnsafeMutableRawPointer?,
    numEvents: Int,
    eventPaths: UnsafeMutableRawPointer,
    eventFlags: UnsafePointer<FSEventStreamEventFlags>,
    eventIds: UnsafePointer<FSEventStreamEventId>
) {
    guard let info = clientCallBackInfo else { return }

    let watcher = Unmanaged<FileWatcherService>.fromOpaque(info).takeUnretainedValue()
    guard let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] else {
        return
    }

    // Determine which stream this is by comparing stream references
    let callback: ((URL) -> Void)?
    if streamRef == watcher.phasesStream {
        callback = watcher.onPhasesChange
    } else if streamRef == watcher.pharaohStream {
        callback = watcher.onPharaohChange
    } else {
        callback = watcher.onChange
    }

    for path in paths {
        let url = URL(fileURLWithPath: path)
        callback?(url)
    }
}
