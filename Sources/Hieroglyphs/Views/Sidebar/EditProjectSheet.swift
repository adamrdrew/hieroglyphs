import SwiftUI
import AppKit

/// Sheet for editing an existing project.
///
/// Mirrors NewProjectSheet structure but pre-populates fields from
/// an existing project. Calls ViewModel.updateProject on save.
struct EditProjectSheet: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    let project: Project

    @State private var title = ""
    @State private var description = ""
    @State private var tags = ""
    @State private var sourceDirectory: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Tags") {
                    TextField("Comma-separated tags", text: $tags)
                }

                Section("Source Directory") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            if let sourceDirectory = sourceDirectory {
                                Text(sourceDirectory)
                                    .font(.caption)
                                    .lineLimit(2)
                                    .truncationMode(.middle)
                            } else {
                                Text("None")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
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
            }
            .navigationTitle("Edit Project")
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
            .onAppear {
                populateFields()
            }
        }
    }

    /// Pre-populates form fields from the project.
    private func populateFields() {
        title = project.title
        description = project.description
        tags = project.tags.joined(separator: ", ")
        sourceDirectory = project.sourceDirectory
    }

    /// Parses tags and updates the project.
    private func saveProject() {
        let parsedTags = tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let updatedProject = Project(
            id: project.id,
            title: title,
            description: description,
            tags: parsedTags,
            created: project.created,
            updated: Date(),
            slug: project.slug,
            sourceDirectory: sourceDirectory,
            buildCommand: project.buildCommand,
            runCommand: project.runCommand,
            publishCommand: project.publishCommand
        )

        viewModel.updateProject(updatedProject)
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
