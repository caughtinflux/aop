ARCHS = armv7
TARGET = iphone:clang:latest:5.0

include theos/makefiles/common.mk

TWEAK_NAME = AlwaysOnProximity

AlwaysOnProximity_FILES = Tweak.xm
AlwaysOnProximity_LDFLAGS = -lactivator -Llib/
AlwaysOnProximity_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += aoptoggle
include $(THEOS_MAKE_PATH)/aggregate.mk
