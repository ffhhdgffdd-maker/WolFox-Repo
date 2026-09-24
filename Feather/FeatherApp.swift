//
//  FeatherApp.swift
//  WolFox Repo
//

import SwiftUI
import Nuke
import IDeviceSwift
import OSLog

@main
struct FeatherApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let heartbeat = HeartbeatManager.shared
    @StateObject var downloadManager = DownloadManager.shared
    let storage = Storage.shared

    var body: some Scene {
        WindowGroup {
            VStack {
                DownloadHeaderView(downloadManager: downloadManager)
                VariedTabbarView()
                    .environment(\.managedObjectContext, storage.context)
                    .onOpenURL(perform: _handleURL)
            }
            .animation(.smooth, value: downloadManager.manualDownloads.description)
            .onAppear {
                if let style = UIUserInterfaceStyle(rawValue: UserDefaults.standard.integer(forKey: "Feather.userInterfaceStyle")) {
                    UIApplication.topViewController()?.view.window?.overrideUserInterfaceStyle = style
                }
                UIApplication.topViewController()?.view.window?.tintColor = UIColor(Color(hex: "#007AFF"))
            }
        }
    }

    private func _handleURL(_ url: URL) {
        if url.scheme == "feather" {
            if let fullPath = url.validatedScheme(after: "/source/") {
                FR.handleSource(fullPath) { }
            }
            if let fullPath = url.validatedScheme(after: "/install/"), let downloadURL = URL(string: fullPath) {
                _ = DownloadManager.shared.startDownload(from: downloadURL)
            }
        } else if url.pathExtension == "ipa" || url.pathExtension == "tipa" {
            if FileManager.default.isFileFromFileProvider(at: url) {
                guard url.startAccessingSecurityScopedResource() else { return }
            }
            FR.handlePackageFile(url) { _ in }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        _createPipeline()
        _createDocumentsDirectories()
        ResetView.clearWorkCache()
        _configureWolFoxSource()
        _addDefaultCertificates()
        return true
    }

    private func _createPipeline() {
        DataLoader.sharedUrlCache.diskCapacity = 0
        let pipeline = ImagePipeline {
            let config = URLSessionConfiguration.default
            config.urlCache = nil
            let dataCache = try? DataCache(name: "wolfox.repo.datacache")
            let imageCache = Nuke.ImageCache()
            dataCache?.sizeLimit = 500 * 1024 * 1024
            imageCache.costLimit = 100 * 1024 * 1024
            $0.dataCache = dataCache
            $0.imageCache = imageCache
            $0.dataLoader = DataLoader(configuration: config)
            $0.dataCachePolicy = .automatic
            $0.isStoringPreviewsInMemoryCache = false
        }
        ImagePipeline.shared = pipeline
    }

    private func _createDocumentsDirectories() {
        let fileManager = FileManager.default
        [fileManager.archives, fileManager.certificates, fileManager.signed, fileManager.unsigned].forEach {
            try? fileManager.createDirectoryIfNeeded(at: $0)
        }
    }

    private func _configureWolFoxSource() {
        let migrationKey = "WolFox.didConfigureDefaultSource"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }
        Storage.shared.deleteAllSources()
        FR.handleSource(WolFoxRepository.sourceURL) {
            UserDefaults.standard.set(true, forKey: migrationKey)
        }
    }

    private func _addDefaultCertificates() {
        guard UserDefaults.standard.bool(forKey: "feather.didImportDefaultCertificates") == false,
              let signingAssetsURL = Bundle.main.url(forResource: "signing-assets", withExtension: nil) else { return }
        do {
            let folders = try FileManager.default.contentsOfDirectory(at: signingAssetsURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for folderURL in folders where folderURL.hasDirectoryPath {
                let certName = folderURL.lastPathComponent
                let p12Url = folderURL.appendingPathComponent("cert.p12")
                let provisionUrl = folderURL.appendingPathComponent("cert.mobileprovision")
                let passwordUrl = folderURL.appendingPathComponent("cert.txt")
                guard FileManager.default.fileExists(atPath: p12Url.path),
                      FileManager.default.fileExists(atPath: provisionUrl.path),
                      FileManager.default.fileExists(atPath: passwordUrl.path) else { continue }
                let password = try String(contentsOf: passwordUrl, encoding: .utf8)
                FR.handleCertificateFiles(p12URL: p12Url, provisionURL: provisionUrl, p12Password: password, certificateName: certName, isDefault: true) { _ in }
            }
            UserDefaults.standard.set(true, forKey: "feather.didImportDefaultCertificates")
        } catch {
            Logger.misc.error("Failed to list signing-assets: \(error)")
        }
    }
}
