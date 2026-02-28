//
//  tabataTests.swift
//  tabataTests
//
//  Created by Allen Russell on 2/27/26.
//

import Testing
@testable import tabata

// MARK: - Mock

/// Silent audio player used in tests so no system sounds fire.
@MainActor
class MockAudioPlayer: AudioPlayer {
    private(set) var workStartCount    = 0
    private(set) var workEndCount      = 0
    private(set) var restStartCount    = 0
    private(set) var setRestStartCount = 0
    private(set) var countdownCount    = 0
    private(set) var completeCount     = 0

    func playWorkStart()    { workStartCount    += 1 }
    func playWorkEnd()      { workEndCount      += 1 }
    func playRestStart()    { restStartCount    += 1 }
    func playSetRestStart() { setRestStartCount += 1 }
    func playCountdownBeep(){ countdownCount    += 1 }
    func playComplete()     { completeCount     += 1 }
}

// MARK: - Helpers

/// Build settings overriding only the values needed for a specific test.
private func makeSettings(
    work: Int = 20, rest: Int = 10, rounds: Int = 8, sets: Int = 1, setRest: Int = 60
) -> TabataSettings {
    TabataSettings(
        workDuration: work, restDuration: rest,
        rounds: rounds, sets: sets, setRestDuration: setRest
    )
}

// MARK: - Tests

/// All tests run on @MainActor to match the implicit actor of TabataViewModel.
@MainActor
struct tabataTests {

    // ── Initial state ────────────────────────────────────────────────────

    @Test func initialStateIsIdle() {
        let vm = TabataViewModel(audioPlayer: MockAudioPlayer())
        #expect(vm.phase        == .idle)
        #expect(vm.currentRound == 1)
        #expect(vm.currentSet   == 1)
        #expect(vm.isRunning    == false)
        #expect(vm.timeRemaining == 0)
        #expect(vm.totalElapsed  == 0)
    }

    // ── Start ────────────────────────────────────────────────────────────

    @Test func startBeginsWorkPhase() {
        let vm = TabataViewModel(audioPlayer: MockAudioPlayer())
        vm.start()
        defer { vm.reset() }
        #expect(vm.phase         == .work)
        #expect(vm.isRunning     == true)
        #expect(vm.timeRemaining == vm.settings.workDuration)
    }

    @Test func startPlaysTWorkAudio() {
        let mock = MockAudioPlayer()
        let vm   = TabataViewModel(audioPlayer: mock)
        vm.start()
        defer { vm.reset() }
        #expect(mock.workStartCount == 1)
    }

    @Test func startOnlyWorksFromIdle() {
        let vm = TabataViewModel(audioPlayer: MockAudioPlayer())
        vm.start()
        let phase = vm.phase
        vm.start() // second call should be ignored
        #expect(vm.phase == phase)
        vm.reset()
    }

    // ── Phase transitions ────────────────────────────────────────────────

    @Test func workTransitionsToRestAfterCountdown() {
        let vm = TabataViewModel(audioPlayer: MockAudioPlayer())
        vm.settings = makeSettings(work: 3, rest: 2, rounds: 3)
        vm.start()
        vm.tick(); vm.tick(); vm.tick() // 3 ticks → work done
        #expect(vm.phase         == .rest)
        #expect(vm.timeRemaining == 2)
    }

    @Test func restAdvancesRoundAndReturnsToWork() {
        let vm = TabataViewModel(audioPlayer: MockAudioPlayer())
        vm.settings = makeSettings(work: 1, rest: 1, rounds: 3)
        vm.start()
        vm.tick()                       // work → rest (round stays 1)
        #expect(vm.phase        == .rest)
        #expect(vm.currentRound == 1)
        vm.tick()                       // rest → work round 2
        #expect(vm.phase        == .work)
        #expect(vm.currentRound == 2)
    }

    @Test func lastRoundLastSetCompletesWorkout() {
        let vm = TabataViewModel(audioPlayer: MockAudioPlayer())
        vm.settings = makeSettings(work: 1, rest: 1, rounds: 1, sets: 1)
        vm.start()
        vm.tick()                       // work → complete
        #expect(vm.phase     == .complete)
        #expect(vm.isRunning == false)
    }

