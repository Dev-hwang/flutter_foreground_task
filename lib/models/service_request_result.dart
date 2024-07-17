/// Result of service request.
class ServiceRequestResult {
  const ServiceRequestResult({
    required this.success,
    this.error,
  });

  /// Whether the request was successful.
  final bool success;

  /// Error when the request failed.
  final Object? error;

  factory ServiceRequestResult.success() =>
      const ServiceRequestResult(success: true);

  factory ServiceRequestResult.error(Object error) =>
      ServiceRequestResult(success: false, error: error);
}
