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
            .onChange(of: events.count) { oldCount, newCount in
                if autoScroll && newCount > oldCount {
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

            let newEvents = service.readEvents(from: sourceDirectory)

            // Detect truncation (new phase started)
            if newEvents.count < events.count {
                events = newEvents
            } else if newEvents.count > events.count {
                // Append only new events
                let newItems = Array(newEvents.dropFirst(events.count))
                events.append(contentsOf: newItems)
            }
            // If counts are equal, do nothing (no change)

            try? await Task.sleep(for: .seconds(2))
        }
    }
}
