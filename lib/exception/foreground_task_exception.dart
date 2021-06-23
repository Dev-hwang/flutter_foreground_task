/// ForegroundTaskException
class ForegroundTaskException implements Exception {
  final String? _message;

  const ForegroundTaskException([this._message]);

  @override
  String toString() => _message ?? 'ForegroundTaskException';
}
