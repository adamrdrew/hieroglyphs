import Foundation
import SwiftUI

/// Concrete implementation of documentation file loading from filesystem.
final class DocsService: DocsProviding, @unchecked Sendable {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func hasDocsDirectory(sourceDirectory: String) -> Bool {
        guard !sourceDirectory.isEmpty else {
            return false
        }

        let docsPath = (sourceDirectory as NSString).appendingPathComponent(".ushabti/docs")

        guard fileManager.fileExists(atPath: docsPath) else {
            return false
        }

        do {
            let docsURL = URL(fileURLWithPath: docsPath)
            let contents = try fileManager.contentsOfDirectory(
                at: docsURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )

            let hasMarkdown = contents.contains { url in
                url.pathExtension == "md" && !url.lastPathComponent.hasPrefix(".")
            }

            return hasMarkdown
        } catch {
            return false
        }
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

                return Doc(
                    id: UUID(),
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
