import SwiftUI
import AppKit

enum CommandType {
    case build
    case run
    case publish
}

struct ProjectOverview: View {
    @Environment(HieroglyphsVM.self) private var viewModel

    let project: Project

    @State private var editedTitle: String = ""
    @State private var editedDescription: String = ""
    @State private var editedTagsString: String = ""
    @State private var editedSourceDirectory: String? = nil
    @State private var editedBuildCommand: String = ""
    @State private var editedRunCommand: String = ""
    @State private var editedPublishCommand: String = ""
    @State private var gitBranch: String?
    @State private var executingCommand: CommandType?

    var body: some View {
        Form {
            Section("Project Details") {
                TextField("Title", text: $editedTitle)
                    .onChange(of: editedTitle) { _, newValue in
                        if newValue != project.title {
                            saveProject()
                        }
                    }

                TextField("Description", text: $editedDescription, axis: .vertical)
                    .lineLimit(3...6)
                    .onChange(of: editedDescription) { _, newValue in
                        if newValue != project.description {
                            saveProject()
                        }
                    }

                TextField("Tags (comma-separated)", text: $editedTagsString)
                    .onChange(of: editedTagsString) { _, _ in
                        saveProject()
                    }
            }

            Section("Source Directory") {
                if let sourceDir = editedSourceDirectory {
                    HStack {
                        Text(sourceDir)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Spacer()

                        Button("Clear") {
                            editedSourceDirectory = nil
                            saveProject()
                        }
                        .buttonStyle(.borderless)
                    }
                } else {
                    Text("No source directory set")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button("Select Folder") {
                    selectSourceDirectory()
                }
                .buttonStyle(.borderedProminent)
            }

            Section("Build Commands") {
                TextField("Build Command", text: $editedBuildCommand)
                    .font(.caption.monospaced())
                    .onChange(of: editedBuildCommand) { _, newValue in
                        saveProject()
                    }

                TextField("Run Command", text: $editedRunCommand)
                    .font(.caption.monospaced())
                    .onChange(of: editedRunCommand) { _, newValue in
                        saveProject()
                    }

                TextField("Publish Command", text: $editedPublishCommand)
                    .font(.caption.monospaced())
                    .onChange(of: editedPublishCommand) { _, newValue in
                        saveProject()
                    }
            }

            if let gitBranch = gitBranch {
                Section("Git Info") {
                    HStack {
                        Text("Branch:")
                            .foregroundStyle(.secondary)
                        Text(gitBranch)
                            .font(.body.monospaced())
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Project Overview")
        .toolbar {
            if hasValidBuildCommand {
                ToolbarItem(placement: .automatic) {
                    Button {
                        executingCommand = .build
                    } label: {
                        Label("Build", systemImage: "hammer")
                    }
                    .disabled(editedSourceDirectory == nil)
                }
            }

            if hasValidRunCommand {
                ToolbarItem(placement: .automatic) {
                    Button {
                        executingCommand = .run
                    } label: {
                        Label("Run", systemImage: "play.fill")
                    }
                    .disabled(editedSourceDirectory == nil)
                }
            }

            if hasValidPublishCommand {
                ToolbarItem(placement: .automatic) {
                    Button {
                        executingCommand = .publish
                    } label: {
                        Label("Publish", systemImage: "arrow.up.doc")
                    }
                    .disabled(editedSourceDirectory == nil)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { executingCommand != nil },
            set: { if !$0 { executingCommand = nil } }
        )) {
            if let commandType = executingCommand,
               let sourceDir = editedSourceDirectory {
                CommandExecutionModal(
                    isPresented: Binding(
                        get: { executingCommand != nil },
                        set: { if !$0 { executingCommand = nil } }
                    ),
                    command: commandString(for: commandType),
                    workingDirectory: sourceDir,
                    title: commandTitle(for: commandType)
                )
            }
        }
        .onAppear {
            loadProjectData()
            loadGitBranch()
        }
    }

    private var hasValidBuildCommand: Bool {
        !editedBuildCommand.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var hasValidRunCommand: Bool {
        !editedRunCommand.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var hasValidPublishCommand: Bool {
        !editedPublishCommand.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func commandString(for commandType: CommandType) -> String {
        switch commandType {
        case .build:
            return editedBuildCommand
        case .run:
            return editedRunCommand
        case .publish:
            return editedPublishCommand
        }
    }

    private func commandTitle(for commandType: CommandType) -> String {
        switch commandType {
        case .build:
            return "Build"
        case .run:
            return "Run"
        case .publish:
            return "Publish"
        }
    }

    private func loadProjectData() {
        editedTitle = project.title
        editedDescription = project.description
        editedTagsString = project.tags.joined(separator: ", ")
        editedSourceDirectory = project.sourceDirectory
        editedBuildCommand = project.buildCommand ?? ""
        editedRunCommand = project.runCommand ?? ""
        editedPublishCommand = project.publishCommand ?? ""
    }

    private func saveProject() {
        let parsedTags = editedTagsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let updatedProject = Project(
            id: project.id,
            title: editedTitle.isEmpty ? project.title : editedTitle,
            description: editedDescription,
            tags: parsedTags,
            created: project.created,
            updated: Date(),
            slug: project.slug,
            sourceDirectory: editedSourceDirectory,
            docsDirectory: project.docsDirectory,
            buildCommand: editedBuildCommand.isEmpty ? nil : editedBuildCommand,
            runCommand: editedRunCommand.isEmpty ? nil : editedRunCommand,
            publishCommand: editedPublishCommand.isEmpty ? nil : editedPublishCommand
        )

        viewModel.updateProject(updatedProject)
    }

    private func selectSourceDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            editedSourceDirectory = panel.url?.path
            saveProject()
            loadGitBranch()
        }
    }

    private func loadGitBranch() {
        guard let sourceDir = editedSourceDirectory else {
            gitBranch = nil
            return
        }

        let gitHeadPath = "\(sourceDir)/.git/HEAD"
        guard FileManager.default.fileExists(atPath: gitHeadPath) else {
            gitBranch = nil
            return
        }

        do {
            let headContent = try String(contentsOfFile: gitHeadPath, encoding: .utf8)
            let trimmedContent = headContent.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedContent.hasPrefix("ref: refs/heads/") {
                let branchName = String(trimmedContent.dropFirst("ref: refs/heads/".count))
                gitBranch = branchName
            } else {
                gitBranch = nil
            }
        } catch {
            gitBranch = nil
        }
    }
}
