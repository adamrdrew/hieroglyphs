import Foundation

/// Generates filesystem-safe slugs from title strings.
struct SlugGenerator {

    /// Converts a title string to a filesystem-safe slug.
    /// - Parameter title: The title to convert
    /// - Returns: A lowercase, hyphen-separated, alphanumeric slug
    static func generateSlug(from title: String) -> String {
        var slug = title.lowercased()

        slug = slug.replacingOccurrences(of: " ", with: "-")

        slug = slug.filter { character in
            character.isLetter || character.isNumber || character == "-"
        }

        while slug.contains("--") {
            slug = slug.replacingOccurrences(of: "--", with: "-")
        }

        slug = slug.trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        return slug
    }
}
