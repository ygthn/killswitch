import SwiftUI

struct ProcessRowView: View {
    let process: AppProcessInfo
    let onForceQuit: () -> Void
    let onGracefulQuit: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            // App icon
            if let icon = process.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.quaternary)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "app.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    )
            }

            // App name
            HStack(spacing: 6) {
                Text(process.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)

                if process.isNotResponding {
                    Text("Not Responding")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(.red))
                }
            }

            Spacer()

            // Buttons on hover
            if isHovered {
                HStack(spacing: 4) {
                    Button {
                        onGracefulQuit()
                    } label: {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Quit")

                    Button {
                        onForceQuit()
                    } label: {
                        Image(systemName: "bolt.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Force Quit")
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.primary.opacity(0.06) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
