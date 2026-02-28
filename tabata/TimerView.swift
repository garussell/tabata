import SwiftUI

/// Main workout screen: ring timer, phase label, round/set progress, and controls.
struct TimerView: View {
    @Bindable var viewModel: TabataViewModel
    @State private var showSettings = false

    var body: some View {
        ZStack {
            // Subtle background tint that shifts with the current phase.
            viewModel.phase.color
                .opacity(0.06)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: viewModel.phase)

            VStack(spacing: 20) {
                progressHeader
                ringTimer
                overallProgressBar
                controlButtons
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .toolbar {
            if viewModel.phase == .idle {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
    }

    // MARK: - Subviews

    private var progressHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Set \(viewModel.currentSet) / \(viewModel.settings.sets)",
                      systemImage: "square.stack.3d.up")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label("Round \(viewModel.currentRound) / \(viewModel.settings.rounds)",
                      systemImage: "repeat")
                    .font(.headline)
                    .foregroundStyle(viewModel.phase.color)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Elapsed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(viewModel.formattedTotalElapsed)
                    .font(.headline)
                    .monospacedDigit()
            }
        }
        .padding(.top, 8)
    }

    private var ringTimer: some View {
        GeometryReader { geo in
            let diameter = min(geo.size.width, geo.size.height)
            ZStack {
                // Track
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 22)

                // Animated progress arc
                Circle()
                    .trim(from: 0, to: viewModel.ringProgress)
                    .stroke(
                        viewModel.phase.color,
                        style: StrokeStyle(lineWidth: 22, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: viewModel.ringProgress)

                // Centre content
                VStack(spacing: 6) {
                    Text(viewModel.phase.label)
                        .font(.title2.bold())
                        .foregroundStyle(viewModel.phase.color)
                        .animation(.none, value: viewModel.phase)

                    Text(viewModel.formattedTime)
                        .font(.system(size: diameter * 0.21,
                                      weight: .bold,
                                      design: .monospaced))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.linear(duration: 0.3), value: viewModel.timeRemaining)

                    if viewModel.phase == .idle {
                        Text("Tap ▶ to begin")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: diameter, height: diameter)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var overallProgressBar: some View {
        VStack(spacing: 6) {
            ProgressView(value: viewModel.overallProgress)
                .tint(viewModel.phase.color)
                .animation(.easeOut(duration: 0.4), value: viewModel.overallProgress)
            HStack {
                Text("\(viewModel.completedRounds) / \(viewModel.totalRounds) rounds complete")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(viewModel.settings.formattedTotalDuration)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 24) {
            // Reset
            Button {
                withAnimation { viewModel.reset() }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2.bold())
                    .frame(width: 60, height: 60)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Circle())
            }
            .disabled(viewModel.phase == .idle)
            .opacity(viewModel.phase == .idle ? 0.4 : 1)

            // Play / Pause
            Button {
                if viewModel.phase == .idle {
                    viewModel.start()
                } else if viewModel.isRunning {
                    viewModel.pause()
                } else {
                    viewModel.resume()
                }
            } label: {
                Image(systemName: playPauseIcon)
                    .font(.system(size: 32, weight: .bold))
                    .frame(width: 84, height: 84)
                    .background(viewModel.phase.color)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
                    .shadow(color: viewModel.phase.color.opacity(0.4),
                            radius: 10, y: 5)
            }
            .animation(.spring(duration: 0.25), value: viewModel.isRunning)
        }
        .padding(.vertical, 8)
    }

    private var playPauseIcon: String {
        viewModel.isRunning ? "pause.fill" : "play.fill"
    }
}

#Preview {
    NavigationStack {
        TimerView(viewModel: TabataViewModel())
    }
}
