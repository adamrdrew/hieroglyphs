import SwiftUI

struct MainWindow: View {
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
            Text("Sidebar")
        } content: {
            Text("List")
        } detail: {
            Text("Detail")
        }
    }
}
