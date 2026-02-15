import SwiftUI

@main
struct HieroglyphsApp: App {
    @State private var viewModel: HieroglyphsVM
    private let workspaceService: WorkspaceProviding
    private let fileWatcher: FileWatching
    private let tagReconciler: TagReconciling
    private let searchService: SearchProviding
    private let phaseService: PhaseProviding
    private let planService: PlanProviding
    private let pharaohService: PharaohProviding
    private let docsService: DocsProviding
    private let promptGenerator: PromptGenerating

    init() {
        let service = WorkspaceService()
        let watcher = FileWatcherService()
        let reconciler = TagReconcilerService()
        let spotlight = SpotlightService()
        let phases = PhaseService()
        let plans = PlanService()
        let pharaoh = PharaohService()
        let docs = DocsService()
        let generator = PromptGenerator()
        self.workspaceService = service
        self.fileWatcher = watcher
        self.tagReconciler = reconciler
        self.searchService = spotlight
        self.phaseService = phases
        self.planService = plans
        self.pharaohService = pharaoh
        self.docsService = docs
        self.promptGenerator = generator
        let vm = HieroglyphsVM(
            workspaceService: service,
            fileWatcher: watcher,
            tagReconciler: reconciler,
            searchService: spotlight,
            phaseService: phases,
            planService: plans,
            pharaohService: pharaoh
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
            .environment(\.phaseService, phaseService)
            .environment(\.planService, planService)
            .environment(\.pharaohService, pharaohService)
            .environment(\.docsService, docsService)
            .environment(\.promptGenerator, promptGenerator)
            .onAppear {
                viewModel.loadWorkspace()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: NSApplication.willTerminateNotification
                )
            ) { _ in
                viewModel.flushPendingCardUpdates()
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

        MenuBarExtra {
            PharaohMenuBar()
                .environment(viewModel)
                .environment(\.planService, planService)
                .environment(\.pharaohService, pharaohService)
        } label: {
            Label("Pharaoh", systemImage: "chart.line.uptrend.xyaxis")
        }
        .menuBarExtraStyle(.menu)
    }
}
