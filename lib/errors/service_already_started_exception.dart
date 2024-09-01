class ServiceAlreadyStartedException implements Exception {
  ServiceAlreadyStartedException(
      [this.message = 'The service has already started.']);

  final String message;

  @override
  String toString() => 'ServiceAlreadyStartedException: $message';
}
