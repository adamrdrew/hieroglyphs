import SwiftUI

/// Sidebar item showing Pharaoh status for a project.
struct SidebarPharaohItem: View {
    let project: Project
    @Environment(\.pharaohService) private var pharaohService
    @State private var status: PharaohStatus = .notRunning

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 8))
                .foregroundStyle(statusColor)

            Text("Pharaoh")
        }
        .tag(SidebarSection.pharaoh(project))
        .onAppear {
            updateStatus()
        }
        .task {
            await pollStatus()
        }
    }

    private var statusColor: Color {
        switch status {
        case .notRunning:
            return .red
        case .idle:
            return .green
        case .busy, .done, .blocked:
            return .orange
        }
    }

    private func updateStatus() {
        guard let sourceDirectory = project.sourceDirectory,
              let service = pharaohService else {
            status = .notRunning
            return
        }
        status = service.readStatus(from: sourceDirectory)
    }

    private func pollStatus() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(2))
            updateStatus()
        }
    }
}
