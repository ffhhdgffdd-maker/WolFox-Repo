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
                    Text("عرض مصدر التطبيقات")
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
