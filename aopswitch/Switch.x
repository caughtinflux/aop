#import "FSSwitchDataSource.h"
#import "FSSwitchPanel.h"
#import <dlfcn.h>

@interface AOPSwitch : NSObject <FSSwitchDataSource>
@end

static void (*SetSensorEnabled)(BOOL);
static BOOL (*SensorIsEnabled)(void);

@implementation AOPSwitch

+ (void)initialize
{
    void *handle = dlopen("/Library/MobileSubstrate/DynamicLibraries/AlwaysOnProximity.dylib", RTLD_NOW);
    if (handle) {
        SetSensorEnabled = (void(*)(BOOL))dlsym(handle, "AOPSetIsEnabled");
        SensorIsEnabled = (BOOL(*)(void))dlsym(handle, "AOPGetIsEnabled");
    }
}

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier
{
    return (SensorIsEnabled() ? FSSwitchStateOn : FSSwitchStateOff) ;
}

- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier
{
    SetSensorEnabled(newState == FSSwitchStateOn);
}

@end