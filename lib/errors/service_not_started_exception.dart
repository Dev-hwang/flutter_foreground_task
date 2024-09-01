class ServiceNotStartedException implements Exception {
  ServiceNotStartedException([this.message = 'The service is not started.']);

  final String message;

  @override
  String toString() => 'ServiceNotStartedException: $message';
}
