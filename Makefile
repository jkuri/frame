ARCH := $(shell uname -m)

.PHONY: build run dmg format clean help install uninstall dev

all: release

release:
	@xcodebuild -scheme Frame -configuration Release build -quiet CODE_SIGNING_ALLOWED=NO -derivedDataPath .build -destination 'platform=macOS,arch=$(ARCH)'

build:
	@xcodebuild -scheme Frame -configuration Debug build -quiet CODE_SIGNING_ALLOWED=NO -derivedDataPath .build -destination 'platform=macOS,arch=$(ARCH)'

run: release
	@open .build/Build/Products/Release/Frame.app

dev: build
	@./.build/Build/Products/Debug/Frame.app/Contents/MacOS/Frame

dmg: release
	@./scripts/create-dmg.sh

install: uninstall release
	@cp -rf .build/Build/Products/Release/Frame.app /Applications/

uninstall:
	@rm -rf /Applications/Frame.app

format:
	@swift format -i -r Frame/

clean:
	@rm -rf .build dist

help:
	@echo "Frame Build System"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build     - Build debug version"
	@echo "  release   - Build release version (default)"
	@echo "  dmg       - Create .dmg installer"
	@echo "  install   - Install to /Applications"
	@echo "  uninstall - Remove from /Applications"
	@echo "  run       - Build and run the app"
	@echo "  dev       - Run in dev mode"
	@echo "  format    - Format Swift source files"
	@echo "  clean     - Clean build artifacts"
	@echo "  help      - Show this help"
