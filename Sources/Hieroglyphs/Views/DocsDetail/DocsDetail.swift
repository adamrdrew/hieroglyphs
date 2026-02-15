import SwiftUI
import MarkdownUI

/// Detail column view for displaying documentation markdown.
struct DocsDetail: View {
    @Environment(HieroglyphsVM.self) private var viewModel

    var body: some View {
        Group {
            if let selectedDoc = viewModel.selectedDoc {
                ScrollView {
                    Markdown(selectedDoc.content)
                        .padding()
                }
                .id(selectedDoc.id)
                .navigationTitle(selectedDoc.displayTitle)
            } else {
                ContentUnavailableView(
                    "No Documentation Selected",
                    systemImage: "doc.text",
                    description: Text("Select a documentation file from the list to view it.")
                )
            }
        }
    }
}
