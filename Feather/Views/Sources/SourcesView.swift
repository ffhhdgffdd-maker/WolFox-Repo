import CoreData
import AltSourceKit
import SwiftUI
import NimbleViews

struct SourcesView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject var viewModel = SourcesViewModel.shared
    @State private var searchText = ""

    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        animation: .snappy
    ) private var sources: FetchedResults<AltSource>

    private var filteredSources: [AltSource] {
        sources.filter { searchText.isEmpty || ($0.name?.localizedCaseInsensitiveContains(searchText) ?? false) }
    }

    var body: some View {
        NBNavigationView(.localized("Sources")) {
            NBListAdaptable {
                Section {
                    WolFoxSourceBadge()
                }

                Section {
                    NavigationLink {
                        WolFoxCertificateView()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "lock.shield.fill")
                                .font(.title3)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 42, height: 42)
                                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            NBTitleWithSubtitleView(title: "الشهادات", subtitle: "جلب الشهادة من الخادم الخارجي")
                        }
                    }
                    .buttonStyle(.plain)
                }

                if !filteredSources.isEmpty {
                    Section {
                        NavigationLink {
                            SourceAppsView(object: Array(sources), viewModel: viewModel)
                        } label: {
                            HStack(spacing: 18) {
                                WolFoxBrandMark(size: 40)
                                NBTitleWithSubtitleView(title: "WolFox", subtitle: "المصدر والتطبيقات")
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    NBSection(.localized("Repository"), secondary: filteredSources.count.description) {
                        ForEach(filteredSources) { source in
                            NavigationLink {
                                SourceAppsView(object: [source], viewModel: viewModel)
                            } label: {
                                SourcesCellView(source: source)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .platform())
            .refreshable { await viewModel.fetchSources(sources, refresh: true) }
        }
        .task(id: Array(sources)) { await viewModel.fetchSources(sources) }
    }
}
