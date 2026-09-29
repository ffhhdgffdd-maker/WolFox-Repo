import SwiftUI
import UIKit

struct WolFoxCertificateView: View {
    @State private var phase: FetchPhase = .ready
    @State private var copiedDeviceIdentifier = false
    @State private var presentsUDIDEditor = false
    @State private var suppliedUDID = ""
    @State private var udidError: String?
    @State private var pendingCertificate: WolFoxRemoteCertificate?
    @State private var presentsImportPassword = false

    private var isWorking: Bool {
        switch phase {
        case .loading, .importing, .awaitingPassword:
            return true
        default:
            return false
        }
    }

    private var identifierMode: String {
        WolFoxCertificateService.usesRegisteredUDID ? "UDID مسجل" : "معرف تثبيت WolFox"
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

                VStack(alignment: .leading, spacing: 7) {
                    Text("تفعيل جهاز عبر UDID")
                        .font(.subheadline.bold())
                    Text("لا يستطيع iOS كشف UDID العتادي من داخل التطبيق. إن كان خادم الشهادات يتطلب UDID، انسخه من Finder أو Xcode أو سجل اقتران موثوق، ثم الصقه هنا بموافقتك.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("بعد حفظ UDID، يستخدم WolFox هذا المعرّف فقط عند طلب الشهادة من الخادم.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)
                .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

                VStack(alignment: .leading, spacing: 7) {
                    Label("تنبيه أمني بشأن ملفات التعريف", systemImage: "exclamationmark.shield.fill")
                        .font(.subheadline.bold())
                    Text("لا تثبّت ملف إعدادات (.mobileconfig) للحصول على UDID؛ فقد يطلب معرّفات مثل IMEI وICCID ويرسلها إلى خادم خارجي. WolFox لا يحتاج إلى تثبيت ملف تعريف ولا يطلب IMEI أو ICCID. عند طلب الشهادة، يتضمن طلب WolFox المعرّف الظاهر هنا ويرسله إلى خادم الشهادات المعروض أعلاه.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)
                .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

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
                .sheet(isPresented: $presentsImportPassword) {
                    if let certificate = pendingCertificate {
                        WolFoxCertificateImportPasswordSheet(
                            certificate: certificate,
                            onCancel: {
                                pendingCertificate = nil
                                phase = .ready
                            },
                            onImported: {
                                pendingCertificate = nil
                                phase = .success(certificate.devName ?? "تم استيراد الشهادة")
                            }
                        )
                    }
                }

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
        .sheet(isPresented: $presentsUDIDEditor) {
            udidEditor
        }
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
                Text(identifierMode)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(WolFoxCertificateService.maskedLookupIdentifier())
                    .font(.subheadline.weight(.medium))
            }
            Spacer(minLength: 0)
            Button {
                UIPasteboard.general.string = WolFoxCertificateService.certificateLookupIdentifier()
                copiedDeviceIdentifier = true
            } label: {
                Image(systemName: copiedDeviceIdentifier ? "checkmark" : "doc.on.doc")
            }
            .buttonStyle(.bordered)
            .accessibilityLabel(copiedDeviceIdentifier ? "تم نسخ المعرّف" : "نسخ المعرّف")

            Button {
                suppliedUDID = WolFoxCertificateService.registeredUDID ?? ""
                udidError = nil
                presentsUDIDEditor = true
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("إدخال أو تعديل UDID")
        }
    }

    private var udidEditor: some View {
        NavigationStack {
            Form {
                Section("UDID") {
                    TextField("الصق UDID هنا", text: $suppliedUDID)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .keyboardType(.asciiCapable)
                    if let udidError {
                        Text(udidError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Text("يُحفظ هذا المعرف محليًا داخل WolFox ويُرسل فقط إلى خادم الشهادات عند الضغط على زر الجلب.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if WolFoxCertificateService.usesRegisteredUDID {
                    Section {
                        Button("إزالة UDID والعودة إلى معرف WolFox", role: .destructive) {
                            WolFoxCertificateService.clearRegisteredUDID()
                            presentsUDIDEditor = false
                        }
                    }
                }
            }
            .navigationTitle("UDID الجهاز")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { presentsUDIDEditor = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") { saveUDID() }
                }
            }
        }
    }

    private func saveUDID() {
        guard WolFoxCertificateService.saveRegisteredUDID(suppliedUDID) else {
            udidError = "أدخل UDID صالحًا (16–64 حرفًا أو رقمًا، دون مسافات)."
            return
        }
        copiedDeviceIdentifier = false
        presentsUDIDEditor = false
        phase = .ready
    }

    private func fetchFromServer() {
        phase = .loading
        WolFoxCertificateService.fetch { result in
            switch result {
            case .success(let certificate):
                pendingCertificate = certificate
                phase = .awaitingPassword
                presentsImportPassword = true
            case .failure(let error):
                phase = .failure(error.localizedDescription)
            }
        }
    }

    private enum FetchPhase {
        case ready
        case loading
        case importing(String)
        case awaitingPassword
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
            case .awaitingPassword:
                return "أدخل كلمة مرور ملف P12 في النافذة لإكمال الاستيراد."
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
            case .loading, .importing, .awaitingPassword:
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
            case .loading, .importing, .awaitingPassword:
                return .orange
            case .success:
                return .green
            case .failure:
                return .red
            }
        }
    }
}
