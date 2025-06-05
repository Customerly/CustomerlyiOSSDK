<a href="https://customerly.io" target="_blank">
    <img src="https://avatars1.githubusercontent.com/u/23583405?s=200&v=4" height="100" alt="Customerly logo">
</a>

# Customerly iOS SDK

[![SPM compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)]()
[![CocoaPods](https://img.shields.io/cocoapods/v/Customerly.svg)]()
![GitHub License](https://img.shields.io/github/license/Customerly/CustomerlyiOSSDK)

Customerly is a customer service platform that helps businesses provide better support to their customers. The iOS SDK allows you to integrate Customerly's features directly into your iOS application, including:

- Live chat support
- Help center articles
- User profiling
- Event tracking
- Lead generation
- Surveys
- Real-time video calls

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/customerly/CustomerlyiOSSDK.git", from: "1.0.2")
]
```

### CocoaPods

Add the following line to your Podfile:

```ruby
pod 'Customerly'
```

Then run:

```bash
pod install
```

## Basic Usage

### `CustomerlyView`
A SwiftUI view that integrates the Customerly messenger into your app. It initializes the SDK with the settings provided and attaches the SDK to the SwiftUI view hierarchy.

> **Important**: The SDK requires two initialization steps to work properly:
> 1. Calling `load(settings:)` to initialize the SDK
> 2. Providing a parent view controller either via `load(settings:parent:)` or `setParent(_:)`
> 
> When using `CustomerlyView`, both requirements are automatically handled for you. If you're not using `CustomerlyView`, you must handle these requirements manually.

```swift
import SwiftUI
import CustomerlySDK

@main
struct SampleAppApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Your app content here

                CustomerlyView(settings: CustomerlySettings(app_id: "YOUR_APP_ID")).onAppear(){
                    Customerly.shared.requestNotificationPermissionIfNeeded()
                }
            }
        }
    }
}
```

### Handling notifications

The SDK will use the `UNUserNotificationCenter` to present local notifications when a new message is received. We suggest you to add an `AppDelegate` to handle the notifications and open the messenger when a notification is tapped.

```swift
// ...
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                            didReceive response: UNNotificationResponse,
                            withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let conversationId = userInfo["conversationId"] as? Int {
            Customerly.shared.navigateToConversation(conversationId: conversationId)
        }
        Customerly.shared.show(withoutNavigation: true)
        completionHandler()
    }
}

@main
struct SampleAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // ...
}
```

## APIs

### Initialization and Configuration

#### load
Initializes the Customerly SDK with the provided settings.

```swift
Customerly.shared.load(settings: CustomerlySettings(app_id: "YOUR_APP_ID"), parent: self)
```

#### setParent
Sets a new parent view controller for presenting the messenger.

```swift
Customerly.shared.setParent(self)
```

#### update
Updates the Customerly SDK settings.

```swift
Customerly.shared.update(settings: CustomerlySettings(app_id: "YOUR_APP_ID"))
```

#### requestNotificationPermissionIfNeeded
Requests notification permissions if not already granted.

```swift
Customerly.shared.requestNotificationPermissionIfNeeded()
```

### Messenger Control

#### show
Shows the Customerly chat interface.

```swift
Customerly.shared.show(withoutNavigation: false)
```

#### hide
Hides the Customerly chat interface.

```swift
Customerly.shared.hide()
```

#### back
Navigates back in the chat interface.

```swift
Customerly.shared.back()
```

### User Management

#### logout
Logs out the current user.

```swift
Customerly.shared.logout()
```

#### registerLead
Registers a new lead with the provided email and optional attributes.

```swift
Customerly.shared.registerLead(email: "test@example.com", attributes: ["name": "John Doe"])
```

### Messaging

#### showNewMessage
Shows the chat interface with a pre-filled message.

```swift
Customerly.shared.showNewMessage(message: "Hello, how can I help you?")
```

#### sendNewMessage
Sends a new message and shows the chat interface.

```swift
Customerly.shared.sendNewMessage(message: "Hello, how can I help you?")
```

#### navigateToConversation
Navigates to a specific conversation.

```swift
Customerly.shared.navigateToConversation(conversationId: 123)
```

### Help Center

#### showArticle
Shows a specific help center article.

```swift
Customerly.shared.showArticle(collectionSlug: "collection", articleSlug: "article")
```

### Analytics

#### event
Tracks a custom event.

```swift
Customerly.shared.event(name: "event_name")
```

#### attribute
Sets a custom attribute for the current user.

```swift
Customerly.shared.attribute(name: "attribute_name", value: "attribute_value")
```

### Message Counts

#### getUnreadMessagesCount
Gets the count of unread messages.

```swift
Customerly.shared.getUnreadMessagesCount(completion: { count in
    print("Unread messages count: \(count)")
})
```

#### getUnreadConversationsCount
Gets the count of unread conversations.

```swift
Customerly.shared.getUnreadConversationsCount(completion: { count in
    print("Unread conversations count: \(count)")
})
```

### Callbacks

The SDK provides various callbacks for different events. Here are the main callback setters:

```swift
func setOnChatClosed(_ callback: @escaping () -> Void)
func setOnChatOpened(_ callback: @escaping () -> Void)
func setOnHelpCenterArticleOpened(_ callback: @escaping (HelpCenterArticle) -> Void)
func setOnLeadGenerated(_ callback: @escaping (String?) -> Void)
func setOnMessengerInitialized(_ callback: @escaping () -> Void)
func setOnNewConversation(_ callback: @escaping (String, [AttachmentPayload]) -> Void)
func setOnNewMessageReceived(_ callback: @escaping (Int?, String?, TimeInterval, Int?, Int) -> Void)
func setOnNewConversationReceived(_ callback: @escaping (Int) -> Void)
func setOnProfilingQuestionAnswered(_ callback: @escaping (String, String) -> Void)
func setOnProfilingQuestionAsked(_ callback: @escaping (String) -> Void)
func setOnRealtimeVideoAnswered(_ callback: @escaping (RealtimeCall) -> Void)
func setOnRealtimeVideoCanceled(_ callback: @escaping () -> Void)
func setOnRealtimeVideoReceived(_ callback: @escaping (RealtimeCall) -> Void)
func setOnRealtimeVideoRejected(_ callback: @escaping () -> Void)
func setOnSurveyAnswered(_ callback: @escaping () -> Void)
func setOnSurveyPresented(_ callback: @escaping (Survey) -> Void)
func setOnSurveyRejected(_ callback: @escaping () -> Void)
```

Each callback has a corresponding remove method:

```swift
func removeOnChatClosed()
func removeOnChatOpened()
// ... and so on for all callbacks
```

You can also remove all callbacks at once:

```swift
func removeAllCallbacks()
```

## Examples

The repository includes a sample project (`SampleApp`) that demonstrates how to integrate and use the Customerly SDK in a SwiftUI application. The example shows:

- Basic SDK initialization
- Messenger presentation
- User management
- Event tracking
- Message handling
- Notification handling
- Callback usage

To run the example:
1. Open the project in Xcode
2. Replace the `app_id` in `SampleAppApp.swift` with your Customerly app ID
3. Build and run the project

The sample app provides a complete reference implementation of all SDK features and can be used as a starting point for your integration.

## License

This SDK is licensed under the GNU GPLv3 License. See the LICENSE file for more details.
