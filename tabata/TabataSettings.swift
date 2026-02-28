import Foundation

struct TabataSettings {
    var workDuration: Int = 20
    var restDuration: Int = 10
    var rounds: Int = 8
    var sets: Int = 1
    var setRestDuration: Int = 60

    /// Total estimated workout duration in seconds.
    var totalDuration: Int {
        let workTime = rounds * sets * workDuration
        // Rest intervals occur between rounds (not after the last round of each set)
        let restTime = rounds > 1 ? (rounds - 1) * sets * restDuration : 0
        let setRestTime = sets > 1 ? (sets - 1) * setRestDuration : 0
        return workTime + restTime + setRestTime
    }

    var formattedTotalDuration: String {
        let m = totalDuration / 60
        let s = totalDuration % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }
}
