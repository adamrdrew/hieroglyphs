import SwiftUI

/// Detail column view for displaying the Pharaoh event stream.
struct PharaohActivityStreamView: View {
    let project: Project
    @Environment(\.pharaohService) private var pharaohService
    @State private var events: [PharaohEvent] = []
    @State private var autoScroll = true

    var body: some View {
        Group {
            if events.isEmpty {
                emptyState
            } else {
                eventList
            }
        }
        .navigationTitle("Activity")
        .task {
            await pollEvents()
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        ContentUnavailableView(
            "No Events",
            systemImage: "list.bullet",
            description: Text("Events will appear here when Pharaoh executes a phase.")
        )
    }

    @ViewBuilder
    private var eventList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(events) { event in
                        PharaohEventRow(event: event)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding()
            }
            .onChange(of: events) { _, _ in
                if autoScroll {
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
    }

    private func pollEvents() async {
        while !Task.isCancelled {
            guard let sourceDirectory = project.sourceDirectory,
                  let service = pharaohService else {
                try? await Task.sleep(for: .seconds(2))
                continue
            }

            events = service.readEvents(from: sourceDirectory)
            try? await Task.sleep(for: .seconds(2))
        }
    }
}
