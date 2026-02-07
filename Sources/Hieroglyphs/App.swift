import SwiftUI

@main
struct HieroglyphsApp: App {
    @State private var viewModel: HieroglyphsVM
    private let workspaceService: WorkspaceProviding
    private let fileWatcher: FileWatching
    private let tagReconciler: TagReconciling

    init() {
        let service = WorkspaceService()
        let watcher = FileWatcherService()
        let reconciler = TagReconcilerService()
        self.workspaceService = service
        self.fileWatcher = watcher
        self.tagReconciler = reconciler
        let vm = HieroglyphsVM(
            workspaceService: service,
            fileWatcher: watcher,
            tagReconciler: reconciler
        )
        _viewModel = State(initialValue: vm)
    }

    var body: some Scene {
        Window("Hieroglyphs", id: "main") {
            MainWindow()
                .environment(viewModel)
                .environment(\.workspaceService, workspaceService)
                .environment(\.fileWatcher, fileWatcher)
                .environment(\.tagReconciler, tagReconciler)
                .onAppear {
                    viewModel.loadWorkspace()
                }
        }
    }
}
