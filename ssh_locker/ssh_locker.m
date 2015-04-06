#import <Foundation/Foundation.h>

@interface LockAgent : NSObject {
}

- (id)init;
- (void)dealloc;
- (void)lock_keychain:(NSNotification *)note;
@end

@implementation LockAgent

- (id)init
{
    if (![super init])
        return nil;

    NSDistributedNotificationCenter *center =
        [NSDistributedNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(lock_keychain:)
                   name:@"com.apple.screensaver.didstart"
                 object:nil];

    return self;
}

- (void)dealloc
{
    NSDistributedNotificationCenter *center =
        [NSDistributedNotificationCenter defaultCenter];
    [center removeObserver:self];
    [super dealloc];
}

- (void)lock_keychain:(NSNotification *)note
{
    SecKeychainLockAll();
}

@end

int stop_agent(void)
{
    NSArray * arguments = [NSArray arrayWithObjects: @"stop",
                           @"org.openbsd.ssh-agent", nil];
    
    NSTask * stopAgent = [NSTask launchedTaskWithLaunchPath: @"/bin/launchctl"
                                                  arguments: arguments];
    [stopAgent waitUntilExit];
    return [stopAgent terminationStatus];
}

OSStatus keychain_locked(SecKeychainEvent keychainEvent, SecKeychainCallbackInfo *info, void *context)
{
#if 1
    stop_agent();
#else
    NSLog(@"Exit: %d", stop_agent());
#endif
    
	return 0;
}

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    LockAgent *agent = [[LockAgent alloc] init];

    SecKeychainAddCallback(&keychain_locked, kSecLockEventMask, nil);

    [[NSRunLoop currentRunLoop] run];

    [pool drain];
    return 0;
}
