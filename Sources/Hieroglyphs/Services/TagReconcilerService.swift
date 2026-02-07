import Foundation

/// Concrete implementation of tag reconciliation using xattr.
///
/// Projects tags from frontmatter to macOS extended attributes by executing
/// the xattr command-line tool. Tags are written in plist XML format to the
/// `com.apple.metadata:_kMDItemUserTags` extended attribute.
final class TagReconcilerService: TagReconciling {

    func reconcileTags(for tags: [String], at path: String) {
        if tags.isEmpty {
            removeExtendedAttribute(at: path)
        } else {
            writeExtendedAttribute(tags: tags, at: path)
        }
    }

    private func removeExtendedAttribute(at path: String) {
        executeCommand(
            "/usr/bin/xattr",
            arguments: ["-d", "com.apple.metadata:_kMDItemUserTags", path]
        )
    }

    private func writeExtendedAttribute(tags: [String], at path: String) {
        let plistContent = generatePlist(for: tags)
        executeCommand(
            "/usr/bin/xattr",
            arguments: ["-w", "com.apple.metadata:_kMDItemUserTags", plistContent, path]
        )
    }

    private func generatePlist(for tags: [String]) -> String {
        var plist = "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
        plist += "<plist version=\"1.0\">\n<array>\n"

        for tag in tags {
            plist += "<string>\(escapeXML(tag))</string>\n"
        }

        plist += "</array>\n</plist>"
        return plist
    }

    private func escapeXML(_ string: String) -> String {
        var escaped = string
        escaped = escaped.replacingOccurrences(of: "&", with: "&amp;")
        escaped = escaped.replacingOccurrences(of: "<", with: "&lt;")
        escaped = escaped.replacingOccurrences(of: ">", with: "&gt;")
        escaped = escaped.replacingOccurrences(of: "\"", with: "&quot;")
        escaped = escaped.replacingOccurrences(of: "'", with: "&apos;")
        return escaped
    }

    private func executeCommand(_ command: String, arguments: [String]) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: command)
        task.arguments = arguments

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus != 0 {
                print("xattr command failed: \(arguments.joined(separator: " "))")
            }
        } catch {
            print("Failed to execute xattr: \(error)")
        }
    }
}
