#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SpringBoard/SBApplication.h>
#import <notify.h>

@interface SpringBoard : UIApplication
- (BOOL)expectsFaceContact;
- (void)setExpectsFaceContact:(BOOL)something;
- (SBApplication *)_accessibilityFrontMostApplication;
@end

// Required
extern "C" BOOL isCapable()
{
	return YES;
}

// Required
extern "C" BOOL isEnabled()
{
	return [(SpringBoard *)[UIApplication sharedApplication] expectsFaceContact];
}

// Required
extern "C" void setState(BOOL state)
{
	// send appropriate notification
	notify_post((state ? "com.flux.aoproximity/enable" : "com.flux.aoproximity/disable"));
}

// Required
// How long the toggle takes to toggle, in seconds.
extern "C" float getDelayTime()
{
	return 0.08f;
}

extern "C" BOOL allowInCall()
{
	return NO;
}
