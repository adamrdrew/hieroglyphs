import SwiftUI

/// Middle column view displaying documentation files.
struct DocsList: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.docsService) private var docsService
    @State private var docs: [Doc] = []

    let project: Project

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        Group {
            if docs.isEmpty {
                emptyDocsState
            } else {
                List(selection: $bindableViewModel.selectedDoc) {
                    ForEach(docs) { doc in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(doc.extractedHeading)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            HStack(spacing: 4) {
                                Image(systemName: "doc.text")
                                    .font(.caption)
                                    .symbolRenderingMode(.hierarchical)
                                Text(doc.filename)
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)

                            if !doc.excerpt.isEmpty {
                                Text(doc.excerpt)
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 4)
                        .tag(doc)
                    }
                }
                .listStyle(.plain)
            }
        }
        .id(project.id)
        .onChange(of: project.id, initial: true) { _, _ in
            loadDocs()
        }
    }

    private var emptyDocsState: some View {
        ContentUnavailableView(
            "No Documentation",
            systemImage: "doc.text",
            description: Text("Documentation files will appear here.")
        )
    }

    private func loadDocs() {
        guard let sourceDirectory = project.sourceDirectory else {
            docs = []
            return
        }

        let docsPath = (sourceDirectory as NSString).appendingPathComponent(".ushabti/docs")
        docs = docsService.loadDocs(from: docsPath)
    }
}
