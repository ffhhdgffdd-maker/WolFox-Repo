import Foundation

enum WolFoxRepository {
    static let sourceURL = "https://repo.p3nd.fun/source.php"
    static let sourceLink = URL(string: sourceURL)!
    static let releaseLabel = "WolFox v6.0.0"

    // Certificate delivery remains delegated to the existing external provider.
    static let certificateProviderURL = URL(string: "https://api.nekoo.eu.org/certificate/public")!

    static let identifier = "fun.repo.p3nd.wolfoxrepo"
	static let bootstrapKey = "WolFox.didBootstrapRepository"

	static func isAllowedHTTPS(_ url: URL, hosts: Set<String>? = nil) -> Bool {
		guard url.scheme?.lowercased() == "https",
			  let host = url.host?.lowercased(),
			  !host.isEmpty,
			  url.user == nil,
			  url.password == nil,
			  url.port == nil || url.port == 443 else { return false }
		if host == "localhost" || host == "127.0.0.1" || host == "::1" || host.hasSuffix(".local") { return false }
		if let hosts, !hosts.contains(host) { return false }
		return true
	}

	static func isAllowedRepositoryURL(_ url: URL) -> Bool {
		isAllowedHTTPS(url, hosts: ["repo.p3nd.fun"])
	}

	static func isAllowedCertificateURL(_ url: URL) -> Bool {
		isAllowedHTTPS(url, hosts: ["api.nekoo.eu.org"])
	}

	static func isAllowedExternalDownload(_ url: URL) -> Bool {
		isAllowedHTTPS(url)
	}

	static func isJSONResponse(_ response: HTTPURLResponse) -> Bool {
		guard let contentType = response.value(forHTTPHeaderField: "Content-Type")?.lowercased() else { return false }
		return contentType.contains("application/json") || contentType.contains("text/json")
	}

    static func bootstrapIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: bootstrapKey) else { return }
        FR.handleSource(sourceURL) {
            UserDefaults.standard.set(true, forKey: bootstrapKey)
        }
    }

    static func refreshSource(completion: @escaping () -> Void) {
        FR.handleSource(sourceURL) {
            completion()
        }
    }
}
