import Foundation
import Observation
import Combine

/// Core state machine and timer logic for a Tabata workout.
///
/// All mutations happen on `@MainActor` (enforced project-wide via
/// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`). The Combine timer
/// also fires on the main run-loop, so there is no cross-actor hopping.
@Observable
class TabataViewModel {

    // MARK: - Public state

    var settings = TabataSettings()
    var phase: TimerPhase = .idle
    var timeRemaining: Int = 0
    var currentRound: Int = 1
    var currentSet: Int = 1
    var isRunning: Bool = false
    var totalElapsed: Int = 0

    // MARK: - Private

    private var timerCancellable: AnyCancellable?
    private let audioPlayer: any AudioPlayer

    // MARK: - Init

    init(audioPlayer: any AudioPlayer = AudioManager()) {
        self.audioPlayer = audioPlayer
    }

    // MARK: - Controls

    /// Begin a fresh workout from the idle state.
    func start() {
        guard phase == .idle else { return }
        currentRound = 1
        currentSet = 1
        totalElapsed = 0
        beginPhase(.work)
        isRunning = true
        startTimer()
    }

    /// Pause a running workout.
    func pause() {
        guard isRunning else { return }
        isRunning = false
        stopTimer()
    }

    /// Resume after a pause.
    func resume() {
        guard phase.isActive && !isRunning else { return }
        isRunning = true
        startTimer()
    }

    /// Reset to the initial idle state.
    func reset() {
        stopTimer()
        isRunning = false
        phase = .idle
        timeRemaining = 0
        currentRound = 1
        currentSet = 1
        totalElapsed = 0
    }

    // MARK: - Timer tick

    /// Called once per second by the Combine timer (or directly in unit tests).
    func tick() {
        guard isRunning && phase.isActive else { return }
        totalElapsed += 1
        timeRemaining -= 1

        if timeRemaining == 0 {
            advancePhase()
        } else if timeRemaining <= 3 {
            audioPlayer.playCountdownBeep()
        }
    }

    // MARK: - Private helpers

    private func startTimer() {
        guard timerCancellable == nil else { return }
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func beginPhase(_ newPhase: TimerPhase) {
        phase = newPhase
        switch newPhase {
        case .work:
            timeRemaining = settings.workDuration
            audioPlayer.playWorkStart()
        case .rest:
            timeRemaining = settings.restDuration
            audioPlayer.playRestStart()
        case .setRest:
            timeRemaining = settings.setRestDuration
            audioPlayer.playSetRestStart()
        case .complete:
            timeRemaining = 0
            isRunning = false
            stopTimer()
            audioPlayer.playComplete()
        case .idle:
            timeRemaining = 0
        }
    }

    private func advancePhase() {
        switch phase {
        case .work:
            audioPlayer.playWorkEnd()
            if currentRound < settings.rounds {
                beginPhase(.rest)
            } else if currentSet < settings.sets {
                beginPhase(.setRest)
            } else {
                beginPhase(.complete)
            }
        case .rest:
            currentRound += 1
            beginPhase(.work)
        case .setRest:
            currentSet += 1
            currentRound = 1
            beginPhase(.work)
        default:
            break
        }
    }

    // MARK: - Computed display helpers

    /// Progress of the current phase ring: 1.0 = full (just started), 0.0 = empty (about to end).
    var ringProgress: Double {
        let total: Int
        switch phase {
        case .work:    total = settings.workDuration
        case .rest:    total = settings.restDuration
        case .setRest: total = settings.setRestDuration
        default:       return 0
        }
        guard total > 0 else { return 0 }
        return Double(timeRemaining) / Double(total)
    }

    var formattedTime: String {
        let m = timeRemaining / 60
        let s = timeRemaining % 60
        return String(format: "%d:%02d", m, s)
    }

    var formattedTotalElapsed: String {
        let m = totalElapsed / 60
        let s = totalElapsed % 60
        return String(format: "%d:%02d", m, s)
    }

    /// Total number of work rounds across all sets.
    var totalRounds: Int { settings.rounds * settings.sets }

    /// How many work rounds have been fully completed.
    var completedRounds: Int {
        (currentSet - 1) * settings.rounds + (currentRound - 1)
    }

    /// 0…1 fraction of the overall workout complete.
    var overallProgress: Double {
        guard totalRounds > 0 else { return 0 }
        return Double(completedRounds) / Double(totalRounds)
    }
}
