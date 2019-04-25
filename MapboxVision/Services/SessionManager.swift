import Foundation

protocol SessionDelegate: AnyObject {
    func sessionStarted()
    func sessionStopped(abort: Bool)
}

final class SessionManager {
    weak var delegate: SessionDelegate?
    
    private var notificationObservers = [Any]()
    private var interruptionInterval: TimeInterval = 0
    private var interruptionTimer: Timer?
    
    private var isStarted = false
    
    func startSession(interruptionInterval: TimeInterval) {
        guard !isStarted else { return }
        isStarted.toggle()

        let observer = NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification,
                                                              object: nil,
                                                              queue: .main) { [weak self] _ in
            self?.stopSession()
        }
        notificationObservers.append(observer)

        if interruptionInterval > 0 {
            interruptionTimer = Timer.scheduledTimer(withTimeInterval: interruptionInterval, repeats: true) { [weak self] _ in
                self?.stopInterval()
                self?.startInterval()
            }
        }
        startInterval()
    }
    
    func stopSession(abort: Bool = false) {
        guard isStarted else { return }
        isStarted.toggle()
        
        notificationObservers.forEach(NotificationCenter.default.removeObserver)
        interruptionTimer?.invalidate()
        stopInterval(abort: abort)
    }
    
    private func startInterval() {
        delegate?.sessionStarted()
    }
    
    private func stopInterval(abort: Bool = false) {
        delegate?.sessionStopped(abort: abort)
    }
}
