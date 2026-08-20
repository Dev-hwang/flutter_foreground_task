import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationProgress', () {
    test('serializes visible progress', () {
      const progress = NotificationProgress(max: 100, progress: 42);

      expect(progress.toJson(), {
        'max': 100,
        'progress': 42,
        'indeterminate': false,
        'show': true,
      });
    });

    test('clamps serialized progress to max', () {
      const progress = NotificationProgress(max: 100, progress: 120);

      expect(progress.toJson()['progress'], 100);
    });

    test('serializes none as hidden progress', () {
      const progress = NotificationProgress.none();

      expect(progress.toJson(), {
        'max': 0,
        'progress': 0,
        'indeterminate': false,
        'show': false,
      });
    });
  });
}
