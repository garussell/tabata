import SwiftUI

/// Configuration sheet for work/rest durations, rounds, and sets.
struct SettingsView: View {
    @Bindable var viewModel: TabataViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // ── Intervals ────────────────────────────────────────────
                Section {
                    durationRow(
                        label: "Work",
                        icon: "flame.fill",
                        iconColor: .orange,
                        value: $viewModel.settings.workDuration,
                        range: 5...300,
                        step: 5
                    )
                    durationRow(
                        label: "Rest",
                        icon: "leaf.fill",
                        iconColor: .green,
                        value: $viewModel.settings.restDuration,
                        range: 5...300,
                        step: 5
                    )
                } header: {
                    Text("Intervals")
                } footer: {
                    Text("Adjust in 5-second increments.")
                        .font(.caption)
                }

                // ── Structure ────────────────────────────────────────────
                Section("Structure") {
                    Stepper(
                        "Rounds: \(viewModel.settings.rounds)",
                        value: $viewModel.settings.rounds,
                        in: 1...20
                    )
                    Stepper(
                        "Sets: \(viewModel.settings.sets)",
                        value: $viewModel.settings.sets,
                        in: 1...10
                    )
                    if viewModel.settings.sets > 1 {
                        durationRow(
                            label: "Set Rest",
                            icon: "moon.fill",
                            iconColor: .blue,
                            value: $viewModel.settings.setRestDuration,
                            range: 10...600,
                            step: 10
                        )
                    }
                }

                // ── Summary ──────────────────────────────────────────────
                Section("Summary") {
                    LabeledContent(
                        "Total Rounds",
                        value: "\(viewModel.settings.rounds * viewModel.settings.sets)"
                    )
                    LabeledContent(
                        "Estimated Duration",
                        value: viewModel.settings.formattedTotalDuration
                    )
                }

                // ── Presets ──────────────────────────────────────────────
                Section("Presets") {
                    Button("Classic Tabata (20/10 × 8)") {
                        viewModel.settings.workDuration = 20
                        viewModel.settings.restDuration = 10
                        viewModel.settings.rounds = 8
                        viewModel.settings.sets = 1
                    }
                    Button("EMOM (40/20 × 10)") {
                        viewModel.settings.workDuration = 40
                        viewModel.settings.restDuration = 20
                        viewModel.settings.rounds = 10
                        viewModel.settings.sets = 1
                    }
                    Button("AMRAP (30/15 × 6 × 3)") {
                        viewModel.settings.workDuration = 30
                        viewModel.settings.restDuration = 15
                        viewModel.settings.rounds = 6
                        viewModel.settings.sets = 3
                        viewModel.settings.setRestDuration = 60
                    }
                }
                .foregroundStyle(.blue)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func durationRow(
        label: String,
        icon: String,
        iconColor: Color,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(label, systemImage: icon)
                    .foregroundStyle(iconColor)
                Spacer()
                Text("\(value.wrappedValue)s")
                    .monospacedDigit()
                    .fontWeight(.medium)
                    .foregroundStyle(iconColor)
            }
            Slider(
                value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: Double(step)
            )
            .tint(iconColor)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView(viewModel: TabataViewModel())
}
