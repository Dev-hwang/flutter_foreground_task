class ServiceTimeoutException implements Exception {
  ServiceTimeoutException(
      [this.message =
          'The service request timed out. (ref: https://developer.android.com/guide/components/services#StartingAService)']);

  final String message;

  @override
  String toString() => 'ServiceTimeoutException: $message';
}
