import Foundation
import Yams

/// Parses and serializes markdown files with YAML frontmatter.
struct FrontmatterParser {

    enum ParserError: Error {
        case invalidFormat
        case yamlParsingFailed(Error)
        case yamlSerializationFailed(Error)
    }

    /// Parses markdown content with YAML frontmatter.
    /// - Parameter markdown: The markdown content to parse
    /// - Returns: A tuple containing the frontmatter dictionary and body string
    /// - Throws: ParserError if parsing fails
    static func parse(_ markdown: String) throws -> (frontmatter: [String: Any], body: String) {
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false)

        guard lines.first == "---" else {
            return (frontmatter: [:], body: markdown)
        }

        guard let closingIndex = lines.dropFirst().firstIndex(of: "---") else {
            throw ParserError.invalidFormat
        }

        let frontmatterLines = lines[1..<closingIndex]
        let frontmatterString = frontmatterLines.joined(separator: "\n")

        let frontmatter: [String: Any]
        do {
            if let parsed = try Yams.load(yaml: frontmatterString) as? [String: Any] {
                frontmatter = parsed
            } else {
                frontmatter = [:]
            }
        } catch {
            throw ParserError.yamlParsingFailed(error)
        }

        let bodyStartIndex = lines.index(after: closingIndex)
        let bodyLines = lines[bodyStartIndex...]
        let body = bodyLines.joined(separator: "\n")

        return (frontmatter: frontmatter, body: body)
    }

    /// Serializes frontmatter and body into markdown with YAML frontmatter.
    /// - Parameters:
    ///   - frontmatter: The frontmatter dictionary to serialize
    ///   - body: The markdown body content
    /// - Returns: A complete markdown string with frontmatter
    /// - Throws: ParserError if serialization fails
    static func serialize(frontmatter: [String: Any], body: String) throws -> String {
        guard !frontmatter.isEmpty else {
            return body
        }

        let yamlString: String
        do {
            yamlString = try Yams.dump(object: frontmatter, allowUnicode: true)
        } catch {
            throw ParserError.yamlSerializationFailed(error)
        }

        let trimmedYaml = yamlString.trimmingCharacters(in: .whitespacesAndNewlines)
        return "---\n\(trimmedYaml)\n---\n\(body)"
    }
}
