import SwiftUI
import AppKit

/// Sheet for creating a new project.
///
/// Provides input fields for project title, description, tags, and optional source directory.
/// Validates that title is non-empty before enabling save.
///
/// Design:
/// - Constrained dimensions with scrollable content
/// - Semantic typography (headline headers, body content, caption metadata)
/// - Consistent spacing scale (4, 8, 12, 16 points)
/// - Clear visual hierarchy (primary fields prominent, directory picker secondary)
/// - Automatic Liquid Glass treatment on toolbar
struct NewProjectSheet: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var tags = ""
    @State private var sourceDirectory: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                Form {
                    Section {
                        TextField("Title", text: $title)

                        TextField("Description", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                    } header: {
                        Text("Project Details")
                            .font(.headline)
                    }

                    Section {
                        TextField("Comma-separated tags", text: $tags)
                    } header: {
                        Text("Tags")
                            .font(.headline)
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            if let sourceDirectory = sourceDirectory {
                                Text(sourceDirectory)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .truncationMode(.middle)
                            } else {
                                Text("None")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }

                            HStack(spacing: 8) {
                                if sourceDirectory != nil {
                                    Button("Clear") {
                                        self.sourceDirectory = nil
                                    }
                                    .buttonStyle(.borderless)
                                }

                                Button("Select Folder...") {
                                    selectSourceDirectory()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    } header: {
                        Text("Source Directory")
                            .font(.headline)
                    }
                }
                .formStyle(.grouped)
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProject()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 450)
    }

    /// Parses tags and creates the project.
    private func saveProject() {
        let parsedTags = tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        viewModel.createProject(
            title: title,
            description: description,
            tags: parsedTags,
            sourceDirectory: sourceDirectory
        )

        dismiss()
    }

    /// Opens NSOpenPanel to select source directory.
    private func selectSourceDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.message = "Select the source directory for this project"
        panel.prompt = "Select"

        let response = panel.runModal()
        if response == .OK, let url = panel.url {
            sourceDirectory = url.path
        }
    }
}
