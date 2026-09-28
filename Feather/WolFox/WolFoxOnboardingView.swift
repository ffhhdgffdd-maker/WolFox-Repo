import SwiftUI

struct WolFoxOnboardingView: View {
    @AppStorage("WolFox.didFinishOnboarding") private var finished = false
    @State private var step = 0
    @State private var status = "جاهز للتحقق من هذا الجهاز"
    @State private var checking = false

    private let pages = [
        Page(icon: "sparkles", title: "أهلًا بك في WolFox v6", detail: "منصة واحدة لإدارة التطبيقات المصرح بها والوصول إلى مصادرها الموثوقة."),
        Page(icon: "personalhotspot", title: "دمج مباشر للمصدر", detail: "يتصل WolFox مباشرةً بمصدر repo.p3nd.fun، ويمكن مزامنة الكتالوج يدويًا من تبويب المصادر."),
        Page(icon: "lock.shield.fill", title: "شهادات عبر مزود خارجي", detail: "تُسترجع شهادتك من مزود الشهادات الخارجي المعتمد؛ لا تُخزَّن بيانات الشهادات في مصدر التطبيقات."),
        Page(icon: "checkmark.seal.fill", title: "تحقق من جهازك", detail: "سنبحث عن الشهادة المسجلة لهذا الجهاز ونستوردها عند توفرها.")
    ]

    var body: some View {
        if finished {
            VariedTabbarView()
                .tint(Color(red: 0.18, green: 0.42, blue: 1.0))
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.03, green: 0.07, blue: 0.18), Color(red: 0.05, green: 0.17, blue: 0.42)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    HStack {
                        Text("WOLFOX")
                            .font(.caption.weight(.black))
                            .tracking(2)
                            .foregroundStyle(Color(red: 0.67, green: 1.0, blue: 0.30))
                        Spacer()
                        Text("\(step + 1) / \(pages.count)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer(minLength: 8)

                    WolFoxBrandMark(size: 102)
                        .shadow(color: Color.black.opacity(0.28), radius: 20, y: 12)

                    VStack(spacing: 12) {
                        Image(systemName: pages[step].icon)
                            .font(.system(size: 25, weight: .semibold))
                            .foregroundStyle(Color(red: 0.67, green: 1.0, blue: 0.30))
                        Text(pages[step].title)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                        Text(pages[step].detail)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if step == 1 {
                        Link(destination: WolFoxRepository.sourceLink) {
                            Label("عرض رابط المصدر", systemImage: "arrow.up.forward.square")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color(red: 0.67, green: 1.0, blue: 0.30))
                        }
                    }

                    if step == pages.count - 1 {
                        VStack(spacing: 8) {
                            if checking {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(status)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .frame(minHeight: 44)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        Button("تخطي الآن") { finished = true }
                            .buttonStyle(.bordered)
                            .tint(.white.opacity(0.85))

                        Button(step == pages.count - 1 ? "جلب الشهادة من الخادم" : "التالي") {
                            if step < pages.count - 1 {
                                withAnimation(.snappy) { step += 1 }
                            } else {
                                checkDevice()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.18, green: 0.42, blue: 1.0))
                        .disabled(checking)
                    }
                }
                .padding(24)
                .frame(maxWidth: 540)
            }
            .preferredColorScheme(.dark)
        }
    }

    private func checkDevice() {
        checking = true
        status = "جارٍ الاتصال بمزود الشهادات الخارجي…"
        WolFoxCertificateService.fetch { result in
            switch result {
            case .success(let certificate):
                status = "تم العثور على الشهادة، جارٍ الاستيراد…"
                WolFoxCertificateService.importCertificate(certificate) { error in
                    checking = false
                    if let error {
                        status = error.localizedDescription
                    } else {
                        status = "تم استيراد الشهادة بنجاح"
                        finished = true
                    }
                }
            case .failure(let error):
                checking = false
                status = error.localizedDescription
            }
        }
    }

    private struct Page {
        let icon: String
        let title: String
        let detail: String
    }
}
