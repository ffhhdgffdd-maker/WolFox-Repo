import SwiftUI

struct WolFoxOnboardingView: View {
    @AppStorage("WolFox.didFinishOnboarding") private var finished = false
    @State private var step = 0
    @State private var status = "Ready to check this device"
    @State private var checking = false

    private let pages = [
        ("Welcome to WolFox", "Set up WolFox in a few quick steps."),
        ("Applications", "Your WolFox repository and applications stay available in the app."),
        ("Device", "WolFox checks this device before retrieving its certificate."),
        ("Certificate", "Continue to retrieve and import the certificate registered for this device.")
    ]

    var body: some View {
        if finished {
            VariedTabbarView()
        } else {
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: step == 3 ? "checkmark.seal" : "iphone")
                    .font(.system(size: 64)).foregroundStyle(.blue)
                Text(pages[step].0).font(.largeTitle.bold())
                Text(pages[step].1).multilineTextAlignment(.center).foregroundStyle(.secondary).padding(.horizontal)
                if step == 3 {
                    if checking { ProgressView() }
                    Text(status).font(.footnote).multilineTextAlignment(.center)
                }
                Spacer()
                HStack {
                    Button("Skip") { finished = true }
                    Spacer()
                    Button(step == 3 ? "Continue" : "Next") {
                        if step < 3 { step += 1 } else { checkDevice() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(checking)
                }.padding()
            }
        }
    }

    private func checkDevice() {
        checking = true
        status = "Checking device…"
        WolFoxCertificateService.fetch { result in
            switch result {
            case .success(let certificate):
                status = "Certificate found. Importing…"
                WolFoxCertificateService.importCertificate(certificate) { error in
                    checking = false
                    if let error { status = error.localizedDescription }
                    else { status = "Certificate imported"; finished = true }
                }
            case .failure(let error):
                checking = false
                status = error.localizedDescription
            }
        }
    }
}
