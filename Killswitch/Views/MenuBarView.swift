import SwiftUI

struct MenuBarView: View {
    @ObservedObject var processService: ProcessService
    @State private var searchText = ""
    @State private var showConfirmation: pid_t? = nil
    @AppStorage("panelHeight") private var panelHeight: Double = 400

    var filteredProcesses: [AppProcessInfo] {
        if searchText.isEmpty {
            return processService.processes
        }
        return processService.processes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search
            SearchBarView(searchText: $searchText)
                .padding(.top, 8)
                .padding(.bottom, 6)

            Divider().padding(.horizontal, 8)

            // Quit failure banner
            if case .failed(let failedPid) = processService.quitStatus {
                let failedName = processService.processes.first(where: { $0.id == failedPid })?.name ?? "App"
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.orange)
                        Text("\(failedName) kapatılamadı")
                            .font(.system(size: 12, weight: .medium))
                    }

                    Text("Uygulama yanıt vermiyor. Activity Monitor ile kapatabilirsiniz.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 8) {
                        Button("Kapat") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                processService.dismissFailure()
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))

                        Button("Activity Monitor") {
                            processService.openActivityMonitor()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(.orange))
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.orange.opacity(0.2), lineWidth: 1))
                )
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Quitting indicator
            if processService.quitStatus == .quitting {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Kapatılıyor...")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            // List (fixed height)
            ScrollView {
                if filteredProcesses.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 28))
                            .foregroundStyle(.tertiary)
                        Text(searchText.isEmpty ? "No apps" : "No match")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredProcesses) { process in
                            if showConfirmation == process.id {
                                confirmationView(for: process)
                            } else {
                                ProcessRowView(
                                    process: process,
                                    onForceQuit: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showConfirmation = process.id
                                        }
                                    },
                                    onGracefulQuit: {
                                        processService.gracefulQuit(pid: process.id)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .frame(height: panelHeight)

            Divider().padding(.horizontal, 8)

            // Resize handle
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        panelHeight = max(200, panelHeight - 100)
                    }
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Smaller")

                Text("\(Int(panelHeight))pt")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.tertiary)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        panelHeight = min(800, panelHeight + 100)
                    }
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Bigger")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)

            Divider().padding(.horizontal, 8)

            // Footer
            HStack {
                Button {
                    processService.snapshot()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Button {
                    NSApp.terminate(nil)
                } label: {
                    Label("Quit Killswitch", systemImage: "power")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 340)
        .onAppear {
            processService.snapshot()
        }
    }

    @ViewBuilder
    private func confirmationView(for process: AppProcessInfo) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.yellow)
                Text("Force quit \(process.name)?")
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }

            Text("Unsaved changes will be lost.")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button("Cancel") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showConfirmation = nil
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))

                Button("Force Quit") {
                    processService.forceQuit(pid: process.id)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showConfirmation = nil
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(.red))
                .disabled(processService.quitStatus == .quitting)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.red.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.red.opacity(0.2), lineWidth: 1))
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}
