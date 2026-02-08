import SwiftUI
import AppKit

/// First-launch welcome screen with workspace directory picker.
///
/// Displayed when no workspace config exists. Provides button to select
/// workspace directory via NSOpenPanel, then triggers workspace initialization.
struct WelcomeView: View {
    @Environment(HieroglyphsVM.self) private var viewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "folder.fill.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Welcome to Hieroglyphs")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("A markdown-based project management tool designed for transparency, version control, and seamless AI collaboration.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button {
                chooseWorkspaceFolder()
            } label: {
                Label("Choose Workspace Folder", systemImage: "folder")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }

    private func chooseWorkspaceFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Select a folder for your Hieroglyphs workspace"
        panel.prompt = "Choose"

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }

        viewModel.initializeWorkspace(at: url.path)
    }
}
