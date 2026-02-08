import SwiftUI

/// Modal sheet for creating a new plan.
struct NewPlanSheet: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var number = 1

    var body: some View {
        NavigationStack {
            Form {
                Section("Plan Details") {
                    TextField("Title", text: $title)

                    TextField("Number", value: $number, format: .number)
                }
            }
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
        .frame(minWidth: 400, minHeight: 200)
    }

    private func savePlan() {
        viewModel.createPlan(title: title, number: number)
        dismiss()
    }
}
