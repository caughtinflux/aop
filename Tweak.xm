#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBTelephonyManager.h>
#import <libactivator/libactivator.h>

#import "BannerClasses.h"

@interface SpringBoard : UIApplication
- (void)setExpectsFaceContact:(BOOL)something;
- (SBApplication *)_accessibilityFrontMostApplication;
@end

static BOOL enabled = YES;
%hook SpringBoard
- (void)applicationDidFinishLaunching:(SpringBoard *)app
{
	%orig;
	if (enabled) {
		// switch the proximity sensor on first launch
		[app setExpectsFaceContact:YES];
	}
}

- (void)setExpectsFaceContact:(BOOL)expectsFaceContact
{
	// make sure nothing else disables the sensor.
	if (enabled) {
		%orig(YES);
	}
	else {
		%orig(NO);
	}
}

- (void)_proximityChanged:(NSNotification *)notification
{
	%orig;

	if (!enabled) {
		return;
	}

	// get the topmost application 
	SBApplication *topApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
	if ([[topApp bundleIdentifier] isEqualToString:@"com.apple.camera"])
		return;

	if (topApp != nil ) {
		int state = [[notification.userInfo objectForKey:@"kSBNotificationKeyState"] intValue]; // this is probably a BOOL.
		
		if ([[%c(SBTelephonyManager) sharedTelephonyManager] inCall]) {
			// if a call is active, don't notify the Phone app to resign/resume active. It knows what it's doing.
			return;
		}
		else if (state == 1) {
			// screen is going off.
			[topApp notifyResignActiveForReason:1];
		}
		else if (state == 0) {
			// screen is turning on.
			[topApp notifyResumeActiveForReason:1];
		}
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
		// register self for KVO notifications.
		[[%c(SBTelephonyManager) sharedTelephonyManager] addObserver:self forKeyPath:@"inCall" options:NSKeyValueObservingOptionNew context:NULL];
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	// enable the proximity sensor when in call.
	if ([keyPath isEqualToString:@"inCall"]) {
		if ([[%c(SBTelephonyManager) sharedTelephonyManager] inCall]) {
			if (!enabled) {
				enabled = YES;
				[(SpringBoard *)[UIApplication sharedApplication] setExpectsFaceContact:enabled];
				enabled = NO; // set it back to original (off) state.
			}
		}
	}
}

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
	// set enabled to opposite.
	enabled = !enabled;
	[(SpringBoard *)[UIApplication sharedApplication] setExpectsFaceContact:enabled];

	// create a bulletin request to display a banner when toggled.
	BBBulletinRequest *request = [[[%c(BBBulletinRequest) alloc] init] autorelease];
	request.title 	  = @"Always On Proximity";
	request.message   = [NSString stringWithFormat:@"Proximity sensor %@", ((enabled) ? @"enabled" : @"disabled")];	
	request.sectionID = @"com.apple.Preferences";
	
	[(SBBulletinBannerController *)[%c(SBBulletinBannerController) sharedInstance] observer:nil addBulletin:request forFeed:2];

	event.handled = YES;
}

+ (void)load
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [[LAActivator sharedInstance] registerListener:[self new] forName:@"com.flux.aop"];
    [pool drain];
}
@end

// simple static functions to respond to notifications posted by the SBSettings toggle
static void AOPEnableSensor(void)
{
	enabled = YES;
	[(SpringBoard *)[UIApplication sharedApplication] setExpectsFaceContact:YES];
}

static void AOPDisableSensor(void)
{
	enabled = NO;
	[(SpringBoard *)[UIApplication sharedApplication] setExpectsFaceContact:NO];
}

%ctor 
{
	NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
	
	%init;
	
	// register ourself for notifications from the SBSettings toggle
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)&AOPEnableSensor, CFSTR("com.flux.aoproximity/enable"), NULL, CFNotificationSuspensionBehaviorHold);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)&AOPDisableSensor, CFSTR("com.flux.aoproximity/disable"), NULL, CFNotificationSuspensionBehaviorHold);

	[p drain];
}