    @Test func lastRoundNotLastSetGoesToSetRest() {
        let vm = TabataViewModel(audioPlayer: MockAudioPlayer())
        vm.settings = makeSettings(work: 1, rest: 1, rounds: 1, sets: 2, setRest: 30)
        vm.start()
        vm.tick()                       // work → setRest
        #expect(vm.phase         == .setRest)
        #expect(vm.timeRemaining == 30)
    }

    @Test func setRestStartsNextSet() {
        let vm = TabataViewModel(audioPlayer: MockAudioPlayer())
        vm.settings = makeSettings(work: 1, rest: 1, rounds: 1, sets: 2, setRest: 1)
        vm.start()
        vm.tick()                       // work → setRest
        vm.tick()                       // setRest → work set 2
        #expect(vm.phase        == .work)
        #expect(vm.currentSet   == 2)
        #expect(vm.currentRound == 1)
    }

    @Test func fullWorkoutTwoRoundsTwoSets() {
        let vm = TabataViewModel(audioPlayer: MockAudioPlayer())
        vm.settings = makeSettings(work: 1, rest: 1, rounds: 2, sets: 2, setRest: 1)
        vm.start()
        // Set 1 round 1: work→rest
        vm.tick(); vm.tick()
        // Set 1 round 2: work→setRest
        vm.tick(); vm.tick()
        // Set 2 round 1: work→rest
        vm.tick(); vm.tick()
        // Set 2 round 2: work→complete
        vm.tick()
        #expect(vm.phase == .complete)
    }

    // ── Audio cues ───────────────────────────────────────────────────────

    @Test func audioPlayedOnWorkEnd() {
        let mock = MockAudioPlayer()
        let vm   = TabataViewModel(audioPlayer: mock)
        vm.settings = makeSettings(work: 1, rest: 1, rounds: 2)
        vm.start()
        vm.tick()                       // work phase ends → playWorkEnd fires
        #expect(mock.workEndCount == 1)
    }

    @Test func audioPlayedForRestStart() {
        let mock = MockAudioPlayer()
        let vm   = TabataViewModel(audioPlayer: mock)
        vm.settings = makeSettings(work: 1, rest: 1, rounds: 2)
        vm.start()
        vm.tick()                       // work → rest
        #expect(mock.restStartCount == 1)
    }

    @Test func audioPlayedForSetRest() {
        let mock = MockAudioPlayer()
        let vm   = TabataViewModel(audioPlayer: mock)
        vm.settings = makeSettings(work: 1, rest: 1, rounds: 1, sets: 2, setRest: 1)
        vm.start()
        vm.tick()                       // work → setRest
        #expect(mock.setRestStartCount == 1)
    }

    @Test func audioPlayedForCompletion() {
        let mock = MockAudioPlayer()
        let vm   = TabataViewModel(audioPlayer: mock)
        vm.settings = makeSettings(work: 1, rest: 1, rounds: 1, sets: 1)
        vm.start()
        vm.tick()
        #expect(mock.completeCount == 1)
    }

    @Test func countdownBeepPlaysAtThreeSeconds() {
        let mock = MockAudioPlayer()
        let vm   = TabataViewModel(audioPlayer: mock)
        vm.settings = makeSettings(work: 5, rest: 5, rounds: 2)
        vm.start()
        // 5 - 1 = 4 … 5 - 2 = 3 → beep, 5 - 3 = 2 → beep, 5 - 4 = 1 → beep
        vm.tick()                       // remaining 4 – no beep
        #expect(mock.countdownCount == 0)
        vm.tick()                       // remaining 3 → beep
        #expect(mock.countdownCount == 1)
        vm.tick()                       // remaining 2 → beep
        #expect(mock.countdownCount == 2)
        vm.tick()                       // remaining 1 → beep
        #expect(mock.countdownCount == 3)
    }

    // ── Pause / Resume / Reset ───────────────────────────────────────────

    @Test func pauseStopsIsRunning() {
        let vm = TabataViewModel(audioPlayer: MockAudioPlayer())
        vm.start()
        vm.pause()
        #expect(vm.isRunning == false)
        #expect(vm.phase     == .work)  // phase unchanged
    }

