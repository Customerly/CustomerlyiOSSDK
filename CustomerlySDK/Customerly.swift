import UIKit
@preconcurrency import WebKit
import UserNotifications
import os

@MainActor
public class Customerly: NSObject {
    /// Shared singleton instance
    public static let shared = Customerly()

    /// The Customerly iOS SDK version. Kept in sync with `Customerly.podspec` and `README.md`.
    public static let version = "1.1.0"

    /// Enables verbose SDK logging. Off by default so the SDK stays silent in host apps' consoles.
    public static var isLoggingEnabled: Bool = false

    private static let logSubsystem = "io.customerly.sdk"

    /// Routes SDK diagnostics through the unified logging system, gated by `isLoggingEnabled`.
    static func log(_ message: String) {
        guard isLoggingEnabled else { return }
        if #available(iOS 14.0, *) {
            Logger(subsystem: logSubsystem, category: "Customerly").notice("\(message, privacy: .public)")
        } else {
            NSLog("[Customerly] %@", message)
        }
    }

    private var webView: WKWebView?
    // Container view controller presenting the messenger
    private var controller: UIViewController?
    // Parent view controller for presenting the messenger
    private weak var parentViewController: UIViewController?
    private var settings: CustomerlySettings?
    private var callbacks = CustomerlyCallbacks()
    private var isPresenting: Bool = false
    private var webViewBottomConstraint: NSLayoutConstraint?

    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func applicationWillTerminate() {
        saveCookies()
    }

    /// Loads and initializes the SDK with the provided settings
    /// - Parameters:
    ///   - settings: Configuration settings for the SDK
    ///   - parent: The view controller from which to present the messenger modally
    public func load(settings: CustomerlySettings, parent: UIViewController? = nil) {
        guard webView == nil else {
            return
        }

        self.settings = settings
        self.parentViewController = parent

        let config = WKWebViewConfiguration()
        let userContent = config.userContentController
        userContent.add(self, name: "customerlyNative")

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = self
        wv.isHidden = true
        wv.backgroundColor = .systemBackground
        wv.isOpaque = false
        wv.scrollView.isScrollEnabled = false
        wv.scrollView.bounces = false

        self.webView = wv

        loadCookies()
        loadMessengerHTML()
    }

    /// Sets a new parent view controller for presenting the messenger
    /// - Parameter parent: The new view controller from which to present the messenger modally
    public func setParent(_ parent: UIViewController) {
        self.parentViewController = parent
    }

    /// Requests notification permissions if needed
    public func requestNotificationPermissionIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            if let error = error {
                Customerly.log("Failed to request notification permission: \(error)")
            }
        }
    }

    private func getDeviceInfo() -> [String: Any] {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
                     Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ??
                     "Unknown App"
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown Version"
        let deviceName = UIDevice.current.name
        let osVersion = UIDevice.current.systemVersion

        return [
            "os": "ios",
            "app_name": appName,
            "app_version": appVersion,
            "device": "Apple \(deviceName)",
            "os_version": osVersion,
            "sdk_version": Customerly.version
        ]
    }

    private func loadMessengerHTML() {
        guard let settings = settings else {
            Customerly.log("Error - Settings not available")
            return
        }

        // Create a mutable copy of settings dictionary and add device info
        var settingsWithDevice = settings.dictionary
        settingsWithDevice["device"] = getDeviceInfo()

        let settingsJson = try? JSONSerialization.data(withJSONObject: settingsWithDevice)
        let settingsString = String(data: settingsJson ?? Data(), encoding: .utf8) ?? "{}"

        let html = """
        <!DOCTYPE html>
        <html>
          <head><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
          <body>
            <script>
                !function(){var e=window,i=document,t="customerly",n="queue",o="load",r="settings",u=e[t]=e[t]||[];if(u.t){return void u.i("[customerly] SDK already initialized. Snippet included twice.")}u.t=!0;u.loaded=!1;u.o=["event","attribute","update","show","hide","open","close"];u[n]=[];u.i=function(t){e.console&&!u.debug&&console.error&&console.error(t)};u.u=function(e){return function(){var t=Array.prototype.slice.call(arguments);return t.unshift(e),u[n].push(t),u}};u[o]=function(t){u[r]=t||{};if(u.loaded){return void u.i("[customerly] SDK already loaded. Use `customerly.update` to change settings.")}u.loaded=!0;var e=i.createElement("script");e.type="text/javascript",e.async=!0,e.src="https://messenger.customerly.io/launcher.js";var n=i.getElementsByTagName("script")[0];n.parentNode.insertBefore(e,n)};u.o.forEach(function(t){u[t]=u.u(t)})}();

                // Register callbacks
                customerly.onMessengerInitialized = function() {
                window.webkit.messageHandlers.customerlyNative.postMessage(JSON.stringify({type: "onMessengerInitialized"}));
                };

                customerly.onChatClosed = function() {
                window.webkit.messageHandlers.customerlyNative.postMessage(JSON.stringify({type: "onChatClosed"}));
                };

                customerly.onChatOpened = function() {
                window.webkit.messageHandlers.customerlyNative.postMessage(JSON.stringify({type: "onChatOpened"}));
                };

                customerly.onHelpCenterArticleOpened = function(article) {
                window.webkit.messageHandlers.customerlyNative.postMessage(JSON.stringify({
                    type: "onHelpCenterArticleOpened",
                    data: article
                }));
                };

                customerly.onLeadGenerated = function(email) {
                window.webkit.messageHandlers.customerlyNative.postMessage(JSON.stringify({
                    type: "onLeadGenerated",
                    data: {email: email}
                }));
                };

                customerly.onMessageRead = function(conversationId, conversationMessageId) {
                window.webkit.messageHandlers.customerlyNative.postMessage(JSON.stringify({
                    type: "onMessageRead",
                    data: {conversationId: conversationId, conversationMessageId: conversationMessageId}
                }));
                };

                customerly.onNewConversation = function(message, attachments) {
                window.webkit.messageHandlers.customerlyNative.postMessage(JSON.stringify({
                    type: "onNewConversation",
                    data: {message: message, attachments: attachments}
                }));
                };

                customerly.onNewMessageReceived = function(message) {
                window.webkit.messageHandlers.customerlyNative.postMessage(JSON.stringify({
                    type: "onNewMessageReceived",
                    data: message
                }));
                };

                customerly.onNewConversationReceived = function(conversationId) {
                window.webkit.messageHandlers.customerlyNative.postMessage(JSON.stringify({
                    type: "onNewConversationReceived",
                    data: {conversationId: conversationId}
                }));
                };

                customerly.onProfilingQuestionAnswered = function(attribute, value) {
                window.webkit.messageHandlers.customerlyNative.postMessage(JSON.stringify({
                    type: "onProfilingQuestionAnswered",
                    data: {attribute: attribute, value: value}
                }));
                };

                customerly.onProfilingQuestionAsked = function(attribute) {
                window.webkit.messageHandlers.customerlyNative.postMessage(JSON.stringify({
                    type: "onProfilingQuestionAsked",
                    data: {attribute: attribute}
                }));
                };

                customerly.onRealtimeVideoAnswered = function(call) {
                window.webkit.messageHandlers.customerlyNative.postMessage(JSON.stringify({
                    type: "onRealtimeVideoAnswered",
                    data: call
                }));
                };

                customerly.onRealtimeVideoCanceled = function() {
                window.webkit.messageHandlers.customerlyNative.postMessage(JSON.stringify({type: "onRealtimeVideoCanceled"}));
                };

                customerly.onRealtimeVideoReceived = function(call) {
                window.webkit.messageHandlers.customerlyNative.postMessage(JSON.stringify({type: "onRealtimeVideoReceived", data: call}));
                };

                customerly.onRealtimeVideoRejected = function() {
                window.webkit.messageHandlers.customerlyNative.postMessage(JSON.stringify({type: "onRealtimeVideoRejected"}));
                };

                customerly.onSurveyAnswered = function() {
                window.webkit.messageHandlers.customerlyNative.postMessage(JSON.stringify({type: "onSurveyAnswered"}));
                };

                customerly.onSurveyPresented = function(survey) {
                window.webkit.messageHandlers.customerlyNative.postMessage(JSON.stringify({type: "onSurveyPresented", data: survey}));
                };

                customerly.onSurveyRejected = function() {
                window.webkit.messageHandlers.customerlyNative.postMessage(JSON.stringify({type: "onSurveyRejected"}));
                };

                // Load Customerly Messenger
                customerly.load(\(settingsString));
            </script>
          </body>
        </html>
        """

        webView?.loadHTMLString(html, baseURL: URL(string: "https://customerly.io/"))
    }

    private func saveCookies() {
        guard webView != nil else { return }

        let dataStore = WKWebsiteDataStore.default()
        let cookieStore = dataStore.httpCookieStore

        cookieStore.getAllCookies { cookies in
            for cookie in cookies {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
    }

    private func loadCookies() {
        guard webView != nil else { return }

        let dataStore = WKWebsiteDataStore.default()
        let cookieStore = dataStore.httpCookieStore

        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                cookieStore.setCookie(cookie)
            }
        }
    }

    private func evaluateJavascript(_ script: String, resultCallback: ((Any?, Error?) -> Void)? = nil) {
        guard let webView = webView else {
            Customerly.log("Error - WebView not loaded")
            return
        }

        webView.evaluateJavaScript(script) { result, error in
            resultCallback?(result, error)
        }
    }

    /// Presents the messenger by showing the preloaded WebView
    /// - Parameters:
    ///   - withoutNavigation: Whether to navigate to messenger home page
    public func show(withoutNavigation: Bool = false) {
        guard let wv = webView else {
            Customerly.log("Error - WebView not loaded")
            assertionFailure("Messenger not loaded. Call load() first.")
            return
        }

        guard let parent = parentViewController else {
            Customerly.log("Error - No parent view controller set")
            assertionFailure("No parent view controller set. Call load() or setParent() first.")
            return
        }

        if self.controller != nil || self.isPresenting {
            Customerly.log("Messenger is already presented or being presented.")
            return
        }

        self.isPresenting = true

        let containerVC = UIViewController()
        containerVC.view.backgroundColor = .systemBackground

        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerVC.view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: containerVC.view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: containerVC.view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: containerVC.view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: containerVC.view.bottomAnchor)
        ])

        wv.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(wv)

        if #available(iOS 11.0, *) {
            let bottomConstraint = wv.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor)
            NSLayoutConstraint.activate([
                wv.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor),
                wv.leadingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leadingAnchor),
                wv.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor),
                bottomConstraint
            ])
            self.webViewBottomConstraint = bottomConstraint
        } else {
            let bottomConstraint = wv.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            NSLayoutConstraint.activate([
                wv.topAnchor.constraint(equalTo: containerView.topAnchor),
                wv.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                wv.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                bottomConstraint
            ])
            self.webViewBottomConstraint = bottomConstraint
        }

        wv.isHidden = false

        // Register for keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        self.evaluateJavascript("customerly.open()")
        if !withoutNavigation {
            self.evaluateJavascript("_customerly_sdk.navigate('/', true)")
        }

        containerVC.presentationController?.delegate = self

        parent.present(containerVC, animated: true) {
            self.controller = containerVC
            self.isPresenting = false
        }
    }

    private func afterHide(withBack: Bool = false) {
        if withBack {
            self.back()
        }

        self.controller = nil
        self.webView?.isHidden = true
        self.isPresenting = false

        // Remove keyboard observers
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    /// Hides the messenger
    public func hide() {
        controller?.dismiss(animated: true) {
            self.afterHide()
        }
    }

    /// Logs out the current user
    public func logout() {
        evaluateJavascript("customerly.logout()")
    }

    /// Tracks an event with the given name
    /// - Parameter name: The name of the event to track
    public func event(name: String) {
        evaluateJavascript("customerly.event(\(JSValue.literal(name)))")
    }

    /// Sets a user attribute
    /// - Parameters:
    ///   - name: The name of the attribute
    ///   - value: The value of the attribute
    public func attribute(name: String, value: Any) {
        evaluateJavascript("customerly.attribute(\(JSValue.literal(name)), \(JSValue.literal(value)))")
    }

    /// Updates the SDK settings
    /// - Parameter settings: The new settings to apply
    public func update(settings: CustomerlySettings) {
        self.settings = settings
        if let settingsJson = try? JSONSerialization.data(withJSONObject: settings.dictionary),
           let settingsString = String(data: settingsJson, encoding: .utf8) {
            evaluateJavascript("customerly.update(\(settingsString))")
        }
    }

    /// Shows the messenger with a new message
    /// - Parameter message: The new message to prepopulate in the messenger
    public func showNewMessage(message: String) {
        show()
        evaluateJavascript("customerly.showNewMessage(\(JSValue.literal(message)))")
    }

    /// Sends a new message
    /// - Parameter message: The new message to send
    public func sendNewMessage(message: String) {
        show()
        evaluateJavascript("customerly.sendNewMessage(\(JSValue.literal(message)))")
    }

    /// Shows a specific article
    /// - Parameters:
    ///   - collectionSlug: The collection slug
    ///   - articleSlug: The article slug
    public func showArticle(collectionSlug: String, articleSlug: String) {
        show()
        evaluateJavascript("customerly.showArticle(\(JSValue.literal(collectionSlug)), \(JSValue.literal(articleSlug)))")
    }

    /// Registers a new lead
    /// - Parameters:
    ///   - email: The email of the lead
    ///   - attributes: Optional attributes for the lead
    public func registerLead(email: String, attributes: [String: String]? = nil) {
        let attributesJson = attributes.map { JSValue.literal($0) } ?? "null"
        evaluateJavascript("customerly.registerLead(\(JSValue.literal(email)), \(attributesJson))")
    }

    /// Navigates back in the messenger
    public func back() {
        evaluateJavascript("_customerly_sdk.back()")
    }

    /// Navigates to a specific conversation
    /// - Parameter conversationId: The ID of the conversation to navigate to
    public func navigateToConversation(conversationId: Int) {
        // The messenger's `_customerly_sdk.navigateToConversation` expects a string argument.
        evaluateJavascript("_customerly_sdk.navigateToConversation(\(JSValue.literal(String(conversationId))))")
    }

    /// Gets the count of unread messages
    /// - Parameter completion: Callback with the count of unread messages
    public func getUnreadMessagesCount(completion: @escaping (Int) -> Void) {
        evaluateJavascript("customerly.unreadMessagesCount") { result, _ in
            completion((result as? NSNumber)?.intValue ?? 0)
        }
    }

    /// Gets the count of unread conversations
    /// - Parameter completion: Callback with the count of unread conversations
    public func getUnreadConversationsCount(completion: @escaping (Int) -> Void) {
        evaluateJavascript("customerly.unreadConversationsCount") { result, _ in
            if let count = (result as? NSNumber)?.intValue {
                completion(count)
            } else {
                completion(0)
            }
        }
    }

    /// Sets a callback for when the chat is closed
    /// - Parameter callback: The callback to handle the event
    public func setOnChatClosed(_ callback: @escaping () -> Void) {
        callbacks.onChatClosed = callback
    }

    /// Sets a callback for when the chat is opened
    /// - Parameter callback: The callback to handle the event
    public func setOnChatOpened(_ callback: @escaping () -> Void) {
        callbacks.onChatOpened = callback
    }

    /// Sets a callback for when a help center article is opened
    /// - Parameter callback: The callback to handle the event
    public func setOnHelpCenterArticleOpened(_ callback: @escaping (HelpCenterArticle) -> Void) {
        callbacks.onHelpCenterArticleOpened = callback
    }

    /// Sets a callback for when a lead is generated
    /// - Parameter callback: The callback to handle the event
    public func setOnLeadGenerated(_ callback: @escaping (String?) -> Void) {
        callbacks.onLeadGenerated = callback
    }

    /// Sets a callback for when a message is read
    /// - Parameter callback: The callback to handle the event
    public func setOnMessageRead(_ callback: @escaping (Int, Int) -> Void) {
        callbacks.onMessageRead = callback
    }

    /// Sets a callback for when the messenger is initialized
    /// - Parameter callback: The callback to handle the event
    public func setOnMessengerInitialized(_ callback: @escaping () -> Void) {
        callbacks.onMessengerInitialized = callback
    }

    /// Sets a callback for when a new conversation is created
    /// - Parameter callback: The callback to handle the event
    public func setOnNewConversation(_ callback: @escaping (String, [AttachmentPayload]) -> Void) {
        callbacks.onNewConversation = callback
    }

    /// Sets a callback for when a new message is received
    /// - Parameter callback: The callback to handle the event
    public func setOnNewMessageReceived(_ callback: @escaping (UnreadMessage) -> Void) {
        callbacks.onNewMessageReceived = callback
    }

    /// Sets a callback for when a new conversation is received
    /// - Parameter callback: The callback to handle the event
    public func setOnNewConversationReceived(_ callback: @escaping (Int) -> Void) {
        callbacks.onNewConversationReceived = callback
    }

    /// Sets a callback for when a profiling question is answered
    /// - Parameter callback: The callback to handle the event
    public func setOnProfilingQuestionAnswered(_ callback: @escaping (String, String) -> Void) {
        callbacks.onProfilingQuestionAnswered = callback
    }

    /// Sets a callback for when a profiling question is asked
    /// - Parameter callback: The callback to handle the event
    public func setOnProfilingQuestionAsked(_ callback: @escaping (String) -> Void) {
        callbacks.onProfilingQuestionAsked = callback
    }

    /// Sets a callback for when a realtime video call is answered
    /// - Parameter callback: The callback to handle the event
    public func setOnRealtimeVideoAnswered(_ callback: @escaping (RealtimeCall) -> Void) {
        callbacks.onRealtimeVideoAnswered = callback
    }

    /// Sets a callback for when a realtime video call is canceled
    /// - Parameter callback: The callback to handle the event
    public func setOnRealtimeVideoCanceled(_ callback: @escaping () -> Void) {
        callbacks.onRealtimeVideoCanceled = callback
    }

    /// Sets a callback for when a realtime video call is received
    /// - Parameter callback: The callback to handle the event
    public func setOnRealtimeVideoReceived(_ callback: @escaping (RealtimeCall) -> Void) {
        callbacks.onRealtimeVideoReceived = callback
    }

    /// Sets a callback for when a realtime video call is rejected
    /// - Parameter callback: The callback to handle the event
    public func setOnRealtimeVideoRejected(_ callback: @escaping () -> Void) {
        callbacks.onRealtimeVideoRejected = callback
    }

    /// Sets a callback for when a survey is answered
    /// - Parameter callback: The callback to handle the event
    public func setOnSurveyAnswered(_ callback: @escaping () -> Void) {
        callbacks.onSurveyAnswered = callback
    }

    /// Sets a callback for when a survey is presented
    /// - Parameter callback: The callback to handle the event
    public func setOnSurveyPresented(_ callback: @escaping (Survey) -> Void) {
        callbacks.onSurveyPresented = callback
    }

    /// Sets a callback for when a survey is rejected
    /// - Parameter callback: The callback to handle the event
    public func setOnSurveyRejected(_ callback: @escaping () -> Void) {
        callbacks.onSurveyRejected = callback
    }

    /// Removes the callback for when the chat is closed
    public func removeOnChatClosed() {
        callbacks.onChatClosed = nil
    }

    /// Removes the callback for when the chat is opened
    public func removeOnChatOpened() {
        callbacks.onChatOpened = nil
    }

    /// Removes the callback for when a help center article is opened
    public func removeOnHelpCenterArticleOpened() {
        callbacks.onHelpCenterArticleOpened = nil
    }

    /// Removes the callback for when a lead is generated
    public func removeOnLeadGenerated() {
        callbacks.onLeadGenerated = nil
    }

    /// Removes the callback for when a message is read
    public func removeOnMessageRead() {
        callbacks.onMessageRead = nil
    }

    /// Removes the callback for when a new conversation is created
    public func removeOnNewConversation() {
        callbacks.onNewConversation = nil
    }

    /// Removes the callback for when a new message is received
    public func removeOnNewMessageReceived() {
        callbacks.onNewMessageReceived = nil
    }

    /// Removes the callback for when a new conversation is received
    public func removeOnNewConversationReceived() {
        callbacks.onNewConversationReceived = nil
    }

    /// Removes the callback for when a profiling question is answered
    public func removeOnProfilingQuestionAnswered() {
        callbacks.onProfilingQuestionAnswered = nil
    }

    /// Removes the callback for when a profiling question is asked
    public func removeOnProfilingQuestionAsked() {
        callbacks.onProfilingQuestionAsked = nil
    }

    /// Removes the callback for when a realtime video call is answered
    public func removeOnRealtimeVideoAnswered() {
        callbacks.onRealtimeVideoAnswered = nil
    }

    /// Removes the callback for when a realtime video call is canceled
    public func removeOnRealtimeVideoCanceled() {
        callbacks.onRealtimeVideoCanceled = nil
    }

    /// Removes the callback for when a realtime video call is received
    public func removeOnRealtimeVideoReceived() {
        callbacks.onRealtimeVideoReceived = nil
    }

    /// Removes the callback for when a realtime video call is rejected
    public func removeOnRealtimeVideoRejected() {
        callbacks.onRealtimeVideoRejected = nil
    }

    /// Removes the callback for when a survey is answered
    public func removeOnSurveyAnswered() {
        callbacks.onSurveyAnswered = nil
    }

    /// Removes the callback for when a survey is presented
    public func removeOnSurveyPresented() {
        callbacks.onSurveyPresented = nil
    }

    /// Removes the callback for when a survey is rejected
    public func removeOnSurveyRejected() {
        callbacks.onSurveyRejected = nil
    }

    /// Removes all registered callbacks
    public func removeAllCallbacks() {
        callbacks = CustomerlyCallbacks()
    }

    private func abstractify(_ html: String?) -> String {
        guard let html = html, !html.isEmpty else {
            return "📎 Attachment"
        }

        // Decode HTML entities and strip tags
        let decoded: String
        if let data = html.data(using: .utf8),
           let attributed = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html,
                          .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil) {
            decoded = attributed.string
        } else {
            decoded = html
        }

        let trimmed = decoded.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return "🖼 Image"
        }

        if trimmed.count > 100 {
            let index = trimmed.index(trimmed.startIndex, offsetBy: 100)
            return "\(trimmed[..<index])..."
        } else {
            return trimmed
        }
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }

        let keyboardHeight = keyboardFrame.height
        self.webViewBottomConstraint?.constant = -keyboardHeight

        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16), animations: {
            self.controller?.view.layoutIfNeeded()
        }, completion: nil)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }

        self.webViewBottomConstraint?.constant = 0

        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16), animations: {
            self.controller?.view.layoutIfNeeded()
        }, completion: nil)
    }
}

