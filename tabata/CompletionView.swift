import SwiftUI

/// Displayed when the workout finishes. Shows stats and a restart button.
struct CompletionView: View {
    var viewModel: TabataViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 24)

                // Trophy
                Image(systemName: "trophy.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(.yellow)
                    .symbolEffect(.bounce, value: true)
                    .shadow(color: .yellow.opacity(0.3), radius: 20)

                VStack(spacing: 8) {
                    Text("Workout Complete!")
                        .font(.largeTitle.bold())
                    Text("You crushed it. Time to rest.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                // Stats card
                statsCard

                Spacer(minLength: 8)

                // Actions
                VStack(spacing: 12) {
                    Button("Start New Workout") {
                        withAnimation { viewModel.reset() }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.orange)

                    Button("Restart Same Settings") {
                        withAnimation {
                            viewModel.reset()
                            viewModel.start()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(.orange)
                }

                Spacer(minLength: 16)
            }
            .padding(.horizontal)
        }
    }

    private var statsCard: some View {
        VStack(spacing: 0) {
            statRow(
                icon: "clock.fill",
                color: .blue,
                label: "Total Time",
                value: viewModel.formattedTotalElapsed
            )
            Divider().padding(.horizontal)
            statRow(
                icon: "repeat",
                color: .orange,
                label: "Total Rounds",
                value: "\(viewModel.settings.rounds * viewModel.settings.sets)"
            )
            Divider().padding(.horizontal)
            statRow(
                icon: "square.stack.3d.up.fill",
                color: .purple,
                label: "Sets Completed",
                value: "\(viewModel.settings.sets)"
            )
            Divider().padding(.horizontal)
            statRow(
                icon: "flame.fill",
                color: .red,
                label: "Work / Rest",
                value: "\(viewModel.settings.workDuration)s / \(viewModel.settings.restDuration)s"
            )
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.07), radius: 10, y: 4)
    }

    @ViewBuilder
    private func statRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

#Preview {
    NavigationStack {
        CompletionView(viewModel: {
            let vm = TabataViewModel()
            vm.reset()
            return vm
        }())
    }
}
