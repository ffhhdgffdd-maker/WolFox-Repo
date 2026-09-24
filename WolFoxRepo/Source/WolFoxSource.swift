import Foundation

enum WolFoxSource {
    static let manifestURL = URL(string: "https://raw.githubusercontent.com/ffhhdgffdd-maker/WolFox-Repo/main/app-repo.json")!

    static func load() async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: manifestURL)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
