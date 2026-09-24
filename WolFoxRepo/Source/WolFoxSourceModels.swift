import Foundation

struct WolFoxManifest: Codable {
    let name: String
    let identifier: String
    let subtitle: String?
    let description: String?
    let website: String?
    let tintColor: String?
    let apps: [WolFoxApp]
}

struct WolFoxApp: Codable, Identifiable {
    var id: String { bundleIdentifier }
    let name: String
    let bundleIdentifier: String
    let developerName: String?
    let subtitle: String?
    let localizedDescription: String?
    let iconURL: String?
    let tintColor: String?
    let category: String?
    let versions: [WolFoxVersion]
}

struct WolFoxVersion: Codable {
    let version: String
    let buildVersion: String?
    let date: String?
    let localizedDescription: String?
    let downloadURL: String
    let size: Int?
    let minOSVersion: String?
}
