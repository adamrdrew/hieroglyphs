import SwiftUI

/// Modal sheet for creating a new plan.
///
/// Simple single-field modal following macOS 26 design standards:
/// - Constrained dimensions with scrollable content
/// - Semantic typography throughout
/// - Standard spacing and visual hierarchy
/// - Automatic Liquid Glass treatment on toolbar
///
/// When sourceCard is provided, the plan is created with that card already linked.
struct NewPlanSheet: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @Binding var sourceCard: Card?

    @State private var title = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                } header: {
                    Text("Plan Details")
                        .font(.headline)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Plan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePlan()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .frame(width: 400, height: 200)
    }

    private func savePlan() {
        viewModel.createPlan(title: title, sourceCard: sourceCard)
        dismiss()
    }
}
