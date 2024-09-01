class ServiceNotInitializedException implements Exception {
  ServiceNotInitializedException(
      [this.message =
          'Not initialized. Please call this function after calling the init function.']);

  final String message;

  @override
  String toString() => 'ServiceNotInitializedException: $message';
}
