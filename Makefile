APP_NAME = Reframed
SCHEME = Reframed
ARCH = $(shell uname -m)
DESTINATION = platform=macOS,arch=$(ARCH)
BUILD_DIR = .build
RELEASE_DIR = $(BUILD_DIR)/Build/Products/Release
DEBUG_DIR = $(BUILD_DIR)/Build/Products/Debug

.PHONY: build release run dev dmg format clean help install uninstall

all: help

build:
	@xcodebuild -project Reframed.xcodeproj -scheme $(SCHEME) -configuration Debug build -quiet -derivedDataPath $(BUILD_DIR) -destination '$(DESTINATION)'

release:
	@xcodebuild -project Reframed.xcodeproj -scheme $(SCHEME) -configuration Release build -quiet -derivedDataPath $(BUILD_DIR) -destination '$(DESTINATION)'

run: release
	@open $(RELEASE_DIR)/$(APP_NAME).app

dev: build
	@open $(DEBUG_DIR)/$(APP_NAME).app

dmg: release
	@./scripts/create-dmg.sh

install: uninstall release
	@cp -rf $(RELEASE_DIR)/$(APP_NAME).app /Applications/

uninstall:
	@rm -rf /Applications/$(APP_NAME).app

format:
	@swift format -i -r Reframed/

clean:
	@rm -rf $(BUILD_DIR) dist

help:
	@echo "Reframed Build System"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build     - Build debug version"
	@echo "  release   - Build release version"
	@echo "  dmg       - Create .dmg installer"
	@echo "  install   - Install to /Applications"
	@echo "  uninstall - Remove from /Applications"
	@echo "  run       - Build release and run"
	@echo "  dev       - Build debug and run"
	@echo "  format    - Format Swift source files"
	@echo "  clean     - Clean build artifacts"
	@echo "  help      - Show this help"
