import SwiftUI

struct AppListView: View {
    @StateObject private var store = WolFoxSourceStore()

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading && store.manifest == nil {
                    ProgressView("جاري تحميل التطبيقات…")
                } else if let message = store.errorMessage, store.manifest == nil {
                    ContentUnavailableView("تعذر تحميل المصدر", systemImage: "exclamationmark.triangle", description: Text(message))
                } else {
                    List(store.manifest?.apps ?? []) { app in
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
                                .clipShape(RoundedRectangle(cornerRadius: 12))

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
                    .refreshable { await store.refresh() }
                }
            }
            .navigationTitle("WolFox Repo")
            .task { if store.manifest == nil { await store.refresh() } }
        }
    }
}
