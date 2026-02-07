import SwiftUI

struct MainWindow: View {
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
            Sidebar()
        } content: {
            CardList()
        } detail: {
            Text("Detail")
        }
    }
}
