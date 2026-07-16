import Foundation
import WatchConnectivity

@MainActor
final class WatchSyncCoordinator: NSObject {
  static let shared = WatchSyncCoordinator()

  private override init() {
    super.init()
  }

  func activate() {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    guard session.delegate !== self else {
      if session.activationState == .activated {
        WatchSyncEngine.publishFullSnapshot(in: SharedModelContainer.shared.mainContext)
      }
      return
    }
    session.delegate = self
    session.activate()
  }
}

extension WatchSyncCoordinator: WCSessionDelegate {
  nonisolated func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    guard activationState == .activated else { return }
    Task { @MainActor in
      WatchSyncEngine.publishFullSnapshot(in: SharedModelContainer.shared.mainContext)
    }
  }

  #if os(iOS)
  nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

  nonisolated func sessionDidDeactivate(_ session: WCSession) {
    session.activate()
  }
  #endif

  nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
    guard session.isReachable else { return }
    Task { @MainActor in
      WatchSyncEngine.publishFullSnapshot(in: SharedModelContainer.shared.mainContext)
    }
  }

  nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    WatchSyncEngine.handleIncoming(applicationContext)
  }

  nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    WatchSyncEngine.handleIncoming(message)
  }

  nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    WatchSyncEngine.handleIncoming(userInfo)
  }
}
