import SwiftUI
import Observation

/// Represents a selectable section in the sidebar.
///
/// Each section corresponds to a project and a specific view type
/// (cards, plans, phases, or pharaoh). This enables hierarchical navigation where
/// selecting a section determines both the project context and which
/// middle-column view to display.
enum SidebarSection: Hashable {
    case cards(Project)
    case plans(Project)
    case phases(Project)
    case pharaoh(Project)
}

/// ViewModel coordinating workspace state and UI selection.
///
/// Acts as the central coordinator between WorkspaceService and UI views.
/// Manages workspace path, project list, and selected project state.
/// Injected via @Environment for view access.
@Observable
@MainActor
final class HieroglyphsVM {
    var workspacePath: String?
    var projects: [Project] = []
    var selectedSection: SidebarSection?

    /// Computed property that extracts the project from any section variant.
    ///
    /// Returns the associated project for cards, plans, phases, or pharaoh sections.
    /// Returns nil if no section is selected.
    var selectedProject: Project? {
        switch selectedSection {
        case .cards(let project):
            return project
        case .plans(let project):
            return project
        case .phases(let project):
            return project
        case .pharaoh(let project):
            return project
        case .none:
            return nil
        }
    }

    var cards: [Card] = []
    var selectedCard: Card?

    /// Tracks whether cards are currently loading from disk.
    ///
    /// Used to prevent empty state flicker when switching between projects.
    /// When true, CardList shows a loading indicator instead of empty state.
    var isLoadingCards: Bool = false

    var phases: [Phase] = []
    var selectedPhase: Phase?

    var plans: [Plan] = []
    var selectedPlan: Plan?

    var searchText: String = ""
    var filterStatus: Set<CardStatus> = []
    var filterType: Set<CardType> = []
    var filterPriority: Set<Priority> = []
    var sortBy: CardSortOption = .updated
    var sortOrder: SortOrder = .forward
    var showDoneAndArchived: Bool = false
    var showDonePlans: Bool = false

    var searchResults: [SearchResult] = []

    var showingNewProjectSheet: Bool = false
    var showingNewCardSheet: Bool = false
    var focusSearch: Bool = false

    var pharaohModel: String = "opus"

    private let workspaceService: WorkspaceProviding
    private let fileWatcher: FileWatching?
    private let tagReconciler: TagReconciling?
    private let searchService: SearchProviding?
    private let phaseService: PhaseProviding?
    private let planService: PlanProviding?
    private let pharaohService: PharaohProviding?

    private let cardUpdateDebouncer = Debouncer(delay: 1.5)
    private var pendingCardUpdate: Card?
    private var lastDebouncedWritePath: String?

    init(
        workspaceService: WorkspaceProviding,
        fileWatcher: FileWatching? = nil,
        tagReconciler: TagReconciling? = nil,
        searchService: SearchProviding? = nil,
        phaseService: PhaseProviding? = nil,
        planService: PlanProviding? = nil,
        pharaohService: PharaohProviding? = nil
    ) {
        self.workspaceService = workspaceService
        self.fileWatcher = fileWatcher
        self.tagReconciler = tagReconciler
        self.searchService = searchService
        self.phaseService = phaseService
        self.planService = planService
        self.pharaohService = pharaohService
    }

    /// Initializes a new workspace at the specified path.
    ///
    /// Creates workspace directory, writes config, generates instructional files
    /// (CLAUDE.md and AGENT.md), and loads the workspace.
    ///
    /// - Parameter path: Absolute path to workspace directory
    func initializeWorkspace(at path: String) {
        do {
            try workspaceService.createWorkspace(at: path, configDirectory: nil)
            try workspaceService.initializeWorkspaceFiles(at: path)
            loadWorkspace()
        } catch {
            print("Failed to initialize workspace: \(error)")
        }
    }

    /// Loads workspace configuration and projects.
    ///
    /// Reads config from ~/.hieroglyphs/config.yaml, extracts workspace path,
    /// and loads all projects from the workspace directory. On error, logs to
    /// console and leaves workspacePath nil and projects empty.
    func loadWorkspace() {
        do {
            let config = try workspaceService.loadWorkspaceConfig(from: nil)
            self.workspacePath = config.workspacePath

            let loadedProjects = try workspaceService.loadProjects(
                from: config.workspacePath
            )
            self.projects = loadedProjects

            startWatching()
        } catch {
            print("Failed to load workspace: \(error)")
            self.workspacePath = nil
            self.projects = []
        }
    }

