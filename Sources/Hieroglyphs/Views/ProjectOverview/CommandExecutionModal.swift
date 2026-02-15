import SwiftUI

struct CommandExecutionModal: View {
    @Environment(\.commandExecutionService) private var commandExecutionService

    @Binding var isPresented: Bool

    let command: String
    let workingDirectory: String
    let title: String

    enum ExecutionState {
        case running
        case success(String)
        case failure(String)
    }

    @State private var state: ExecutionState = .running

    var body: some View {
        VStack(spacing: 20) {
            switch state {
            case .running:
                runningView
            case .success(let output):
                successView(output: output)
            case .failure(let error):
                failureView(error: error)
            }
        }
        .frame(width: 600, height: 400)
        .padding()
        .onAppear {
            executeCommand()
        }
    }

    private var runningView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Executing...")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private func successView(output: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("\(title) Complete")
                .font(.headline)

            if !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ScrollView {
                    Text(output)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
            }

            Button("Done") {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func failureView(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("\(title) Failed")
                .font(.headline)

            ScrollView {
                Text(error)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)

            Button("Close") {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func executeCommand() {
        Task {
            do {
                let result = try await commandExecutionService.executeCommand(
                    command: command,
                    workingDirectory: workingDirectory
                )
                await MainActor.run {
                    state = .success(result.output)
                }
            } catch let error as CommandExecutionService.CommandError {
                await MainActor.run {
                    switch error {
                    case .nonZeroExit(let code, let output):
                        state = .failure("Exit code \(code)\n\n\(output)")
                    case .timeout:
                        state = .failure("Command timed out")
                    case .processLaunchFailed:
                        state = .failure("Failed to launch process")
                    }
                }
            } catch {
                await MainActor.run {
                    state = .failure(error.localizedDescription)
                }
            }
        }
    }
}
