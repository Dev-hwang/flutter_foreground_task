import 'package:flutter/services.dart';

class ServiceTimeoutException extends PlatformException {
  ServiceTimeoutException()
      : super(
          code: 'ServiceTimeoutException',
          message:
              'The service request timed out. (ref: https://developer.android.com/guide/components/services#StartingAService)',
        );
}