extension Customerly: WKScriptMessageHandler {
    public func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "customerlyNative",
              let messageBody = message.body as? String else { return }

        do {
            guard let data = messageBody.data(using: .utf8),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = json["type"] as? String else {
                Customerly.log("Error - Invalid message format")
                return
            }

            let messageData = json["data"] as? [String: Any]

            switch type {
            case "onChatClosed":
                hide()
                callbacks.onChatClosed?()

            case "onChatOpened":
                callbacks.onChatOpened?()

            case "onHelpCenterArticleOpened":
                guard let data = messageData,
                      let article = try? HelpCenterArticle(from: data) else { return }
                callbacks.onHelpCenterArticleOpened?(article)

            case "onLeadGenerated":
                let email = messageData?["email"] as? String
                callbacks.onLeadGenerated?(email)

            case "onMessageRead":
                guard let data = messageData,
                      let conversationId = data["conversationId"] as? Int,
                      let conversationMessageId = data["conversationMessageId"] as? Int else { return }
                callbacks.onMessageRead?(conversationId, conversationMessageId)

            case "onMessengerInitialized":
                callbacks.onMessengerInitialized?()

            case "onNewConversation":
                guard let data = messageData,
                      let message = data["message"] as? String else { return }

                let attachments = (data["attachments"] as? [[String: Any]])?.compactMap { dict -> AttachmentPayload? in
                    guard let name = dict["name"] as? String,
                          let size = dict["size"] as? Int,
                          let base64 = dict["base64"] as? String else {
                        return nil
                    }
                    return AttachmentPayload(name: name, size: size, base64: base64)
                } ?? []

                callbacks.onNewConversation?(message, attachments)

            case "onNewMessageReceived":
                guard let data = messageData,
                      let conversationId = data["conversationId"] as? Int else {
                    return
                }

                // Create UnreadMessage object
                let unreadMessage = UnreadMessage(
                    accountId: data["accountId"] as? Int64,
                    accountName: data["accountName"] as? String,
                    message: data["message"] as? String,
                    timestamp: Int64((data["timestamp"] as? TimeInterval) ?? 0),
                    userId: data["userId"] as? Int64,
                    conversationId: Int64(conversationId)
                )

                // Only surface a local notification when the messenger isn't already on screen —
                // otherwise the user would get a redundant banner for a chat they're actively viewing.
                if controller == nil {
                    let content = UNMutableNotificationContent()
                    let abstractedMessage = abstractify(unreadMessage.message ?? "")

                    // Set title and message based on accountName availability
                    if let accountName = unreadMessage.accountName, !accountName.isEmpty {
                        content.title = accountName
                        content.body = abstractedMessage
                    } else {
                        content.title = abstractedMessage
                    }

                    content.sound = .default
                    content.userInfo = [
                        "conversationId": conversationId,
                        "accountId": unreadMessage.accountId ?? 0,
                        "accountName": unreadMessage.accountName ?? "",
                        "userId": unreadMessage.userId ?? 0,
                        "timestamp": unreadMessage.timestamp,
                        "message": unreadMessage.message ?? ""
                    ]
                    let request = UNNotificationRequest(
                        identifier: "customerly_new_message_\(conversationId)_\(unreadMessage.timestamp)",
                        content: content,
                        trigger: nil // deliver immediately
                    )
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                }

                callbacks.onNewMessageReceived?(unreadMessage)

            case "onNewConversationReceived":
                guard let data = messageData,
                      let conversationId = data["conversationId"] as? Int else { return }
                callbacks.onNewConversationReceived?(conversationId)

            case "onProfilingQuestionAnswered":
                guard let data = messageData,
                      let attribute = data["attribute"] as? String,
                      let value = data["value"] as? String else { return }
                callbacks.onProfilingQuestionAnswered?(attribute, value)

            case "onProfilingQuestionAsked":
                guard let data = messageData,
                      let attribute = data["attribute"] as? String else { return }
                callbacks.onProfilingQuestionAsked?(attribute)

            case "onRealtimeVideoAnswered":
                guard let data = messageData,
                      let call = try? RealtimeCall(from: data) else { return }
                callbacks.onRealtimeVideoAnswered?(call)

            case "onRealtimeVideoCanceled":
                callbacks.onRealtimeVideoCanceled?()

            case "onRealtimeVideoReceived":
                guard let data = messageData,
                      let call = try? RealtimeCall(from: data) else { return }
                show()
                callbacks.onRealtimeVideoReceived?(call)

            case "onRealtimeVideoRejected":
                callbacks.onRealtimeVideoRejected?()

            case "onSurveyAnswered":
                callbacks.onSurveyAnswered?()

            case "onSurveyPresented":
                guard let data = messageData,
                      let survey = try? Survey(from: data) else { return }
                show(withoutNavigation: true)
                callbacks.onSurveyPresented?(survey)

            case "onSurveyRejected":
                callbacks.onSurveyRejected?()

            default:
                Customerly.log("Unhandled message type: \(type)")
            }
        } catch {
            Customerly.log("Error processing message: \(messageBody) - \(error)")
        }
    }
}

extension Customerly: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Customerly.log("WebView finished loading")
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Customerly.log("WebView error: \(error)")
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Customerly.log("WebView provisional navigation failed: \(error)")
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let request = navigationAction.request
        if let url = request.url {
            if url.absoluteString == "https://customerly.io/" || request.mainDocumentURL?.absoluteString == "https://customerly.io/" {
                decisionHandler(.allow)
                return
            }

            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}

extension Customerly: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.afterHide(withBack: true)
    }
}
