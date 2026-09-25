import SwiftUI
import UIKit
import IDeviceSwift

struct WolFoxDeviceInfoView: View {
    @State private var installID = Self.installIdentifier()

    var body: some View {
        Form {
            Section("Device Information") {
                row("Model", MobileGestalt().getStringForName("PhysicalHardwareNameString") ?? UIDevice.current.model)
                row("iOS", UIDevice.current.systemVersion)
                row("Device Name", UIDevice.current.name)
                row("WolFox ID", installID)
            }
            Section {
                Text("WolFox ID is an app installation identifier. The app does not expose a protected hardware UDID.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Device")
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary).textSelection(.enabled)
        }
    }

    private static func installIdentifier() -> String {
        let key = "WolFox.installIdentifier"
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty { return existing }
        let value = UUID().uuidString
        UserDefaults.standard.set(value, forKey: key)
        return value
    }
}
