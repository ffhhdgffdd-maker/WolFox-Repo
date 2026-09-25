import CoreData
import AltSourceKit
import SwiftUI
import NimbleViews
struct SourcesView: View {
 @Environment(\.horizontalSizeClass) private var horizontalSizeClass
 @StateObject var viewModel=SourcesViewModel.shared
 @State private var _searchText=""
 @FetchRequest(entity:AltSource.entity(),sortDescriptors:[NSSortDescriptor(keyPath:\AltSource.name,ascending:true)],animation:.snappy) private var _sources:FetchedResults<AltSource>
 private var _filteredSources:[AltSource]{_sources.filter{_searchText.isEmpty || ($0.name?.localizedCaseInsensitiveContains(_searchText) ?? false)}}
 var body: some View {
  NBNavigationView(.localized("Sources")) {
   NBListAdaptable {
    if !_filteredSources.isEmpty {
     Section {
      NavigationLink { SourceAppsView(object:Array(_sources),viewModel:viewModel) } label: {
       HStack(spacing:18){ Image("Repositories").appIconStyle(); NBTitleWithSubtitleView(title:.localized("WolFox"),subtitle:.localized("Applications")) }
      }.buttonStyle(.plain)
     }
     NBSection(.localized("Repository"),secondary:_filteredSources.count.description) {
      ForEach(_filteredSources){ source in NavigationLink { SourceAppsView(object:[source],viewModel:viewModel) } label:{ SourcesCellView(source:source) }.buttonStyle(.plain) }
     }
    }
   }.searchable(text:$_searchText,placement:.platform()).refreshable{await viewModel.fetchSources(_sources,refresh:true)}
  }.task(id:Array(_sources)){await viewModel.fetchSources(_sources)}
 }
}
