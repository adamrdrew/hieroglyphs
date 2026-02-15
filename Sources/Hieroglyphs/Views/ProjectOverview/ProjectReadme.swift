import SwiftUI
import MarkdownUI

struct ProjectReadme: View {
    let project: Project

    @State private var readmeContent: String?
    @State private var isLoading = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading README...")
            } else if let content = readmeContent {
                ScrollView {
                    Markdown(content)
                        .padding()
                }
            } else {
                ContentUnavailableView(
                    "No README Found",
                    systemImage: "doc.text",
                    description: Text(emptyStateMessage)
                )
            }
        }
        .navigationTitle("README")
        .onAppear {
            loadReadme()
        }
    }

    private var emptyStateMessage: String {
        if project.sourceDirectory == nil {
            return "Set a source directory in the project overview to display README.md"
        } else {
            return "No README.md file found in the source directory"
        }
    }

    private func loadReadme() {
        guard let sourceDir = project.sourceDirectory else {
            readmeContent = nil
            return
        }

        let readmePath = "\(sourceDir)/README.md"

        guard FileManager.default.fileExists(atPath: readmePath) else {
            readmeContent = nil
            return
        }

        isLoading = true

        do {
            let content = try String(contentsOfFile: readmePath, encoding: .utf8)
            readmeContent = content
        } catch {
            print("Failed to load README from \(readmePath): \(error)")
            readmeContent = nil
        }

        isLoading = false
    }
}
