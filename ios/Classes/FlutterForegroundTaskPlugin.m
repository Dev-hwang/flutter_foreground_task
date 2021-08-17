#import "FlutterForegroundTaskPlugin.h"
#if __has_include(<flutter_foreground_task/flutter_foreground_task-Swift.h>)
#import <flutter_foreground_task/flutter_foreground_task-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_foreground_task-Swift.h"
#endif

@implementation FlutterForegroundTaskPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterForegroundTaskPlugin registerWithRegistrar:registrar];
}
+ (void)setPluginRegistrantCallback:(FlutterPluginRegistrantCallback)callback {
  [SwiftFlutterForegroundTaskPlugin setPluginRegistrantCallback:callback];
}
@end
