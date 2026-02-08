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
            MainWindow()
                .environment(viewModel)
                .environment(\.workspaceService, workspaceService)
                .environment(\.fileWatcher, fileWatcher)
                .environment(\.tagReconciler, tagReconciler)
                .environment(\.searchService, searchService)
                .onAppear {
                    viewModel.loadWorkspace()
                }
        }
    }
}
