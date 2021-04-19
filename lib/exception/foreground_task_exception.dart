/// ForegroundTaskException
class ForegroundTaskException implements Exception {
  final String? _message;

  ForegroundTaskException([this._message]);

  @override
  String toString() => _message ?? 'ForegroundTaskException';
}
