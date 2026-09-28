import Foundation

enum WolFoxRepository {
    static let sourceURL = "https://repo.p3nd.fun/source.php"
    static let sourceLink = URL(string: sourceURL)!

    // Certificate delivery remains delegated to the existing external provider.
    static let certificateProviderURL = URL(string: "https://api.nekoo.eu.org/certificate/public")!

    static let identifier = "fun.repo.p3nd.wolfoxrepo"
    static let bootstrapKey = "WolFox.didBootstrapRepository"

    static func bootstrapIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: bootstrapKey) else { return }
        FR.handleSource(sourceURL) {
            UserDefaults.standard.set(true, forKey: bootstrapKey)
        }
    }
}
