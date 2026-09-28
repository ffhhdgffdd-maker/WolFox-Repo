import SwiftUI
import UIKit

struct WolFoxCertificateView: View {
    @State private var phase: FetchPhase = .ready
    @State private var copiedDeviceIdentifier = false

    private var isWorking: Bool {
        switch phase {
        case .loading, .importing:
            return true
        default:
            return false
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 14) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(Color(red: 0.18, green: 0.42, blue: 1.0))

                    Text("شهادات WolFox")
                        .font(.title2.bold())
                    Text("يجلب WolFox الشهادة المسجلة لجهازك من المزوّد الخارجي ثم يتحقق منها قبل الاستيراد.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 12) {
                    certificateRow(title: "خادم الشهادات", value: WolFoxCertificateService.providerName, icon: "network")
                    Divider()
                    deviceRegistrationRow
                    Divider()
                    certificateRow(title: "طريقة الحماية", value: "تحقق ثم استيراد محلي", icon: "checkmark.shield")
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text("تفعيل جهاز جديد")
                        .font(.subheadline.bold())
                    Text("انسخ معرف الجهاز، سجّله لدى مزوّد الشهادات الخارجي، ثم اضغط «جلب الشهادة من الخادم». لا تُرسل ملفات P12 أو كلمات المرور داخل التطبيق.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)
                .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

                Button(action: fetchFromServer) {
                    HStack(spacing: 9) {
                        if isWorking {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        Text(isWorking ? phase.buttonTitle : "جلب الشهادة من الخادم")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.18, green: 0.42, blue: 1.0))
                .disabled(isWorking)

                statusCard

                Text("لا يعرض WolFox أو يشارك محتوى الشهادة في الواجهة. التسجيل يتم لدى المزوّد الخارجي، بينما يستورد WolFox الشهادة المسجلة فقط بعد التحقق.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
            }
            .padding(20)
        }
        .navigationTitle("الشهادات")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: phase.icon)
                .foregroundStyle(phase.color)
                .font(.title3)
            Text(phase.message)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(15)
        .background(phase.color.opacity(0.10), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private func certificateRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .textSelection(.enabled)
            }
            Spacer(minLength: 0)
        }
    }

    private var deviceRegistrationRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "iphone")
                .frame(width: 20)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text("معرف تسجيل الجهاز")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(WolFoxCertificateService.maskedDeviceIdentifier())
                    .font(.subheadline.weight(.medium))
            }
            Spacer(minLength: 0)
            Button {
                UIPasteboard.general.string = WolFoxCertificateService.deviceIdentifier()
                copiedDeviceIdentifier = true
            } label: {
                Label(copiedDeviceIdentifier ? "تم النسخ" : "نسخ", systemImage: copiedDeviceIdentifier ? "checkmark" : "doc.on.doc")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel(copiedDeviceIdentifier ? "تم نسخ معرف الجهاز" : "نسخ معرف الجهاز")
        }
    }

    private func fetchFromServer() {
        phase = .loading
        WolFoxCertificateService.fetch { result in
            switch result {
            case .success(let certificate):
                phase = .importing(certificate.devName ?? "الشهادة المسجلة")
                WolFoxCertificateService.importCertificate(certificate) { error in
                    DispatchQueue.main.async {
                        if let error {
                            phase = .failure(error.localizedDescription)
                        } else {
                            phase = .success(certificate.devName ?? "تم استيراد الشهادة")
                        }
                    }
                }
            case .failure(let error):
                phase = .failure(error.localizedDescription)
            }
        }
    }

    private enum FetchPhase {
        case ready
        case loading
        case importing(String)
        case success(String)
        case failure(String)

        var message: String {
            switch self {
            case .ready:
                return "اضغط «جلب الشهادة من الخادم» للتحقق من شهادة هذا الجهاز."
            case .loading:
                return "جارٍ الاتصال بخادم الشهادات الخارجي…"
            case .importing(let name):
                return "تم العثور على \(name). جارٍ التحقق والاستيراد…"
            case .success(let name):
                return "نجح الاستيراد: \(name)."
            case .failure(let reason):
                return reason
            }
        }

        var buttonTitle: String {
            switch self {
            case .loading:
                return "جارٍ الجلب…"
            case .importing:
                return "جارٍ الاستيراد…"
            default:
                return ""
            }
        }

        var icon: String {
            switch self {
            case .ready:
                return "info.circle.fill"
            case .loading, .importing:
                return "arrow.triangle.2.circlepath"
            case .success:
                return "checkmark.seal.fill"
            case .failure:
                return "exclamationmark.triangle.fill"
            }
        }

        var color: Color {
            switch self {
            case .ready:
                return .blue
            case .loading, .importing:
                return .orange
            case .success:
                return .green
            case .failure:
                return .red
            }
        }
    }
}
