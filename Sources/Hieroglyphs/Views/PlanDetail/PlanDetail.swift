import SwiftUI

/// Detail column view for displaying and editing a selected plan.
struct PlanDetail: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.pharaohService) private var pharaohService
    @State private var showingAddCardSheet = false
    @State private var phasePromptContent = ""
    @State private var showingDispatchConfirmation = false

    private var isEditable: Bool {
        viewModel.selectedPlan?.status != .inProgress
    }

    private var canDispatch: Bool {
        guard let plan = viewModel.selectedPlan,
              let project = viewModel.selectedProject,
              project.sourceDirectory != nil,
              plan.status == .ready,
              !plan.phasePrompt.isEmpty else {
            return false
        }

        guard let sourceDirectory = project.sourceDirectory,
              let service = pharaohService else {
            return false
        }

        let status = service.readStatus(from: sourceDirectory)
        return status.isIdle
    }

    var body: some View {
        Group {
            if let plan = viewModel.selectedPlan {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        planMetadataSection(plan: plan)
                        Divider()
                        linkedCardsSection(plan: plan)
                        Divider()
                        phasePromptSection(plan: plan)
                    }
                    .padding()
                }
                .navigationTitle("Plan \(String(format: "%04d", plan.number)): \(plan.title)")
                .toolbar {
                    dispatchToolbarItem
                }
                .alert("Run this plan with Pharaoh?", isPresented: $showingDispatchConfirmation) {
                    dispatchAlertButtons
                } message: {
                    dispatchAlertMessage
                }
                .onAppear {
                    phasePromptContent = plan.phasePrompt
                }
                .onChange(of: viewModel.selectedProject) { _, _ in
                    showingAddCardSheet = false
                    showingDispatchConfirmation = false
                }
                .onChange(of: viewModel.selectedPlan) { _, newPlan in
                    phasePromptContent = newPlan?.phasePrompt ?? ""
                }
            } else {
                ContentUnavailableView(
                    "No Plan Selected",
                    systemImage: "list.bullet.clipboard",
                    description: Text("Select a plan from the list to view and edit it.")
                )
            }
        }
        .sheet(isPresented: $showingAddCardSheet) {
            if let plan = viewModel.selectedPlan {
                AddCardToPlanSheet(plan: plan)
            }
        }
    }

    @ViewBuilder
    private func planMetadataSection(plan: Plan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plan Details")
                .font(.headline)

            HStack {
                Text("Status:")
                    .foregroundStyle(.secondary)

                Picker("Status", selection: statusBinding(plan: plan)) {
                    ForEach(PlanStatus.allCases, id: \.self) { status in
                        Text(status.rawValue.capitalized)
                            .tag(status)
                    }
                }
                .pickerStyle(.menu)
            }

            HStack {
                Text("Created:")
                    .foregroundStyle(.secondary)
                Text(plan.created, style: .date)
            }

            HStack {
                Text("Updated:")
                    .foregroundStyle(.secondary)
                Text(plan.updated, style: .date)
            }
        }
    }

    @ViewBuilder
    private func linkedCardsSection(plan: Plan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Linked Cards")
                    .font(.headline)

                Spacer()

                if isEditable {
                    Button {
                        showingAddCardSheet = true
                    } label: {
                        Label("Add Card", systemImage: "plus")
                    }
                }
            }

            if plan.linkedCardSlugs.isEmpty {
                Text("No cards linked to this plan.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(plan.linkedCardSlugs, id: \.self) { cardSlug in
                    linkedCardRow(cardSlug: cardSlug, plan: plan)
                }
            }
        }
    }

    @ViewBuilder
    private func linkedCardRow(cardSlug: String, plan: Plan) -> some View {
        if let card = viewModel.cards.first(where: { $0.slug == cardSlug }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.title)
                        .font(.body)

                    HStack(spacing: 8) {
                        Text(card.status.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(card.priority.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    navigateToCard(card: card)
                } label: {
                    Image(systemName: "doc.text")
                }
                .buttonStyle(.borderless)
                .help("View Card")

                if isEditable {
                    Button(role: .destructive) {
                        viewModel.removeCardFromPlan(
                            cardSlug: cardSlug,
                            planSlug: plan.slug
                        )
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(.borderless)
                    .help("Remove from Plan")
                }
            }
            .padding(.vertical, 4)
            .contextMenu {
                Button("View Card") {
                    navigateToCard(card: card)
                }

                if isEditable {
                    Button("Remove from Plan", role: .destructive) {
                        viewModel.removeCardFromPlan(
                            cardSlug: cardSlug,
                            planSlug: plan.slug
                        )
                    }
                }
            }
        } else {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text("Missing: \(cardSlug)")
                    .foregroundStyle(.secondary)

                Spacer()

                if isEditable {
                    Button(role: .destructive) {
                        viewModel.removeCardFromPlan(
                            cardSlug: cardSlug,
                            planSlug: plan.slug
                        )
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(.borderless)
                    .help("Remove from Plan")
                }
            }
            .padding(.vertical, 4)
            .contextMenu {
                if isEditable {
                    Button("Remove from Plan", role: .destructive) {
                        viewModel.removeCardFromPlan(
                            cardSlug: cardSlug,
                            planSlug: plan.slug
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func phasePromptSection(plan: Plan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Phase Prompt")
                    .font(.headline)

                if !isEditable {
                    Text("(Plan is executing...)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            TextEditor(text: $phasePromptContent)
                .frame(minHeight: 200)
                .font(.body.monospaced())
                .border(Color.secondary.opacity(0.2))
                .disabled(!isEditable)
                .onChange(of: phasePromptContent) { _, newValue in
                    if isEditable {
                        viewModel.writePhasePrompt(
                            planSlug: plan.slug,
                            content: newValue
                        )
                    }
                }

            Button {
                // Placeholder for future generation logic
            } label: {
                Label("Generate Phase Prompt", systemImage: "wand.and.stars")
            }
            .disabled(true)
        }
    }

    private func statusBinding(plan: Plan) -> Binding<PlanStatus> {
        Binding(
            get: { plan.status },
            set: { newStatus in
                viewModel.updatePlanStatus(plan: plan, status: newStatus)
            }
        )
    }

    private func navigateToCard(card: Card) {
        guard let project = viewModel.selectedProject else { return }
        viewModel.selectedSection = .cards(project)
        viewModel.selectedCard = card
    }

    @ToolbarContentBuilder
    private var dispatchToolbarItem: some ToolbarContent {
        if canDispatch {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingDispatchConfirmation = true
                } label: {
                    Label("Dispatch to Pharaoh", systemImage: "play.circle.fill")
                }
                .help("Send this plan to Pharaoh for execution")
            }
        }
    }

    @ViewBuilder
    private var dispatchAlertButtons: some View {
        Button("Cancel", role: .cancel) { }
        Button("Run") {
            viewModel.dispatchPlan()
        }
    }

    @ViewBuilder
    private var dispatchAlertMessage: some View {
        Text("This will execute the plan's phase prompt using Pharaoh and set the plan status to In Progress.")
    }
}
