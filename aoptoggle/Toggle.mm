#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SpringBoard/SBApplication.h>
#import <dlfcn.h>
#import "../AOP.h"


static void (*SetSensorEnabled)(BOOL);
static BOOL (*SensorIsEnabled)(void);

extern "C" BOOL isCapable(void)
{
    // can return YES, because it can only be installed on devices with telephony capabilities
    return YES;
}

extern "C" BOOL isEnabled(void)
{
    return SensorIsEnabled();
}

extern "C" void setState(BOOL state)
{
    // send appropriate notification
    SetSensorEnabled(state);
}

extern "C" float getDelayTime(void)
{
    return 0.08f;
}

extern "C" BOOL allowInCall(void)
{
    return NO;
}

static void __attribute__((constructor)) __constructor(void)
{
    void *handle = dlopen("/Library/MobileSubstrate/DynamicLibraries/AlwaysOnProximity.dylib", RTLD_NOW);
    if (handle) {
        SetSensorEnabled = (void(*)(BOOL))dlsym(handle, "AOPSetIsEnabled");
        SensorIsEnabled = (BOOL(*)(void))dlsym(handle, "AOPGetIsEnabled");
    }
}
