import SwiftUI

@main
struct WolFoxRepoApp: App {
    var body: some Scene {
        WindowGroup {
            AppListView()
                .tint(Color(red: 0.18, green: 0.42, blue: 1.0))
                .environment(\.layoutDirection, .rightToLeft)
        }
    }
}
