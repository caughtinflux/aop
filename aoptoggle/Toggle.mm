#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SpringBoard/SBApplication.h>
#import <notify.h>

@interface SpringBoard : UIApplication
- (BOOL)expectsFaceContact;
@end

extern "C" BOOL isCapable()
{
	// can return YES, because it can only be installed on devices with telephony capabilities
	return YES;
}

extern "C" BOOL isEnabled()
{
	return [(SpringBoard *)[UIApplication sharedApplication] expectsFaceContact];
}

extern "C" void setState(BOOL state)
{
	// send appropriate notification
	notify_post((state ? "com.flux.aoproximity/enable" : "com.flux.aoproximity/disable"));
}

extern "C" float getDelayTime()
{
	return 0.08f;
}

extern "C" BOOL allowInCall()
{
	return NO;
}