    @Test func tickIsNoOpWhenPaused() {
        let vm = TabataViewModel(audioPlayer: MockAudioPlayer())
        vm.settings = makeSettings(work: 10, rest: 5, rounds: 2)
        vm.start()
        vm.pause()
        let remaining = vm.timeRemaining
        vm.tick()                       // should be ignored
        #expect(vm.timeRemaining == remaining)
    }

    @Test func resumeContinuesFromPause() {
        let vm = TabataViewModel(audioPlayer: MockAudioPlayer())
        vm.start()
        vm.pause()
        vm.resume()
        #expect(vm.isRunning == true)
        #expect(vm.phase     == .work)
        vm.reset()
    }

    @Test func resetRestoresIdleState() {
        let vm = TabataViewModel(audioPlayer: MockAudioPlayer())
        vm.start()
        vm.tick(); vm.tick()
        vm.reset()
        #expect(vm.phase         == .idle)
        #expect(vm.currentRound  == 1)
        #expect(vm.currentSet    == 1)
        #expect(vm.isRunning     == false)
        #expect(vm.timeRemaining == 0)
        #expect(vm.totalElapsed  == 0)
    }

    // ── Computed properties ──────────────────────────────────────────────

    @Test func formattedTimeShowsMinutesAndSeconds() {
        let vm = TabataViewModel(audioPlayer: MockAudioPlayer())
        vm.settings = makeSettings(work: 90, rest: 10, rounds: 1)
        vm.start()
        defer { vm.reset() }
        #expect(vm.formattedTime == "1:30")
    }

    @Test func formattedTimeShowsZeroMinutes() {
        let vm = TabataViewModel(audioPlayer: MockAudioPlayer())
        vm.settings = makeSettings(work: 20, rest: 10, rounds: 1)
        vm.start()
        defer { vm.reset() }
        #expect(vm.formattedTime == "0:20")
    }

    @Test func ringProgressIsFullAtStart() {
        let vm = TabataViewModel(audioPlayer: MockAudioPlayer())
        vm.start()
        defer { vm.reset() }
        #expect(vm.ringProgress == 1.0)
    }

    @Test func ringProgressDecreasesAfterTick() {
        let vm = TabataViewModel(audioPlayer: MockAudioPlayer())
        vm.settings = makeSettings(work: 4, rest: 2, rounds: 2)
        vm.start()
        let before = vm.ringProgress
        vm.tick()
        #expect(vm.ringProgress < before)
        vm.reset()
    }

    @Test func overallProgressIsZeroAtStart() {
        let vm = TabataViewModel(audioPlayer: MockAudioPlayer())
        vm.start()
        defer { vm.reset() }
        #expect(vm.overallProgress == 0.0)
    }

    @Test func totalElapsedTracksTime() {
        let vm = TabataViewModel(audioPlayer: MockAudioPlayer())
        vm.settings = makeSettings(work: 10, rest: 5, rounds: 2)
        vm.start()
        vm.tick(); vm.tick(); vm.tick()
        defer { vm.reset() }
        #expect(vm.totalElapsed == 3)
    }

    // ── Settings calculations ────────────────────────────────────────────

    @Test func settingsTotalDurationClassicTabata() {
        let s = makeSettings(work: 20, rest: 10, rounds: 8, sets: 1)
        // 8×20 work + 7×10 rest = 160 + 70 = 230
        #expect(s.totalDuration == 230)
    }

    @Test func settingsTotalDurationWithMultipleSets() {
        let s = makeSettings(work: 20, rest: 10, rounds: 8, sets: 2, setRest: 60)
        // Work: 2×8×20 = 320
        // Rest between rounds: 2×7×10 = 140
        // Set rest: 1×60 = 60
        #expect(s.totalDuration == 520)
    }

    @Test func settingsFormattedDurationOverOneMinute() {
        let s = makeSettings(work: 20, rest: 10, rounds: 8, sets: 1)
        // 230 seconds = 3m 50s
        #expect(s.formattedTotalDuration == "3m 50s")
    }
}
