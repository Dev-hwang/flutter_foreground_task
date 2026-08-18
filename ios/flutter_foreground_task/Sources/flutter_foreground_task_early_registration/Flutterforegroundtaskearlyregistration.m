#import "FlutterForegroundTaskEarlyRegistration.h"
#import <Foundation/Foundation.h>

@interface FlutterForegroundTaskEarlyRegistration : NSObject
@end

@implementation FlutterForegroundTaskEarlyRegistration
+ (void)load {
    flutter_foreground_task_register_app_refresh();
}
@end