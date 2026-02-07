import Foundation

/// Concrete implementation of FileWatching using FSEventStream.
///
/// Monitors a directory tree for file system events and invokes a callback
/// when changes are detected. Uses macOS native FSEvents API for efficient
/// monitoring without polling.
final class FileWatcherService: FileWatching {
    private var stream: FSEventStreamRef?
    fileprivate var onChange: ((URL) -> Void)?

    deinit {
        stopWatching()
    }

    func startWatching(path: String, onChange: @escaping (URL) -> Void) {
        stopWatching()

        self.onChange = onChange

        let context = createContext()
        guard let streamRef = createStream(path: path, context: context) else {
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

    private func createContext() -> UnsafeMutablePointer<FSEventStreamContext> {
        let contextPointer = UnsafeMutablePointer<FSEventStreamContext>.allocate(
            capacity: 1
        )
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        contextPointer.pointee = FSEventStreamContext(
            version: 0,
            info: selfPointer,
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        return contextPointer
    }

    private func createStream(
        path: String,
        context: UnsafeMutablePointer<FSEventStreamContext>
    ) -> FSEventStreamRef? {
        let pathsToWatch = [path] as CFArray
        let latency: CFTimeInterval = 0.5

        let flags = UInt32(kFSEventStreamCreateFlagFileEvents)
            | UInt32(kFSEventStreamCreateFlagUseCFTypes)

        return FSEventStreamCreate(
            kCFAllocatorDefault,
            eventCallback,
            context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            latency,
            flags
        )
    }

    private func cleanupStream() {
        guard let streamRef = stream else { return }

        FSEventStreamStop(streamRef)
        FSEventStreamInvalidate(streamRef)
        FSEventStreamRelease(streamRef)

        stream = nil
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

    for path in paths {
        let url = URL(fileURLWithPath: path)
        watcher.onChange?(url)
    }
}