    /// Creates a new project and reloads the project list.
    ///
    /// - Parameters:
    ///   - title: Project title
    ///   - description: Project description
    ///   - tags: Project tags
    ///   - sourceDirectory: Optional path to source directory
    func createProject(
        title: String,
        description: String,
        tags: [String],
        sourceDirectory: String? = nil
    ) {
        guard let workspacePath else {
            print("Cannot create project: workspace path is nil")
            return
        }

        do {
            _ = try workspaceService.createProject(
                title: title,
                description: description,
                tags: tags,
                sourceDirectory: sourceDirectory,
                at: workspacePath
            )

            let reloadedProjects = try workspaceService.loadProjects(
                from: workspacePath
            )
            self.projects = reloadedProjects
        } catch {
            print("Failed to create project: \(error)")
        }
    }

    /// Updates an existing project and reloads the project list.
    ///
    /// - Parameter project: The updated project model
    func updateProject(_ project: Project) {
        guard let workspacePath else {
            print("Cannot update project: workspace path is nil")
            return
        }

        do {
            try workspaceService.updateProject(project, at: workspacePath)
            let reloadedProjects = try workspaceService.loadProjects(
                from: workspacePath
            )
            self.projects = reloadedProjects

            if let updatedProject = reloadedProjects.first(where: { $0.id == project.id }),
               let currentSection = selectedSection {
                switch currentSection {
                case .cards:
                    self.selectedSection = .cards(updatedProject)
                case .plans:
                    self.selectedSection = .plans(updatedProject)
                case .phases:
                    self.selectedSection = .phases(updatedProject)
                case .pharaoh:
                    self.selectedSection = .pharaoh(updatedProject)
                }
            }
        } catch {
            print("Failed to update project: \(error)")
        }
    }

    /// Deletes a project and reloads the project list.
    ///
    /// - Parameter project: The project to delete
    func deleteProject(_ project: Project) {
        guard let workspacePath else {
            print("Cannot delete project: workspace path is nil")
            return
        }

        do {
            let projectPath = "\(workspacePath)/\(project.slug)"
            try workspaceService.deleteProject(at: projectPath)
            self.selectedSection = nil
            loadProjects()
        } catch {
            print("Failed to delete project: \(error)")
        }
    }

    /// Updates the selected section.
    ///
    /// Clears cross-section selection state to ensure detail column displays
    /// content consistent with the selected section type. Clears all detail
    /// selections when the project changes.
    ///
    /// - Parameter section: The section to select
    func selectSection(_ section: SidebarSection?) {
        let oldProject = selectedProject
        self.selectedSection = section
        let newProject = selectedProject

        // If the project changed, clear all detail selections
        if oldProject?.id != newProject?.id {
            self.selectedCard = nil
            self.selectedPlan = nil
            self.selectedPhase = nil
            return
        }

        // If only the section type changed within the same project,
        // clear cross-section selections
        switch section {
        case .cards:
            self.selectedPlan = nil
            self.selectedPhase = nil
        case .plans:
            self.selectedCard = nil
            self.selectedPhase = nil
        case .phases:
            self.selectedCard = nil
            self.selectedPlan = nil
        case .pharaoh:
            self.selectedCard = nil
            self.selectedPlan = nil
            self.selectedPhase = nil
        case .none:
            self.selectedCard = nil
            self.selectedPlan = nil
            self.selectedPhase = nil
        }
    }

    /// Loads cards for the currently selected project.
    ///
    /// Reads all cards from the selected project's cards/ directory and updates
    /// the cards property. On error, logs to console and leaves cards empty.
    func loadCards() {
        isLoadingCards = true

        guard let selectedProject else {
            self.cards = []
            isLoadingCards = false
            return
        }

        guard let workspacePath else {
            print("Cannot load cards: workspace path is nil")
            self.cards = []
            isLoadingCards = false
            return
        }

        do {
            let projectPath = "\(workspacePath)/\(selectedProject.slug)"

            if let sourceDirectory = selectedProject.sourceDirectory {
                do {
                    let ingestedCount = try workspaceService.ingestCardsFromUshabti(
                        projectPath: projectPath,
                        sourceDirectory: sourceDirectory
                    )
                    if ingestedCount > 0 {
                        print("Ingested \(ingestedCount) card(s) from Ushabti")
                    }
                } catch {
                    print("Warning: Card ingestion failed: \(error)")
                }
            }

            let loadedCards = try workspaceService.loadCards(
                from: projectPath,
                for: selectedProject
            )
            self.cards = loadedCards

            // Clear selection if the selected card no longer exists
            if let selectedCard,
               !loadedCards.contains(where: { $0.id == selectedCard.id }) {
                self.selectedCard = nil
            }

            isLoadingCards = false
        } catch {
            print("Failed to load cards: \(error)")
            self.cards = []
            isLoadingCards = false
        }
    }

