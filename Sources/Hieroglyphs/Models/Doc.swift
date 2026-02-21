import Foundation

/// Represents a documentation file from the Ushabti docs directory.
struct Doc: Identifiable, Equatable, Hashable {
    let id: UUID
    let title: String
    let slug: String
    let filename: String
    let content: String

    var displayTitle: String {
        slug
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    var extractedHeading: String {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.hasPrefix("# ") {
                let headingText = trimmedLine.dropFirst(2)
                return String(headingText).trimmingCharacters(in: .whitespaces)
            }
        }
        return displayTitle
    }

    var excerpt: String {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        var foundH1 = false
        var paragraphLines: [String] = []

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            if trimmedLine.hasPrefix("# ") {
                foundH1 = true
                continue
            }

            if foundH1 {
                if trimmedLine.isEmpty {
                    if !paragraphLines.isEmpty {
                        break
                    }
                    continue
                }

                paragraphLines.append(trimmedLine)
            }
        }

        if paragraphLines.isEmpty {
            return ""
        }

        let paragraph = paragraphLines.joined(separator: " ")
        let stripped = stripMarkdown(paragraph)
        let limit = 150
        if stripped.count > limit {
            let index = stripped.index(stripped.startIndex, offsetBy: limit)
            return String(stripped[..<index]) + "..."
        }
        return stripped
    }

    private func stripMarkdown(_ text: String) -> String {
        var result = text

        while let boldRange = result.range(of: "**") {
            if let endRange = result[boldRange.upperBound...].range(of: "**") {
                let boldText = result[boldRange.upperBound..<endRange.lowerBound]
                result.replaceSubrange(boldRange.lowerBound..<endRange.upperBound, with: boldText)
            } else {
                result.removeSubrange(boldRange)
            }
        }

        while let italicRange = result.range(of: "*") {
            if let endRange = result[italicRange.upperBound...].range(of: "*") {
                let italicText = result[italicRange.upperBound..<endRange.lowerBound]
                result.replaceSubrange(italicRange.lowerBound..<endRange.upperBound, with: italicText)
            } else {
                result.removeSubrange(italicRange)
            }
        }

        while let linkStart = result.range(of: "[") {
            if let linkMid = result[linkStart.upperBound...].range(of: "]("),
               let linkEnd = result[linkMid.upperBound...].range(of: ")") {
                let linkText = result[linkStart.upperBound..<linkMid.lowerBound]
                result.replaceSubrange(linkStart.lowerBound..<linkEnd.upperBound, with: linkText)
            } else {
                result.removeSubrange(linkStart)
            }
        }

        while let codeRange = result.range(of: "`") {
            if let endRange = result[codeRange.upperBound...].range(of: "`") {
                let codeText = result[codeRange.upperBound..<endRange.lowerBound]
                result.replaceSubrange(codeRange.lowerBound..<endRange.upperBound, with: codeText)
            } else {
                result.removeSubrange(codeRange)
            }
        }

        return result
    }
}
