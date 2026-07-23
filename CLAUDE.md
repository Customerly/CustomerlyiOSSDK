# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

The **Customerly iOS SDK** — a native wrapper that embeds the Customerly web messenger (live chat, help center, surveys, lead gen, realtime video) into iOS apps. It ships via both **Swift Package Manager** and **CocoaPods**.

- Min deployment target: **iOS 13**, Swift **5.6**.
- Distributed as source (`source_files = "CustomerlySDK/**/*.swift"`); there is no compiled framework artifact.
- Zero third-party dependencies — only `UIKit`, `WebKit`, `SwiftUI`, `UserNotifications`.

## Architecture — the key thing to understand

**The SDK is a thin native bridge over the JavaScript messenger.** There is no native chat UI. `Customerly.load()` builds a `WKWebView`, injects an inline HTML page (`loadMessengerHTML()` in `Customerly.swift`) that loads `https://messenger.customerly.io/launcher.js`, and the WebView is presented modally when `show()` is called. Almost every public API is implemented by calling `evaluateJavaScript(...)` against that page.

Two directions of communication:

1. **Native → JS**: public methods like `event`, `attribute`, `update`, `show`, `logout`, `showArticle` serialize their args and call `customerly.*(...)` / `_customerly_sdk.*(...)` via `evaluateJavascript`. **Every interpolated argument must go through `JSValue.literal(_:)`** (in `JSValue.swift`), which JSON-encodes it into a safe JS literal — never interpolate a raw string, or an apostrophe will break the call and crafted input can inject script.
2. **JS → Native**: the injected page registers `customerly.on*` handlers that `postMessage` JSON to the `customerlyNative` message handler. `userContentController(_:didReceive:)` parses `{type, data}` and dispatches to the registered Swift callback. **When adding a new callback you must touch all layers**: the JS handler in `loadMessengerHTML()`, the `switch` case in `userContentController`, a typed optional closure property on the `CustomerlyCallbacks` struct (`CustomerlyCallback.swift`), and the `setOn*/removeOn*` pair in `Customerly.swift`. The README API list should be updated too.

Other structural notes:

- `Customerly` is a `NSObject` **singleton** (`Customerly.shared`) holding all state (webView, callbacks, parent VC). It must be driven on the main thread.
- **Two-step init**: `load(settings:)` creates the webview, and a **parent view controller** must be set (via `load(settings:parent:)` or `setParent(_:)`) before `show()` can present. `CustomerlyView` (a `UIViewControllerRepresentable`) is the SwiftUI entry point that wires both automatically.
- The webview is **preloaded once and reused** — `show()` reparents the same `WKWebView` into a freshly-presented container VC; `hide()`/dismiss tears the container down but keeps the webview alive. `load()` is a no-op if a webView already exists.
- Callbacks are stored as type-safe optional closures on the `CustomerlyCallbacks` struct; the compiler enforces signatures at registration. They can be set before `load()`. The class is `@MainActor`-isolated — drive it from the main thread.
- Some incoming events have **side effects beyond the callback**: `onNewMessageReceived` schedules a local `UNUserNotification`, `onRealtimeVideoReceived`/`onSurveyPresented` auto-call `show()`, `onChatClosed` calls `hide()`.
- `CustomerlySettings` (and nested `Company`/`Event`) are value structs whose `dictionary` computed property is the JSON payload sent to JS. `sdkMode: true` and `disableAutofocus: true` are always injected. Device info (`getDeviceInfo()`) is merged in at load time.
- Cookies are bridged between `WKWebsiteDataStore` and `HTTPCookieStorage` on load / app-terminate to persist the messenger session.

## Models

`CustomerlySDK/models/` holds the DTOs decoded from the JS `data` payloads (`HelpCenterArticle`, `Survey`, `RealtimeCall`, `UnreadMessage`, `AttachmentPayload`, `Account`) plus `CustomerlySettings`. Most decode via a `init(from: [String: Any])`-style initializer, not `Codable`.

## Building & testing

Unit tests live in `Tests/CustomerlyTests/` (a Swift Package `.testTarget`); SwiftLint config is in `.swiftlint.yml`. `swift build`/`swift test` do **not** work on macOS because the SDK imports UIKit — always target an iOS simulator.

```bash
# Build the SDK via the Xcode project (adjust simulator as needed)
xcodebuild -project CustomerlySDK.xcodeproj -scheme CustomerlySDK \
  -destination 'generic/platform=iOS Simulator' build

# Run the unit tests. The Package.swift and .xcodeproj share this directory and xcodebuild
# resolves the project (no test target) by default, so move it aside for the test run:
mv CustomerlySDK.xcodeproj /tmp/proj.aside
xcodebuild test -scheme Customerly \
  -destination "platform=iOS Simulator,id=$(xcrun simctl list devices available | grep -m1 -oE '\([0-9A-F-]{36}\)' | tr -d '()')"
mv /tmp/proj.aside CustomerlySDK.xcodeproj
```

CI (`.github/workflows/ci.yml`) runs the build, the tests, and SwiftLint on every push/PR.

`SampleApp/` (`SampleAppApp.swift`) is the reference integration exercising every feature. To run it, open the project in Xcode and set a real `app_id`.

## Releasing (CocoaPods + SPM)

Version lives in **three places that must stay in sync**: `Customerly.podspec` (`s.version`), `README.md` (the SPM `from: "x.y.z"` line), and `CustomerlySDK/Customerly.swift` (`Customerly.version`, sent to the backend as `sdk_version`). Release is tag-driven via `.github/workflows/release.yml`:

1. Bump the version in `Customerly.podspec`, `README.md`, **and** `CustomerlySDK/Customerly.swift`.
2. Push to the default branch.
3. Create and push a tag matching the version (workflow triggers on `*.*.*`).
4. CI checks that the tag, podspec, and README versions match (auto-committing a fix to the default branch if they don't) and pushes the pod to CocoaPods trunk.

SPM consumers just resolve the git tag — no publish step.
