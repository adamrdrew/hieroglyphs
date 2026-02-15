import Foundation
import SwiftUI

/// Concrete implementation of documentation file loading from filesystem.
final class DocsService: DocsProviding {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func loadDocs(from docsDirectory: String) -> [Doc] {
        let docsURL = URL(fileURLWithPath: docsDirectory)

        guard fileManager.fileExists(atPath: docsDirectory) else {
            return []
        }

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: docsURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )

            let markdownFiles = contents.filter { url in
                url.pathExtension == "md" && !url.lastPathComponent.hasPrefix(".")
            }

            let docs = markdownFiles.compactMap { url -> Doc? in
                let filename = url.lastPathComponent
                let slug = url.deletingPathExtension().lastPathComponent
                let title = slug

                guard let content = loadDocContent(path: url.path) else {
                    return nil
                }

                let id = generateStableUUID(from: filename)

                return Doc(
                    id: id,
                    title: title,
                    slug: slug,
                    filename: filename,
                    content: content
                )
            }

            return docs.sorted { $0.slug < $1.slug }
        } catch {
            print("Warning: Failed to load docs from \(docsDirectory): \(error)")
            return []
        }
    }

    func loadDocContent(path: String) -> String? {
        guard fileManager.fileExists(atPath: path) else {
            return nil
        }

        do {
            return try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
        } catch {
            print("Warning: Failed to load doc content from \(path): \(error)")
            return nil
        }
    }

    private func generateStableUUID(from filename: String) -> UUID {
        let namespace = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!
        let data = (namespace.uuidString + filename).data(using: .utf8)!
        let hash = data.withUnsafeBytes { bytes in
            var hasher = [UInt8](repeating: 0, count: 16)
            let ptr = bytes.bindMemory(to: UInt8.self)
            for i in 0..<min(16, ptr.count) {
                hasher[i] = ptr[i]
            }
            return hasher
        }

        let uuidString = String(
            format: "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
            hash[0], hash[1], hash[2], hash[3],
            hash[4], hash[5],
            hash[6], hash[7],
            hash[8], hash[9],
            hash[10], hash[11], hash[12], hash[13], hash[14], hash[15]
        )

        return UUID(uuidString: uuidString) ?? UUID()
    }
}

private struct DocsServiceEnvironmentKey: EnvironmentKey {
    static let defaultValue: DocsProviding = DocsService()
}

extension EnvironmentValues {
    var docsService: DocsProviding {
        get { self[DocsServiceEnvironmentKey.self] }
        set { self[DocsServiceEnvironmentKey.self] = newValue }
    }
}
