import Foundation

struct DeviceState: Equatable {
    var camera: Bool
    var microphone: Bool

    static let inactive = DeviceState(camera: false, microphone: false)
}

/// Polls the camera and microphone state on a fixed interval and invokes
/// `onChange` once per transition. Polling only runs while `isEnabled` is true.
@MainActor
final class DeviceStateMonitor {
    private(set) var state: DeviceState = .inactive
    private(set) var pollInterval: TimeInterval

    /// Called on the main thread whenever the aggregated state changes.
    var onChange: ((_ old: DeviceState, _ new: DeviceState) -> Void)?

    private var timer: Timer?

    var isEnabled: Bool { timer != nil }

    init(pollInterval: TimeInterval = 3) {
        self.pollInterval = pollInterval
    }

    func start() {
        guard timer == nil else { return }
        poll()
        let timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
        timer.tolerance = pollInterval * 0.2
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func setPollInterval(_ interval: TimeInterval) {
        guard interval != pollInterval else { return }
        pollInterval = interval
        if isEnabled {
            stop()
            start()
        }
    }

    private func poll() {
        let new = DeviceState(camera: CameraMonitor.isInUse(), microphone: MicrophoneMonitor.isInUse())
        guard new != state else { return }
        let old = state
        state = new
        onChange?(old, new)
    }
}