    /// Loads phases for the currently selected project.
    ///
    /// Reads all phases from the selected project's sourceDirectory/.ushabti/phases/
    /// and updates the phases property. Requires project to have a sourceDirectory
    /// configured. On error, logs to console and leaves phases empty.
    func loadPhases() {
        guard let selectedProject else {
            self.phases = []
            return
        }

        guard let sourceDirectory = selectedProject.sourceDirectory else {
            self.phases = []
            return
        }

        guard let phaseService else {
            print("Cannot load phases: phase service is nil")
            self.phases = []
            return
        }

        do {
            let loadedPhases = try phaseService.loadPhases(
                from: sourceDirectory
            )
            self.phases = loadedPhases

            // Clear selection if the selected phase no longer exists
            if let selectedPhase,
               !loadedPhases.contains(where: { $0.id == selectedPhase.id }) {
                self.selectedPhase = nil
            }
        } catch {
            print("Failed to load phases: \(error)")
            self.phases = []
        }
    }

    func loadPlans() {
        guard let selectedProject else {
            self.plans = []
            return
        }

        guard let workspacePath else {
            print("Cannot load plans: workspace path is nil")
            self.plans = []
            return
        }

        guard let planService else {
            print("Cannot load plans: plan service is nil")
            self.plans = []
            return
        }

        let projectPath = "\(workspacePath)/\(selectedProject.slug)"

        do {
            let loadedPlans = try planService.loadPlans(projectPath: projectPath)
            self.plans = loadedPlans

            // Clear selection if the selected plan no longer exists
            if let selectedPlan,
               !loadedPlans.contains(where: { $0.id == selectedPlan.id }) {
                self.selectedPlan = nil
            }
        } catch {
            print("Failed to load plans: \(error)")
            self.plans = []
        }
    }

    func createPlan(title: String) {
        guard let selectedProject else {
            print("Cannot create plan: no project selected")
            return
        }

        guard let workspacePath else {
            print("Cannot create plan: workspace path is nil")
            return
        }

        guard let planService else {
            print("Cannot create plan: plan service is nil")
            return
        }

        let projectPath = "\(workspacePath)/\(selectedProject.slug)"

        do {
            let number = try planService.findNextPlanNumber(projectPath: projectPath)
            _ = try planService.createPlan(
                title: title,
                number: number,
                projectPath: projectPath
            )
            loadPlans()
        } catch {
            print("Failed to create plan: \(error)")
        }
    }

    func createPlanFromCard(_ card: Card) {
        guard let selectedProject else {
            print("Cannot create plan from card: no project selected")
            return
        }

        guard let workspacePath else {
            print("Cannot create plan from card: workspace path is nil")
            return
        }

        guard let planService else {
            print("Cannot create plan from card: plan service is nil")
            return
        }

        let projectPath = "\(workspacePath)/\(selectedProject.slug)"

        do {
            let number = try planService.findNextPlanNumber(projectPath: projectPath)
            let planTitle = "Implement \(card.title)"

            let plan = try planService.createPlan(
                title: planTitle,
                number: number,
                projectPath: projectPath
            )

            try planService.addCardToPlan(
                cardSlug: card.slug,
                planSlug: plan.slug,
                projectPath: projectPath
            )

            loadPlans()
        } catch {
            print("Failed to create plan from card: \(error)")
        }
    }

