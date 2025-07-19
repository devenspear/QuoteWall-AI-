SCHEME = QuoteWallAI
DEST   = "platform=iOS Simulator,name=iPhone 16,OS=18.0"

.PHONY: build run test logs format clean

build:
	xcodebuild -scheme $(SCHEME) \
	  -destination $(DEST) \
	  build | xcbeautify

run: build
	xcrun simctl install booted \
	  build/Build/Products/Debug-iphonesimulator/$(SCHEME).app || true
	xcrun simctl launch booted com.LifeKitchenSudios.QuoteWallAI.QuoteWallAI

test:
	xcodebuild test -scheme $(SCHEME) \
	  -destination $(DEST) | xcbeautify

logs:
	xcrun simctl spawn booted log stream

format:
	swiftformat . && swiftlint --fix

clean:
	xcodebuild clean -scheme $(SCHEME)
