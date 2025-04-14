/// https://developer.android.com/about/versions/14/changes/fgs-types-required#system-exempted
class ForegroundServiceTypes {
  /// Constructs an instance of [ForegroundServiceTypes].
  const ForegroundServiceTypes(this.rawValue);

  /// Continue to access the camera from the background, such as video chat apps that allow for multitasking.
  static const camera = ForegroundServiceTypes(0);

  /// Interactions with external devices that require a Bluetooth, NFC, IR, USB, or network connection.
  static const connectedDevice = ForegroundServiceTypes(1);

  /// Data transfer operations, such as the following:
  ///
  /// * Data upload or download
  /// * Backup-and-restore operations
  /// * Import or export operations
  /// * Fetch data
  /// * Local file processing
  /// * Transfer data between a device and the cloud over a network
  static const dataSync = ForegroundServiceTypes(2);

  /// Any long-running use cases to support apps in the fitness category such as exercise trackers.
  static const health = ForegroundServiceTypes(3);

  /// Long-running use cases that require location access, such as navigation and location sharing.
  static const location = ForegroundServiceTypes(4);

  /// Continue audio or video playback from the background. Support Digital Video Recording (DVR) functionality on Android TV.
  static const mediaPlayback = ForegroundServiceTypes(5);

  /// Project content to non-primary display or external device using the MediaProjection APIs. This content doesn't have to be exclusively media content.
  static const mediaProjection = ForegroundServiceTypes(6);

  /// Continue microphone capture from the background, such as voice recorders or communication apps.
  static const microphone = ForegroundServiceTypes(7);

  /// Continue an ongoing call using the ConnectionService APIs.
  static const phoneCall = ForegroundServiceTypes(8);

  /// Transfer text messages from one device to another. Assists with continuity of a user's messaging tasks when they switch devices.
  static const remoteMessaging = ForegroundServiceTypes(9);

  /// Quickly finish critical work that cannot be interrupted or postponed.
  static const shortService = ForegroundServiceTypes(10);

  /// Covers any valid foreground service use cases that aren't covered by the other foreground service types.
  static const specialUse = ForegroundServiceTypes(11);

  /// Reserved for system applications and specific system integrations, to continue to use foreground services.
  static const systemExempted = ForegroundServiceTypes(12);

  /// The raw value of [ForegroundServiceTypes].
  final int rawValue;
}