    func updatePlan(_ plan: Plan) {
        guard let selectedProject else {
            print("Cannot update plan: no project selected")
            return
        }

        guard let workspacePath else {
            print("Cannot update plan: workspace path is nil")
            return
        }

        guard let planService else {
            print("Cannot update plan: plan service is nil")
            return
        }

        let projectPath = "\(workspacePath)/\(selectedProject.slug)"

        do {
            try planService.updatePlan(plan, projectPath: projectPath)
            loadPlans()
        } catch {
            print("Failed to update plan: \(error)")
        }
    }

    func addCardToPlan(cardSlug: String, planSlug: String) {
        guard let selectedProject else {
            print("Cannot add card to plan: no project selected")
            return
        }

        guard let workspacePath else {
            print("Cannot add card to plan: workspace path is nil")
            return
        }

        guard let planService else {
            print("Cannot add card to plan: plan service is nil")
            return
        }

        let projectPath = "\(workspacePath)/\(selectedProject.slug)"

        do {
            try planService.addCardToPlan(
                cardSlug: cardSlug,
                planSlug: planSlug,
                projectPath: projectPath
            )
            loadPlans()
            refreshSelectedPlan()
        } catch {
            print("Failed to add card to plan: \(error)")
        }
    }

    func addCardsToPlan(cardSlugs: [String], planSlug: String) {
        guard let selectedProject else {
            print("Cannot add cards to plan: no project selected")
            return
        }

        guard let workspacePath else {
            print("Cannot add cards to plan: workspace path is nil")
            return
        }

        guard let planService else {
            print("Cannot add cards to plan: plan service is nil")
            return
        }

        let projectPath = "\(workspacePath)/\(selectedProject.slug)"

        for cardSlug in cardSlugs {
            do {
                try planService.addCardToPlan(
                    cardSlug: cardSlug,
                    planSlug: planSlug,
                    projectPath: projectPath
                )
            } catch {
                print("Failed to add card \(cardSlug) to plan: \(error)")
            }
        }

        loadPlans()
        refreshSelectedPlan()
    }

    func removeCardFromPlan(cardSlug: String, planSlug: String) {
        guard let selectedProject else {
            print("Cannot remove card from plan: no project selected")
            return
        }

        guard let workspacePath else {
            print("Cannot remove card from plan: workspace path is nil")
            return
        }

        guard let planService else {
            print("Cannot remove card from plan: plan service is nil")
            return
        }

        let projectPath = "\(workspacePath)/\(selectedProject.slug)"

        do {
            try planService.removeCardFromPlan(
                cardSlug: cardSlug,
                planSlug: planSlug,
                projectPath: projectPath
            )
            loadPlans()
            refreshSelectedPlan()
        } catch {
            print("Failed to remove card from plan: \(error)")
        }
    }

    func updatePlanStatus(plan: Plan, status: PlanStatus) {
        guard let selectedProject else {
            print("Cannot update plan status: no project selected")
            return
        }

        guard let workspacePath else {
            print("Cannot update plan status: workspace path is nil")
            return
        }

        guard let planService else {
            print("Cannot update plan status: plan service is nil")
            return
        }

        let projectPath = "\(workspacePath)/\(selectedProject.slug)"

        do {
            try planService.updatePlanStatus(
                plan: plan,
                status: status,
                projectPath: projectPath
            )
            loadPlans()
            loadCards()
            refreshSelectedPlan()
        } catch {
            print("Failed to update plan status: \(error)")
        }
    }

    /// Refreshes selectedPlan to point to the updated Plan in the plans array.
    ///
    /// Called after reloading plans from disk following a mutation. Since Plan
    /// is a value type, the old selectedPlan and the reloaded plan are separate
    /// copies. This method finds the updated plan by slug and updates the
    /// selection to point to the fresh object.
    ///
    /// If selectedPlan is nil or the plan is no longer in the array (deleted),
    /// this method does nothing.
    private func refreshSelectedPlan() {
        guard let currentPlan = selectedPlan else { return }

        if let updatedPlan = plans.first(where: { $0.slug == currentPlan.slug }) {
            self.selectedPlan = updatedPlan
        }
    }

    func writePhasePrompt(planSlug: String, content: String) {
        guard let selectedProject else {
            print("Cannot write phase prompt: no project selected")
            return
        }

        guard let workspacePath else {
            print("Cannot write phase prompt: workspace path is nil")
            return
        }

        guard let planService else {
            print("Cannot write phase prompt: plan service is nil")
            return
        }

        let projectPath = "\(workspacePath)/\(selectedProject.slug)"

        do {
            try planService.writePhasePrompt(
                planSlug: planSlug,
                content: content,
                projectPath: projectPath
            )
        } catch {
            print("Failed to write phase prompt: \(error)")
        }
    }

