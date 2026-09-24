import Foundation

enum WolFoxRepository {
    static let sourceURL = "https://raw.githubusercontent.com/ffhhdgffdd-maker/WolFox-Repo/main/app-repo.json"
    static let identifier = "fun.repo.p3nd.wolfoxrepo"
    static let bootstrapKey = "WolFox.didBootstrapRepository"

    static func bootstrapIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: bootstrapKey) else { return }
        FR.handleSource(sourceURL) {
            UserDefaults.standard.set(true, forKey: bootstrapKey)
        }
    }
}
