#import "FSSwitchDataSource.h"
#import "FSSwitchPanel.h"
#import <dlfcn.h>

@interface AOPSwitch : NSObject <FSSwitchDataSource>
@end

static void (*enableSensor)(void);
static void (*disableSensor)(void);
static BOOL (*currentState)(void);

@implementation AOPSwitch

+ (void)initialize
{
    void *handle = dlopen("/Library/MobileSubstrate/DynamicLibraries/AlwaysOnProximity.dylib", RTLD_NOW);
    if (handle) {
        enableSensor = (void(*)(void))dlsym(handle, "AOPEnableSensor");
        disableSensor = (void(*)(void))dlsym(handle, "AOPDisableSensor");
        currentState = (BOOL(*)(void))dlsym(handle, "AOPGetCurrentState");
    }
}

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier
{
    return (currentState() ? FSSwitchStateOn : FSSwitchStateOff) ;
}

- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier
{
    if (newState == FSSwitchStateOn) {
        enableSensor();
    }
    else if (newState == FSSwitchStateOff) {
        disableSensor();
    }
}

@end