    func deletePlan(_ plan: Plan) {
        guard let selectedProject else {
            print("Cannot delete plan: no project selected")
            return
        }

        guard let workspacePath else {
            print("Cannot delete plan: workspace path is nil")
            return
        }

        guard let planService else {
            print("Cannot delete plan: plan service is nil")
            return
        }

        let projectPath = "\(workspacePath)/\(selectedProject.slug)"

        do {
            try planService.deletePlan(
                planSlug: plan.slug,
                projectPath: projectPath
            )

            if selectedPlan?.id == plan.id {
                self.selectedPlan = nil
            }

            loadPlans()
        } catch {
            print("Failed to delete plan: \(error)")
        }
    }

    func dispatchPlan() {
        guard let plan = selectedPlan else {
            print("Cannot dispatch: no plan selected")
            return
        }

        guard let selectedProject else {
            print("Cannot dispatch: no project selected")
            return
        }

        guard let sourceDirectory = selectedProject.sourceDirectory else {
            print("Cannot dispatch: project has no source directory")
            return
        }

        let dispatchDirectory = "\(sourceDirectory)/.pharaoh/dispatch"
        let dispatchFilePath = "\(dispatchDirectory)/\(plan.slug).md"

        let frontmatter = """
        ---
        phase: \(plan.slug)
        model: \(pharaohModel)
        ---

        \(plan.phasePrompt)
        """

        do {
            try FileManager.default.createDirectory(
                atPath: dispatchDirectory,
                withIntermediateDirectories: true
            )

            try frontmatter.write(
                toFile: dispatchFilePath,
                atomically: true,
                encoding: .utf8
            )

            updatePlanStatus(plan: plan, status: .inProgress)
        } catch {
            print("Failed to dispatch plan: \(error)")
        }
    }

    /// Creates a new card and reloads the card list.
    ///
    /// - Parameters:
    ///   - title: Card title
    ///   - type: Card type
    ///   - status: Card status
    ///   - priority: Card priority
    ///   - tags: Card tags
    ///   - body: Markdown body content
    func createCard(
        title: String,
        type: CardType,
        status: CardStatus,
        priority: Priority,
        tags: [String],
        body: String
    ) {
        guard let selectedProject else {
            print("Cannot create card: no project selected")
            return
        }

        guard let workspacePath else {
            print("Cannot create card: workspace path is nil")
            return
        }

        do {
            let projectPath = "\(workspacePath)/\(selectedProject.slug)"
            _ = try workspaceService.createCard(
                title: title,
                type: type,
                status: status,
                priority: priority,
                tags: tags,
                body: body,
                projectPath: projectPath
            )

            loadCards()
        } catch {
            print("Failed to create card: \(error)")
        }
    }

    /// Updates an existing card and reloads the card list.
    ///
    /// Writes immediately to disk. Use for discrete actions (picker changes,
    /// tag operations) that should persist immediately.
    ///
    /// - Parameter card: The card to update
    func updateCard(_ card: Card) {
        guard let selectedProject else {
            print("Cannot update card: no project selected")
            return
        }

        guard let workspacePath else {
            print("Cannot update card: workspace path is nil")
            return
        }

        do {
            let projectPath = "\(workspacePath)/\(selectedProject.slug)"
            try workspaceService.updateCard(card, projectPath: projectPath)
            lastDebouncedWritePath = nil
            loadCards()
        } catch {
            print("Failed to update card: \(error)")
        }
    }

    /// Updates an existing card with debouncing for continuous edits.
    ///
    /// Schedules write to occur after delay. Repeated calls coalesce into single
    /// write. Use for continuous typing (title, body) to avoid lag.
    ///
    /// - Parameter card: The card to update
    func updateCardDebounced(_ card: Card) {
        pendingCardUpdate = card

        cardUpdateDebouncer.schedule { [weak self] in
            guard let self else { return }
            guard let card = self.pendingCardUpdate else { return }
            guard let selectedProject = self.selectedProject else { return }
            guard let workspacePath = self.workspacePath else { return }

            let cardPath = "\(workspacePath)/\(selectedProject.slug)/cards/\(card.slug)/card.md"
            self.lastDebouncedWritePath = cardPath

            self.updateCard(card)
            self.pendingCardUpdate = nil
        }
    }

