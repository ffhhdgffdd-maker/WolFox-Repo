import SwiftUI

struct AppDetailsView: View {
    let app: WolFoxApp

    var latest: WolFoxVersion? { app.versions.first }

    var body: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    AsyncImage(url: URL(string: app.iconURL ?? "")) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 16).fill(.quaternary)
                    }
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading) {
                        Text(app.name).font(.title3.bold())
                        Text(app.developerName ?? "WolFox").foregroundStyle(.secondary)
                    }
                }
            }

            if let description = app.localizedDescription {
                Section("الوصف") { Text(description) }
            }

            if let version = latest {
                Section("آخر إصدار") {
                    LabeledContent("الإصدار", value: version.version)
                    if let minOS = version.minOSVersion {
                        LabeledContent("النظام", value: "iOS \(minOS)+")
                    }
                    if let url = URL(string: version.downloadURL) {
                        Link("تنزيل", destination: url)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .navigationTitle(app.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
