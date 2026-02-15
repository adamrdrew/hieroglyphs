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
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundStyle(.secondary)
                                .symbolRenderingMode(.hierarchical)

                            Text(doc.displayTitle)
                                .font(.body)
                        }
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
        guard let docsDirectory = project.docsDirectory else {
            docs = []
            return
        }

        docs = docsService.loadDocs(from: docsDirectory)
    }
}
