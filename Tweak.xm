#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <libactivator/libactivator.h>
#import "AOP.h"
#import "BannerClasses.h"

#define kPrefPath [NSHomeDirectory() stringByAppendingString:@"/Library/Preferences/com.flux.aoproximity.plist"]
#ifndef kCFCoreFoundationVersionNumber_iOS_7_0
#define kCFCoreFoundationVersionNumber_iOS_7_0 847.20
#endif

static void AOPWritePrefsToFile(void);
static BOOL _enabled;
static BOOL _allowIdleTimerToClear;

%hook SpringBoard
- (void)_performDeferredLaunchWork
{
    %orig;
    
    // load up the prefs
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:kPrefPath];
    _enabled = [prefs[@"enabled"] boolValue];

    if (_enabled || (prefs == nil)) {
        // if the file doesn't exist, enable the sensor, and create the file. 
        AOPSetIsEnabled(YES);
    }

    [prefs release];
}

- (void)setExpectsFaceContact:(BOOL)expectsFaceContact
{
    %orig(_enabled);
}

- (void)_proximityChanged:(NSNotification *)notification
{
    // get the topmost application 
    SBApplication *topApp = [(SpringBoard *)self _accessibilityFrontMostApplication];

    if ([[topApp bundleIdentifier] isEqualToString:@"com.apple.camera"] || (!_enabled)) {
        return; // don't turn off the screen
    }

    _allowIdleTimerToClear = NO;
    %orig;
    _allowIdleTimerToClear = YES;

    if ((topApp == nil) || ([[topApp bundleIdentifier] isEqualToString:@"com.saurik.Cydia"]) || ([[%c(SBTelephonyManager) sharedTelephonyManager] inCall]))  {
        // don't notify to resume/resign active
        return;
    }

    BOOL objectWithinProximity = [[notification.userInfo objectForKey:@"kSBNotificationKeyState"] boolValue];
    if (objectWithinProximity) {
        [topApp notifyResignActiveForReason:1];
    }
    else {
        [topApp notifyResumeActiveForReason:1];
    }
    
}

- (void)clearIdleTimer
{
    if (_allowIdleTimerToClear) {
        %orig;
    }
    else {
        return;
    }
}
%end

@interface AOPListener : NSObject <LAListener>
@end

@implementation AOPListener

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callStateChanged) name:@"com.apple.springboard.activeCallStateChanged" object:nil];
    }
    return self;
}

static BOOL didChangeState;
- (void)callStateChanged
{
    BOOL inCall = [[%c(SBTelephonyManager) sharedTelephonyManager] inCall];
    if (!_enabled && inCall) {
        _enabled = YES;
        [(SpringBoard *)[UIApplication sharedApplication] setExpectsFaceContact:_enabled];
        didChangeState = YES;
    }
    if (!inCall && didChangeState) {
        _enabled = NO;
        [(SpringBoard *)[UIApplication sharedApplication] setExpectsFaceContact:_enabled];
        didChangeState = NO;
    }
}

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
    if ([[%c(SBTelephonyManager) sharedTelephonyManager] inCall]) {
        return;
    }

    AOPSetIsEnabled(!_enabled);

    // create a bulletin request to display a banner when toggled.
    BBBulletinRequest *request = [[%c(BBBulletinRequest) alloc] init];
    request.title     = @"Always On Proximity";
    request.message   = [NSString stringWithFormat:@"Proximity sensor %@", ((_enabled) ? @"enabled" : @"disabled")]; 
    request.sectionID = @"com.apple.Preferences";
    
    [(SBBulletinBannerController *)[%c(SBBulletinBannerController) sharedInstance] observer:nil addBulletin:request forFeed:2];
    [request release];

    event.handled = YES;
}

+ (void)load
{
    @autoreleasepool {
        [[LAActivator sharedInstance] registerListener:[self new] forName:@"com.flux.aop"];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end

extern void AOPSetIsEnabled(BOOL isEnabled)
{
    _enabled = isEnabled;
    [(SpringBoard *)[UIApplication sharedApplication] setExpectsFaceContact:isEnabled];
    AOPWritePrefsToFile();

}

extern BOOL AOPGetIsEnabled(void)
{
    return _enabled;
}

static void AOPWritePrefsToFile(void)
{
    @autoreleasepool {
        NSMutableDictionary *prefs = [@{} mutableCopy];
        prefs[@"enabled"] = @(_enabled);
        [prefs writeToFile:kPrefPath atomically:YES];
        [prefs release];
    }
}

%ctor 
{
    @autoreleasepool {
        %init;
    }
}

