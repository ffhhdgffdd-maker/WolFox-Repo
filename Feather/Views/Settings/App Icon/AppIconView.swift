//
//  AppIconView.swift
//  Feather
//
//  Created by samara on 19.06.2025.
//

import SwiftUI
import NimbleViews

// MARK: - View extension: Model
extension AppIconView {
	struct AltIcon: Identifiable {
		var displayName: String
		var author: String
		var key: String?
		var image: UIImage
		var id: String { key ?? displayName }

		init(displayName: String, author: String, key: String? = nil) {
			self.displayName = displayName
			self.author = author
			self.key = key
			self.image = altImage(key)
		}
	}

	static func altImage(_ name: String?) -> UIImage {
		let path = Bundle.main.bundleURL.appendingPathComponent((name ?? "AppIcon60x60") + "@2x.png")
		return UIImage(contentsOfFile: path.path) ?? UIImage()
	}
}

// MARK: - View
struct AppIconView: View {
	@Binding var currentIcon: String?
	@State private var iconChangeError: String?
	@State private var isChangingIcon = false

	// dont translate
	var sections: [String: [AltIcon]] = [
		"Main": [
			AltIcon(displayName: "WolFox", author: "WolFox", key: nil),
			AltIcon(displayName: "Feather (macOS)", author: "Samara", key: "V2Mac"),
			AltIcon(displayName: "Feather v1", author: "Samara", key: "V1"),
			AltIcon(displayName: "Feather v1 (macOS)", author: "Samara", key: "V1Mac"),
			AltIcon(displayName: "Feather v0", author: "Samara", key: "V0")
		],
		"Wingio": [
			AltIcon(displayName: "Feather", author: "Wingio", key: "Wing"),
		]
	]

	// MARK: Body
	var body: some View {
		NBList(.localized("App Icon")) {
			ForEach(sections.keys.sorted(), id: \.self) { section in
				if let icons = sections[section] {
					NBSection(section) {
						ForEach(icons) { icon in
							_icon(icon: icon)
						}
					}
				}
			}
		}
		.alert("تعذر تغيير الأيقونة", isPresented: Binding(
			get: { iconChangeError != nil },
			set: { if !$0 { iconChangeError = nil } }
		)) {
			Button("حسنًا", role: .cancel) { iconChangeError = nil }
		} message: {
			Text(iconChangeError ?? "حدث خطأ غير معروف.")
		}
		.onAppear {
			currentIcon = UIApplication.shared.alternateIconName
		}
	}
}

// MARK: - View extension
extension AppIconView {
	@ViewBuilder
	private func _icon(
		icon: AppIconView.AltIcon
	) -> some View {
		Button {
			guard !isChangingIcon else { return }
			isChangingIcon = true
			UIApplication.shared.setAlternateIconName(icon.key) { error in
				DispatchQueue.main.async {
					isChangingIcon = false
					if let error {
						iconChangeError = error.localizedDescription
					} else {
						currentIcon = UIApplication.shared.alternateIconName
					}
				}
			}
		} label: {
			HStack(spacing: 18) {
				Image(uiImage: icon.image)
					.appIconStyle()

				NBTitleWithSubtitleView(
					title: icon.displayName,
					subtitle: icon.author,
					linelimit: 0
				)

				if currentIcon == icon.key {
					Image(systemName: "checkmark").bold()
				}
			}
		}
		.disabled(isChangingIcon)
	}
}
