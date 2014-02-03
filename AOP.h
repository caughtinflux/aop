#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBTelephonyManager.h>
#import <libactivator/libactivator.h>
#import "BannerClasses.h"

#ifdef __cplusplus
extern "C" {
#endif
    extern void AOPEnableSensor();
    extern void AOPDisableSensor();
    extern BOOL AOPGetCurrentState();
#ifdef __cplusplus
}
#endif
