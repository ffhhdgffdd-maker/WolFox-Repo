import SwiftUI
struct AppearanceTintColorView: View {
 @AppStorage("Feather.userTintColor") private var _selectedColorHex: String = "#007AFF"
 private let _tintOptions=[("WolFox","#007AFF"),("Cool Blue","#4161F1"),("Peculiar","#4860e8"),("Very Peculiar","#5394F7")]
 var body: some View {
  ScrollView(.horizontal, showsIndicators:false) {
   LazyHGrid(rows:[GridItem(.fixed(100))],spacing:12) {
    ForEach(_tintOptions,id:\.1){ option in
     let color=Color(hex:option.1)
     VStack(spacing:8){ Circle().fill(color).frame(width:30,height:30); Text(option.0).font(.subheadline).foregroundColor(.secondary) }
      .frame(width:120,height:100).background(Color(uiColor:.secondarySystemGroupedBackground))
      .clipShape(RoundedRectangle(cornerRadius:10.5,style:.continuous)).onTapGesture{_selectedColorHex=option.1}
    }
   }
  }.onChange(of:_selectedColorHex){ value in UIApplication.topViewController()?.view.window?.tintColor=UIColor(Color(hex:value)) }
 }
}
