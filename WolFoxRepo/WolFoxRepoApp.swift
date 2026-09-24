import SwiftUI

@main
struct WolFoxRepoApp: App {
    var body: some Scene {
        WindowGroup {
            AppListView()
                .tint(.blue)
                .environment(\.layoutDirection, .rightToLeft)
        }
    }
}
