import 'package:flutter/services.dart';

class ServiceNotInitializedException extends PlatformException {
  ServiceNotInitializedException()
      : super(
          code: 'ServiceNotInitializedException',
          message:
              'Not initialized. Please call this function after calling the init function.',
        );
}
