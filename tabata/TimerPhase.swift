import SwiftUI

enum TimerPhase: Equatable {
    case idle
    case work
    case rest
    case setRest
    case complete

    var label: String {
        switch self {
        case .idle:    "Ready"
        case .work:    "WORK"
        case .rest:    "REST"
        case .setRest: "SET REST"
        case .complete:"DONE!"
        }
    }

    var color: Color {
        switch self {
        case .idle:    .gray
        case .work:    .orange
        case .rest:    .green
        case .setRest: .blue
        case .complete:.purple
        }
    }

    /// True while the countdown is actively ticking.
    var isActive: Bool {
        self == .work || self == .rest || self == .setRest
    }
}
