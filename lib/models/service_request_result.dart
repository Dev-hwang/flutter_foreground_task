/// Represents the result of a service request.
sealed class ServiceRequestResult {
  const ServiceRequestResult();
}

/// The service request was successful.
final class ServiceRequestSuccess extends ServiceRequestResult {
  const ServiceRequestSuccess();
}

/// The service request failed.
final class ServiceRequestFailure extends ServiceRequestResult {
  const ServiceRequestFailure({required this.error});

  /// The error that occurred when the service request failed.
  final Object error;
}
