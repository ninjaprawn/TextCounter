ARCHS = armv7 arm64
# TARGET = iphone:clang:10.2:10.2
THEOS_DEVICE_IP = localhost
THEOS_DEVICE_PORT = 2222

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TextCounter
TextCounter_FILES = Convo.xm All.xm $(wildcard FMDB/*.m)
TextCounter_FRAMEWORKS = Foundation UIKit
TextCounter_PRIVATE_FRAMEWORKS = ChatKit
TextCounter_LDFLAGS=-lsqlite3

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 MobileSMS"
