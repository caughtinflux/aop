#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBTelephonyManager.h>
#import <libactivator/libactivator.h>

#import "BannerClasses.h"

#define kPrefPath [NSHomeDirectory() stringByAppendingString:@"/Library/Preferences/com.flux.aoproximity.plist"]

static void AOPEnableSensor(void);
static void AOPDisableSensor(void);
static void AOPWritePrefsToFile(void);

@interface SpringBoard : UIApplication
- (void)setExpectsFaceContact:(BOOL)something;
- (SBApplication *)_accessibilityFrontMostApplication;
@end

static BOOL enabled = YES;
%hook SpringBoard
- (void)applicationDidFinishLaunching:(SpringBoard *)app
{
    %orig;
    if ([[NSFileManager defaultManager] fileExistsAtPath:kPrefPath]) {
        // load up the prefs
        NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:kPrefPath];
        enabled = [prefs[@"enabled"] boolValue];
        if (enabled) {
            AOPEnableSensor();
        }
        [prefs release];
    }
    else {
        AOPEnableSensor();
    }
}

- (void)setExpectsFaceContact:(BOOL)expectsFaceContact
{
    %orig(enabled);
}

- (void)_proximityChanged:(NSNotification *)notification
{
    // get the topmost application 
    SBApplication *topApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];

    if ([[topApp bundleIdentifier] isEqualToString:@"com.apple.camera"] || (!enabled)) {
        return; // don't turn off the screen
    }

    %orig;

    if ((topApp == nil) || ([[topApp bundleIdentifier] isEqualToString:@"com.saurik.Cydia"]) || ([[%c(SBTelephonyManager) sharedTelephonyManager] inCall]))  {
        // don't notify to resume/resign active
        return;
    }

    int state = [[notification.userInfo objectForKey:@"kSBNotificationKeyState"] intValue]; // this is probably a BOOL.
    if (state == 1) {
        // screen is going off.
        [topApp notifyResignActiveForReason:1];
    }
    else if (state == 0) {
        // screen is turning on.
        [topApp notifyResumeActiveForReason:1];
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
        // register self for call state change notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callStateChanged) name:@"com.apple.springboard.activeCallStateChanged" object:nil];
    }
    return self;
}

- (void)callStateChanged
{
    // enable the proximity sensor when in call.
    if (([[%c(SBTelephonyManager) sharedTelephonyManager] inCall]) && (enabled == NO)) {
        AOPEnableSensor();
    }
    else if (![[%c(SBTelephonyManager) sharedTelephonyManager] inCall]) {
        AOPDisableSensor();
    }
}

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
    (enabled == YES) ? AOPDisableSensor() : AOPEnableSensor();

    // create a bulletin request to display a banner when toggled.
    BBBulletinRequest *request = [[[%c(BBBulletinRequest) alloc] init] autorelease];
    request.title     = @"Always On Proximity";
    request.message   = [NSString stringWithFormat:@"Proximity sensor %@", ((enabled) ? @"enabled" : @"disabled")]; 
    request.sectionID = @"com.apple.Preferences";
    
    [(SBBulletinBannerController *)[%c(SBBulletinBannerController) sharedInstance] observer:nil addBulletin:request forFeed:2];

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

static void AOPEnableSensor(void)
{
    enabled = YES;
    [(SpringBoard *)[UIApplication sharedApplication] setExpectsFaceContact:YES];
    AOPWritePrefsToFile();
}

static void AOPDisableSensor(void)
{
    enabled = NO;
    [(SpringBoard *)[UIApplication sharedApplication] setExpectsFaceContact:NO];
    AOPWritePrefsToFile();
}

static void AOPWritePrefsToFile(void)
{
    @autoreleasepool {
        NSMutableDictionary *prefs = [[NSDictionary dictionaryWithContentsOfFile:kPrefPath] mutableCopy];
        if (!prefs) {
            prefs = [[NSMutableDictionary alloc] init];
        }
        prefs[@"enabled"] = @(enabled);
        [prefs writeToFile:kPrefPath atomically:YES];
        [prefs release];
    }
}

%ctor 
{
    @autoreleasepool {
        %init;
        
        // register ourself for notifications from the SBSettings toggle
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)&AOPEnableSensor, CFSTR("com.flux.aoproximity/enable"), NULL, CFNotificationSuspensionBehaviorHold);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)&AOPDisableSensor, CFSTR("com.flux.aoproximity/disable"), NULL, CFNotificationSuspensionBehaviorHold);
    }
}
