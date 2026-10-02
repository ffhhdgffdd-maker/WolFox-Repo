import Foundation

enum WolFoxSource {
    static let manifestURL = URL(string: "https://repo.p3nd.fun/source.php")!
    private static let maximumManifestBytes = 5 * 1024 * 1024

    private static func isAllowedRepositoryURL(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https",
              url.host?.lowercased() == "repo.p3nd.fun",
              url.user == nil,
              url.password == nil,
              url.port == nil || url.port == 443 else { return false }
        return true
    }

    private static func isJSONResponse(_ response: HTTPURLResponse) -> Bool {
        guard let contentType = response.value(forHTTPHeaderField: "Content-Type")?.lowercased() else { return false }
        return contentType.contains("application/json") || contentType.contains("text/json")
    }

    static func load() async throws -> Data {
        guard isAllowedRepositoryURL(manifestURL) else {
            throw URLError(.appTransportSecurityRequiresSecureConnection)
        }

        var request = URLRequest(url: manifestURL)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              http.url?.host?.lowercased() == manifestURL.host?.lowercased(),
              (200..<300).contains(http.statusCode),
              isJSONResponse(http),
              data.count <= maximumManifestBytes else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
