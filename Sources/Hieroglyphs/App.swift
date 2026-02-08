import SwiftUI

@main
struct HieroglyphsApp: App {
    @State private var viewModel: HieroglyphsVM
    private let workspaceService: WorkspaceProviding
    private let fileWatcher: FileWatching
    private let tagReconciler: TagReconciling
    private let searchService: SearchProviding

    init() {
        let service = WorkspaceService()
        let watcher = FileWatcherService()
        let reconciler = TagReconcilerService()
        let spotlight = SpotlightService()
        self.workspaceService = service
        self.fileWatcher = watcher
        self.tagReconciler = reconciler
        self.searchService = spotlight
        let vm = HieroglyphsVM(
            workspaceService: service,
            fileWatcher: watcher,
            tagReconciler: reconciler,
            searchService: spotlight
        )
        _viewModel = State(initialValue: vm)
    }

    var body: some Scene {
        Window("Hieroglyphs", id: "main") {
            Group {
                if viewModel.workspacePath == nil {
                    WelcomeView()
                } else {
                    MainWindow()
                }
            }
            .environment(viewModel)
            .environment(\.workspaceService, workspaceService)
            .environment(\.fileWatcher, fileWatcher)
            .environment(\.tagReconciler, tagReconciler)
            .environment(\.searchService, searchService)
            .onAppear {
                viewModel.loadWorkspace()
            }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Project") {
                    viewModel.showNewProjectSheet()
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])

                Button("New Card") {
                    viewModel.showNewCardSheet()
                }
                .keyboardShortcut("n", modifiers: .command)
                .disabled(viewModel.selectedProject == nil)
            }

            CommandGroup(after: .pasteboard) {
                Button("Delete") {
                    viewModel.deleteSelectedItem()
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(viewModel.selectedProject == nil && viewModel.selectedCard == nil)

                Divider()

                Button("Find") {
                    viewModel.requestSearchFocus()
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }
    }
}
