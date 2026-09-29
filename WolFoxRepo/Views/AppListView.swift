import SwiftUI

struct AppListView: View {
    @StateObject private var store = WolFoxSourceStore()
    private let sourceURL = URL(string: "https://repo.p3nd.fun/source.php")!
    private let brandURL = URL(string: "https://repo.p3nd.fun/assets/wolfox-mark.png")!
    private var androidApps: [WolFoxApp] {
        (store.manifest?.apps ?? []).filter { ($0.platform ?? "android").lowercased() == "android" }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading && store.manifest == nil {
                    ProgressView("جاري تحميل التطبيقات…")
                } else if let message = store.errorMessage, store.manifest == nil {
                    ContentUnavailableView("تعذر تحميل المصدر", systemImage: "exclamationmark.triangle", description: Text(message))
                } else {
                    List {
                        Section {
                            HStack(spacing: 14) {
                                AsyncImage(url: brandURL) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 18).fill(Color.blue.opacity(0.2))
                                }
                                .frame(width: 70, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                                VStack(alignment: .leading, spacing: 5) {
                                    Text("WolFox Repo")
                                        .font(.title3.bold())
                                    Text(store.manifest?.subtitle ?? "متجر WolFox لتطبيقات Android")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                    Link("فتح رابط المصدر", destination: sourceURL)
                                        .font(.caption.weight(.semibold))
                                    Text("Android فقط • APK موثوق")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.vertical, 5)
                        }

                        Section("التطبيقات المنشورة") {
                            ForEach(androidApps) { app in
                                NavigationLink {
                                    AppDetailsView(app: app)
                                } label: {
                                    HStack(spacing: 12) {
                                        AsyncImage(url: URL(string: app.iconURL ?? "")) { image in
                                            image.resizable().scaledToFill()
                                        } placeholder: {
                                            RoundedRectangle(cornerRadius: 12).fill(.quaternary)
                                        }
                                        .frame(width: 54, height: 54)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(app.name).font(.headline)
                                            Text(app.subtitle ?? app.bundleIdentifier)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await store.refresh() }
                }
            }
            .navigationTitle("WolFox Repo")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Link(destination: sourceURL) {
                        Image(systemName: "arrow.up.forward.square")
                    }
                }
            }
            .task { if store.manifest == nil { await store.refresh() } }
        }
    }
}
