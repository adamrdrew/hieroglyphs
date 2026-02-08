import SwiftUI

/// Detail column view for displaying and editing a selected plan.
struct PlanDetail: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @State private var showingAddCardSheet = false
    @State private var phasePromptContent = ""

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
                .onAppear {
                    phasePromptContent = plan.phasePrompt
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

                Button {
                    showingAddCardSheet = true
                } label: {
                    Label("Add Card", systemImage: "plus")
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
            .padding(.vertical, 4)
            .contextMenu {
                Button("View Card") {
                    navigateToCard(card: card)
                }

                Button("Remove from Plan", role: .destructive) {
                    viewModel.removeCardFromPlan(
                        cardSlug: cardSlug,
                        planSlug: plan.slug
                    )
                }
            }
        } else {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text("Missing: \(cardSlug)")
                    .foregroundStyle(.secondary)

                Spacer()

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
            .padding(.vertical, 4)
            .contextMenu {
                Button("Remove from Plan", role: .destructive) {
                    viewModel.removeCardFromPlan(
                        cardSlug: cardSlug,
                        planSlug: plan.slug
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func phasePromptSection(plan: Plan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Phase Prompt")
                .font(.headline)

            TextEditor(text: $phasePromptContent)
                .frame(minHeight: 200)
                .font(.body.monospaced())
                .border(Color.secondary.opacity(0.2))
                .onChange(of: phasePromptContent) { _, newValue in
                    viewModel.writePhasePrompt(
                        planSlug: plan.slug,
                        content: newValue
                    )
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
}
