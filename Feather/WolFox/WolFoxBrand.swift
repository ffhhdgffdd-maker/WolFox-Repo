import SwiftUI

struct WolFoxBrandMark: View {
    var size: CGFloat = 88

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.06, green: 0.16, blue: 0.42), Color(red: 0.10, green: 0.34, blue: 0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: "bolt.fill")
                .font(.system(size: size * 0.43, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.40, green: 0.78, blue: 1.0), Color(red: 0.67, green: 1.0, blue: 0.30)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.22), radius: 5, y: 4)

            Image(systemName: "chevron.compact.up")
                .font(.system(size: size * 0.46, weight: .black))
                .foregroundStyle(.white.opacity(0.84))
                .offset(y: size * 0.17)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("WolFox")
    }
}

struct WolFoxSourceBadge: View {
    var body: some View {
        Link(destination: WolFoxRepository.sourceLink) {
            HStack(spacing: 12) {
                WolFoxBrandMark(size: 42)
                VStack(alignment: .leading, spacing: 3) {
                    Text("WolFox Repo")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("مصدر التطبيقات الموثوق")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.forward.square")
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .accessibilityHint("يفتح رابط مصدر WolFox في المتصفح")
    }
}

struct WolFoxConnectionCard: View {
    @State private var isSyncing = false
    @State private var detail = "المصدر جاهز لتحديث الكتالوج"

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "shareplay")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color(red: 0.16, green: 0.80, blue: 0.38))
                .frame(width: 42, height: 42)
                .background(Color(red: 0.16, green: 0.80, blue: 0.38).opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("دمج WolFox v6.0.0")
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Button {
                syncRepository()
            } label: {
                if isSyncing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.body.weight(.semibold))
                }
            }
            .buttonStyle(.bordered)
            .tint(Color.accentColor)
            .disabled(isSyncing)
            .accessibilityLabel("تحديث مصدر WolFox")
        }
        .padding(.vertical, 3)
    }

    private func syncRepository() {
        isSyncing = true
        detail = "جارٍ مزامنة مصدر WolFox…"
        WolFoxRepository.refreshSource {
            DispatchQueue.main.async {
                isSyncing = false
                detail = "تم تحديث الكتالوج من repo.p3nd.fun"
            }
        }
    }
}
