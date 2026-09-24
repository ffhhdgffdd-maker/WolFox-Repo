import Foundation

@MainActor
final class WolFoxSourceStore: ObservableObject {
    @Published var manifest: WolFoxManifest?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let data = try await WolFoxSource.load()
            manifest = try JSONDecoder().decode(WolFoxManifest.self, from: data)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
