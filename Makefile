ARCHS = armv7 armv7s arm64
TARGET = iphone:clang:latest:7.0

include theos/makefiles/common.mk

TWEAK_NAME = AlwaysOnProximity

AlwaysOnProximity_FILES = Tweak.xm
AlwaysOnProximity_LDFLAGS = -lactivator
AlwaysOnProximity_FRAMEWORKS = UIKit Foundation CoreFoundation

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += aoptoggle
SUBPROJECTS += AOPSwitch
SUBPROJECTS += aopswitch
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall backboardd"
