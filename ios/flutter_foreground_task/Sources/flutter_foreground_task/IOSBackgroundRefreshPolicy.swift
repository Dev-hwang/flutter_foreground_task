import Foundation

/// Serializes disable with submission/completion across Flutter engines.
final class IOSBackgroundRefreshPolicy {
  let lock = NSRecursiveLock()
  private let defaults: UserDefaults
  private let permitted: () -> Bool
  private let registered: () -> Bool
  private let cancel: () -> Void
  private let cancelRunning: () -> Void
  private let key = "com.pravera.flutter_foreground_task.backgroundRefreshEnabled"

  init(defaults: UserDefaults = .standard, permitted: @escaping () -> Bool,
       registered: @escaping () -> Bool, cancel: @escaping () -> Void,
       cancelRunning: @escaping () -> Void) {
    self.defaults = defaults
    self.permitted = permitted
    self.registered = registered
    self.cancel = cancel
    self.cancelRunning = cancelRunning
  }

  var enabled: Bool {
    lock.lock()
    defer { lock.unlock() }
    return permitted() && (defaults.object(forKey: key) as? Bool ?? true)
  }

  func setEnabled(_ value: Bool) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    if value && (!permitted() || !registered()) { return false }
    defaults.set(value, forKey: key)
    if !value {
      cancel()
      cancelRunning()
    }
    return true
  }

  func submitIfEnabled(_ submit: () -> Void) {
    lock.lock()
    defer { lock.unlock() }
    guard enabled, registered() else {
      cancel()
      return
    }
    submit()
  }
}