    /// Flushes pending debounced card updates immediately.
    ///
    /// Call before card deselection or app termination to ensure all edits
    /// are persisted to disk.
    func flushPendingCardUpdates() {
        cardUpdateDebouncer.flush()
    }

    /// Starts watching workspace for external file changes.
    ///
    /// Called automatically after successful workspace load. Monitors
    /// workspace directory for changes and triggers appropriate reloads.
    func startWatching() {
        guard let workspacePath else { return }

        fileWatcher?.startWatching(path: workspacePath) { [weak self] url in
            self?.handleFileChange(url: url)
        }

        // Start phases watching if source directory is set
        if let selectedProject,
           let sourceDirectory = selectedProject.sourceDirectory {
            let phasesPath = "\(sourceDirectory)/.ushabti/phases/"

            // Only start watching if phases directory exists
            if FileManager.default.fileExists(atPath: phasesPath) {
                fileWatcher?.startWatchingPhases(path: phasesPath) { [weak self] url in
                    self?.handlePhaseFileChange(url: url)
                }
            }
        }
    }

    /// Stops watching workspace for external file changes.
    ///
    /// Called on deinit to clean up file monitoring resources.
    func stopWatching() {
        fileWatcher?.stopWatching()
        stopPhasesWatching()
    }

    /// Stops watching phases directory for external file changes.
    func stopPhasesWatching() {
        fileWatcher?.stopWatchingPhases()
    }

    /// Restarts phases watching when project selection changes.
    ///
    /// Called when selectedProject changes to update the phases watching
    /// to monitor the new project's source directory, or stop watching
    /// if the new project has no source directory set.
    func restartPhasesWatching() {
        // Stop current phases watching
        stopPhasesWatching()

        // Start phases watching for new project if it has source directory
        if let selectedProject,
           let sourceDirectory = selectedProject.sourceDirectory {
            let phasesPath = "\(sourceDirectory)/.ushabti/phases/"

            // Only start watching if phases directory exists
            if FileManager.default.fileExists(atPath: phasesPath) {
                fileWatcher?.startWatchingPhases(path: phasesPath) { [weak self] url in
                    self?.handlePhaseFileChange(url: url)
                }
            }
        }
    }

    private func handleFileChange(url: URL) {
        guard workspacePath != nil else { return }

        let path = url.path

        if path.contains("/project.md") {
            loadProjects()
            reconcileProjectTags(at: path)
        } else if path.contains("/cards/") || path.contains("/card.md") {
            if let selectedProject,
               path.contains("/\(selectedProject.slug)/") {
                if let lastWritePath = lastDebouncedWritePath,
                   path == lastWritePath {
                    lastDebouncedWritePath = nil
                    reconcileCardTags(at: path)
                    return
                }
                loadCards()
            }
            reconcileCardTags(at: path)
        } else if path.contains("/plans/") && (path.contains("/plan.yaml") || path.contains("/PHASE_PROMPT.md")) {
            if let selectedProject,
               path.contains("/\(selectedProject.slug)/") {
                loadPlans()
            }
        }
    }

    private func handlePhaseFileChange(url: URL) {
        let path = url.path

        // Check if path contains phases directory and phase files
        if path.contains("/.ushabti/phases/") && (path.contains(".yaml") || path.contains(".md")) {
            loadPhases()
        }
    }

    private func loadProjects() {
        guard let workspacePath else { return }

        do {
            let loadedProjects = try workspaceService.loadProjects(
                from: workspacePath
            )
            self.projects = loadedProjects
        } catch {
            print("Failed to reload projects: \(error)")
        }
    }

    private func reconcileProjectTags(at path: String) {
        guard let tagReconciler else { return }

        do {
            let project = try extractProjectFromPath(path)
            tagReconciler.reconcileTags(for: project.tags, at: path)
        } catch {
            print("Failed to reconcile project tags: \(error)")
        }
    }

    private func reconcileCardTags(at path: String) {
        guard let tagReconciler else { return }

        do {
            let card = try extractCardFromPath(path)
            tagReconciler.reconcileTags(for: card.tags, at: path)
        } catch {
            print("Failed to reconcile card tags: \(error)")
        }
    }

    private func extractProjectFromPath(_ path: String) throws -> Project {
        guard let workspacePath else {
            throw NSError(
                domain: "HieroglyphsVM",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Workspace path is nil"]
            )
        }

        let allProjects = try workspaceService.loadProjects(from: workspacePath)
        guard let project = allProjects.first(where: { path.contains("/\($0.slug)/") }) else {
            throw NSError(
                domain: "HieroglyphsVM",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Project not found for path"]
            )
        }

        return project
    }

    private func extractCardFromPath(_ path: String) throws -> Card {
        guard let workspacePath else {
            throw NSError(
                domain: "HieroglyphsVM",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Workspace path is nil"]
            )
        }

        let project = try extractProjectFromPath(path)
        let projectPath = "\(workspacePath)/\(project.slug)"
        let allCards = try workspaceService.loadCards(from: projectPath, for: project)

        guard let card = allCards.first(where: { path.contains("/\($0.slug)/") }) else {
            throw NSError(
                domain: "HieroglyphsVM",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Card not found for path"]
            )
        }

        return card
    }

    /// Performs a Spotlight search across workspace files.
    ///
    /// Searches file content, titles, and tags for matches. Updates
    /// searchResults property with results. Clears results if query is empty.
    ///
    /// - Parameter query: Search query string
    func performSearch(query: String) {
        guard let searchService else {
            print("Cannot perform search: search service is nil")
            return
        }

        guard !query.isEmpty else {
            self.searchResults = []
            return
        }

        guard let workspacePath else {
            print("Cannot perform search: workspace path is nil")
            self.searchResults = []
            return
        }

        searchService.performSearch(
            query: query,
            scope: workspacePath
        ) { [weak self] results in
            Task { @MainActor in
                self?.searchResults = results
            }
        }
    }

    /// Navigates to a search result by setting selection state.
    ///
    /// For project results, sets selectedProject. For card results,
    /// sets selectedProject and selectedCard, loading cards if needed.
    ///
    /// - Parameter result: The search result to navigate to
    func navigateToSearchResult(_ result: SearchResult) {
        switch result.resultType {
        case .project:
            navigateToProject(slug: result.projectSlug)

        case .card:
            navigateToCard(
                projectSlug: result.projectSlug,
                cardSlug: result.cardSlug
            )
        }
    }

    private func navigateToProject(slug: String?) {
        guard let slug else { return }

        if let project = projects.first(where: { $0.slug == slug }) {
            self.selectedSection = .cards(project)
        }
    }

    private func navigateToCard(projectSlug: String?, cardSlug: String?) {
        guard let projectSlug, let cardSlug else { return }

        if let project = projects.first(where: { $0.slug == projectSlug }) {
            self.selectedSection = .cards(project)
            loadCards()

            if let card = cards.first(where: { $0.slug == cardSlug }) {
                self.selectedCard = card
            }
        }
    }

    /// Shows the New Project sheet.
    func showNewProjectSheet() {
        self.showingNewProjectSheet = true
    }

    /// Shows the New Card sheet.
    func showNewCardSheet() {
        self.showingNewCardSheet = true
    }

    /// Deletes the currently selected item (card or project).
    ///
    /// If a card is selected, deletes the card. If only a project is selected,
    /// deletes the project. Reloads appropriate list after deletion.
    func deleteSelectedItem() {
        guard let workspacePath else {
            print("Cannot delete: workspace path is nil")
            return
        }

        if let selectedCard, let selectedProject {
            do {
                let projectPath = "\(workspacePath)/\(selectedProject.slug)"

                // Clean up plan links before trashing the card
                do {
                    try planService?.removeCardFromPlans(
                        cardSlug: selectedCard.slug,
                        projectPath: projectPath
                    )
                } catch {
                    print("Warning: Failed to clean up plan links: \(error)")
                }

                try workspaceService.deleteCard(
                    slug: selectedCard.slug,
                    projectPath: projectPath
                )
                self.selectedCard = nil
                loadCards()
                loadPlans()
            } catch {
                print("Failed to delete card: \(error)")
            }
        } else if let selectedProject {
            deleteProject(selectedProject)
        }
    }

    /// Requests focus on the search field.
    func requestSearchFocus() {
        self.focusSearch = true
    }
}
