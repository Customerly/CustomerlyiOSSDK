import UIKit
@preconcurrency import WebKit
import UserNotifications

public class Customerly: NSObject {
    /// Shared singleton instance
    public static let shared = Customerly()

    private var webView: WKWebView?
    // Container view controller presenting the messenger
    private var controller: UIViewController?
    // Parent view controller for presenting the messenger
    private weak var parentViewController: UIViewController?
    private var settings: CustomerlySettings?
    private var callbacks: [String: CustomerlyCallback] = [:]
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
        wv.backgroundColor = .white
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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Customerly: Failed to request notification permission: \(error)")
            }
        }
    }

    private func loadMessengerHTML() {
        guard let settings = settings else {
            print("Customerly: Error - Settings not available")
            return
        }

        let settingsJson = try? JSONSerialization.data(withJSONObject: settings.dictionary)
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
            print("Customerly: Error - WebView not loaded")
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
            print("Customerly: Error - WebView not loaded")
            assertionFailure("Messenger not loaded. Call load() first.")
            return
        }
        
        guard let parent = parentViewController else {
            print("Customerly: Error - No parent view controller set")
            assertionFailure("No parent view controller set. Call load() or setParent() first.")
            return
        }

        if self.controller != nil || self.isPresenting {
            print("Customerly: Messenger is already presented or being presented.")
            return
        }

        self.isPresenting = true

        let containerVC = UIViewController()
        containerVC.view.backgroundColor = .white

        let containerView = UIView()
        containerView.backgroundColor = .white
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
        evaluateJavascript("customerly.event('\(name)')")
    }

    /// Sets a user attribute
    /// - Parameters:
    ///   - name: The name of the attribute
    ///   - value: The value of the attribute
    public func attribute(name: String, value: Any) {
        let valueJson: String
        switch value {
        case let stringValue as String:
            valueJson = "'\(stringValue)'"
        case let numberValue as NSNumber:
            valueJson = numberValue.stringValue
        default:
            let json = ["value": value]
            if let jsonData = try? JSONSerialization.data(withJSONObject: json),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                valueJson = jsonString
            } else {
                valueJson = "null"
            }
        }
        
        evaluateJavascript("customerly.attribute('\(name)', \(valueJson))")
    }

    /// Updates the SDK settings
    /// - Parameter settings: The new settings to apply
    public func update(settings: CustomerlySettings) {
        if let settingsJson = try? JSONSerialization.data(withJSONObject: settings.dictionary),
           let settingsString = String(data: settingsJson, encoding: .utf8) {
            evaluateJavascript("customerly.update(\(settingsString))")
        }
    }

    /// Shows the messenger with a new message
    /// - Parameter message: The new message to prepopulate in the messenger
    public func showNewMessage(message: String) {
        show()
        evaluateJavascript("customerly.showNewMessage('\(message)')")
    }

    /// Sends a new message
    /// - Parameter message: The new message to send
    public func sendNewMessage(message: String) {
        show()
        evaluateJavascript("customerly.sendNewMessage('\(message)')")
    }

    /// Shows a specific article
    /// - Parameters:
    ///   - collectionSlug: The collection slug
    ///   - articleSlug: The article slug
    public func showArticle(collectionSlug: String, articleSlug: String) {
        show()
        evaluateJavascript("customerly.showArticle('\(collectionSlug)', '\(articleSlug)')")
    }

    /// Registers a new lead
    /// - Parameters:
    ///   - email: The email of the lead
    ///   - attributes: Optional attributes for the lead
    public func registerLead(email: String, attributes: [String: String]? = nil) {
        let attributesJson: String
        if let attributes = attributes,
           let jsonData = try? JSONSerialization.data(withJSONObject: attributes),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            attributesJson = jsonString
        } else {
            attributesJson = "null"
        }
        
        evaluateJavascript("customerly.registerLead('\(email)', \(attributesJson))")
    }

    /// Navigates back in the messenger
    public func back() {
        evaluateJavascript("_customerly_sdk.back()")
    }

    /// Navigates to a specific conversation
    /// - Parameter conversationId: The ID of the conversation to navigate to
    public func navigateToConversation(conversationId: Int) {
        evaluateJavascript("_customerly_sdk.navigateToConversation(\(conversationId))")
    }

    /// Gets the count of unread messages
    /// - Parameter completion: Callback with the count of unread messages
    public func getUnreadMessagesCount(completion: @escaping (Int) -> Void) {
        evaluateJavascript("customerly.unreadMessagesCount") { result, error in
            if let count = result as? Int {
                completion(count)
            } else {
                completion(0)
            }
        }
    }

    /// Gets the count of unread conversations
    /// - Parameter completion: Callback with the count of unread conversations
    public func getUnreadConversationsCount(completion: @escaping (Int) -> Void) {
        evaluateJavascript("customerly.unreadConversationsCount") { result, error in
            if let count = result as? Int {
                completion(count)
            } else {
                completion(0)
            }
        }
    }

    /// Registers a callback for a specific event type
    /// - Parameters:
    ///   - type: The type of event to register for
    ///   - callback: The callback to handle the event
    private func registerCallback(type: String, callback: CustomerlyCallback) {
        guard webView != nil else {
            print("Customerly: Error - WebView not loaded")
            return
        }
        
        callbacks[type] = callback
    }

    /// Sets a callback for when the chat is closed
    /// - Parameter callback: The callback to handle the event
    public func setOnChatClosed(_ callback: @escaping () -> Void) {
        registerCallback(type: "onChatClosed", callback: CallbackWrapper(callback))
    }

    /// Sets a callback for when the chat is opened
    /// - Parameter callback: The callback to handle the event
    public func setOnChatOpened(_ callback: @escaping () -> Void) {
        registerCallback(type: "onChatOpened", callback: CallbackWrapper(callback))
    }

    /// Sets a callback for when a help center article is opened
    /// - Parameter callback: The callback to handle the event
    public func setOnHelpCenterArticleOpened(_ callback: @escaping (HelpCenterArticle) -> Void) {
        registerCallback(type: "onHelpCenterArticleOpened", callback: CallbackWrapper(callback))
    }

    /// Sets a callback for when a lead is generated
    /// - Parameter callback: The callback to handle the event
    public func setOnLeadGenerated(_ callback: @escaping (String?) -> Void) {
        registerCallback(type: "onLeadGenerated", callback: CallbackWrapper(callback))
    }

    /// Sets a callback for when a message is read
    /// - Parameter callback: The callback to handle the event
    public func setOnMessageRead(_ callback: @escaping (Int, Int) -> Void) {
        registerCallback(type: "onMessageRead", callback: CallbackWrapper(callback))
    }

    /// Sets a callback for when the messenger is initialized
    /// - Parameter callback: The callback to handle the event
    public func setOnMessengerInitialized(_ callback: @escaping () -> Void) {
        registerCallback(type: "onMessengerInitialized", callback: CallbackWrapper(callback))
    }

    /// Sets a callback for when a new conversation is created
    /// - Parameter callback: The callback to handle the event
    public func setOnNewConversation(_ callback: @escaping (String, [AttachmentPayload]) -> Void) {
        registerCallback(type: "onNewConversation", callback: CallbackWrapper(callback))
    }

    /// Sets a callback for when a new message is received
    /// - Parameter callback: The callback to handle the event
    public func setOnNewMessageReceived(_ callback: @escaping (UnreadMessage) -> Void) {
        registerCallback(type: "onNewMessageReceived", callback: CallbackWrapper(callback))
    }

    /// Sets a callback for when a new conversation is received
    /// - Parameter callback: The callback to handle the event
    public func setOnNewConversationReceived(_ callback: @escaping (Int) -> Void) {
        registerCallback(type: "onNewConversationReceived", callback: CallbackWrapper(callback))
    }

    /// Sets a callback for when a profiling question is answered
    /// - Parameter callback: The callback to handle the event
    public func setOnProfilingQuestionAnswered(_ callback: @escaping (String, String) -> Void) {
        registerCallback(type: "onProfilingQuestionAnswered", callback: CallbackWrapper(callback))
    }

    /// Sets a callback for when a profiling question is asked
    /// - Parameter callback: The callback to handle the event
    public func setOnProfilingQuestionAsked(_ callback: @escaping (String) -> Void) {
        registerCallback(type: "onProfilingQuestionAsked", callback: CallbackWrapper(callback))
    }

    /// Sets a callback for when a realtime video call is answered
    /// - Parameter callback: The callback to handle the event
    public func setOnRealtimeVideoAnswered(_ callback: @escaping (RealtimeCall) -> Void) {
        registerCallback(type: "onRealtimeVideoAnswered", callback: CallbackWrapper(callback))
    }

    /// Sets a callback for when a realtime video call is canceled
    /// - Parameter callback: The callback to handle the event
    public func setOnRealtimeVideoCanceled(_ callback: @escaping () -> Void) {
        registerCallback(type: "onRealtimeVideoCanceled", callback: CallbackWrapper(callback))
    }

    /// Sets a callback for when a realtime video call is received
    /// - Parameter callback: The callback to handle the event
    public func setOnRealtimeVideoReceived(_ callback: @escaping (RealtimeCall) -> Void) {
        registerCallback(type: "onRealtimeVideoReceived", callback: CallbackWrapper(callback))
    }

    /// Sets a callback for when a realtime video call is rejected
    /// - Parameter callback: The callback to handle the event
    public func setOnRealtimeVideoRejected(_ callback: @escaping () -> Void) {
        registerCallback(type: "onRealtimeVideoRejected", callback: CallbackWrapper(callback))
    }

    /// Sets a callback for when a survey is answered
    /// - Parameter callback: The callback to handle the event
    public func setOnSurveyAnswered(_ callback: @escaping () -> Void) {
        registerCallback(type: "onSurveyAnswered", callback: CallbackWrapper(callback))
    }

    /// Sets a callback for when a survey is presented
    /// - Parameter callback: The callback to handle the event
    public func setOnSurveyPresented(_ callback: @escaping (Survey) -> Void) {
        registerCallback(type: "onSurveyPresented", callback: CallbackWrapper(callback))
    }

    /// Sets a callback for when a survey is rejected
    /// - Parameter callback: The callback to handle the event
    public func setOnSurveyRejected(_ callback: @escaping () -> Void) {
        registerCallback(type: "onSurveyRejected", callback: CallbackWrapper(callback))
    }

    /// Removes a callback for a specific event type
    /// - Parameter type: The type of event to remove the callback for
    private func removeCallback(type: String) {
        guard webView != nil else {
            print("Customerly: Error - WebView not loaded")
            return
        }
        
        callbacks.removeValue(forKey: type)
    }

    /// Removes the callback for when the chat is closed
    public func removeOnChatClosed() {
        removeCallback(type: "onChatClosed")
    }

    /// Removes the callback for when the chat is opened
    public func removeOnChatOpened() {
        removeCallback(type: "onChatOpened")
    }

    /// Removes the callback for when a help center article is opened
    public func removeOnHelpCenterArticleOpened() {
        removeCallback(type: "onHelpCenterArticleOpened")
    }

    /// Removes the callback for when a lead is generated
    public func removeOnLeadGenerated() {
        removeCallback(type: "onLeadGenerated")
    }

    /// Removes the callback for when a message is read
    public func removeOnMessageRead() {
        removeCallback(type: "onMessageRead")
    }

    /// Removes the callback for when a new conversation is created
    public func removeOnNewConversation() {
        removeCallback(type: "onNewConversation")
    }

    /// Removes the callback for when a new message is received
    public func removeOnNewMessageReceived() {
        removeCallback(type: "onNewMessageReceived")
    }

    /// Removes the callback for when a new conversation is received
    public func removeOnNewConversationReceived() {
        removeCallback(type: "onNewConversationReceived")
    }

    /// Removes the callback for when a profiling question is answered
    public func removeOnProfilingQuestionAnswered() {
        removeCallback(type: "onProfilingQuestionAnswered")
    }

    /// Removes the callback for when a profiling question is asked
    public func removeOnProfilingQuestionAsked() {
        removeCallback(type: "onProfilingQuestionAsked")
    }

    /// Removes the callback for when a realtime video call is answered
    public func removeOnRealtimeVideoAnswered() {
        removeCallback(type: "onRealtimeVideoAnswered")
    }

    /// Removes the callback for when a realtime video call is canceled
    public func removeOnRealtimeVideoCanceled() {
        removeCallback(type: "onRealtimeVideoCanceled")
    }

    /// Removes the callback for when a realtime video call is received
    public func removeOnRealtimeVideoReceived() {
        removeCallback(type: "onRealtimeVideoReceived")
    }

    /// Removes the callback for when a realtime video call is rejected
    public func removeOnRealtimeVideoRejected() {
        removeCallback(type: "onRealtimeVideoRejected")
    }

    /// Removes the callback for when a survey is answered
    public func removeOnSurveyAnswered() {
        removeCallback(type: "onSurveyAnswered")
    }

    /// Removes the callback for when a survey is presented
    public func removeOnSurveyPresented() {
        removeCallback(type: "onSurveyPresented")
    }

    /// Removes the callback for when a survey is rejected
    public func removeOnSurveyRejected() {
        removeCallback(type: "onSurveyRejected")
    }

    /// Removes all registered callbacks
    public func removeAllCallbacks() {
        guard webView != nil else {
            print("Customerly: Error - WebView not loaded")
            return
        }
        
        callbacks.removeAll()
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
    public func userContentController(_ userContentController: WKUserContentController,
                                    didReceive message: WKScriptMessage) {
        guard message.name == "customerlyNative",
              let messageBody = message.body as? String else { return }

        do {
            guard let data = messageBody.data(using: .utf8),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = json["type"] as? String else {
                print("Customerly: Error - Invalid message format")
                return
            }

            let messageData = json["data"] as? [String: Any]

            switch type {
            case "onChatClosed":
                hide()
                callbacks[type]?.onChatClosed()
                
            case "onChatOpened":
                callbacks[type]?.onChatOpened()
                
            case "onHelpCenterArticleOpened":
                guard let data = messageData,
                      let article = try? HelpCenterArticle(from: data) else { return }
                callbacks[type]?.onHelpCenterArticleOpened(article: article)
                
            case "onLeadGenerated":
                let email = messageData?["email"] as? String
                callbacks[type]?.onLeadGenerated(email: email)
                
            case "onMessageRead":
                guard let data = messageData,
                      let conversationId = data["conversationId"] as? Int,
                      let conversationMessageId = data["conversationMessageId"] as? Int else { return }
                callbacks[type]?.onMessageRead(conversationId: conversationId, conversationMessageId: conversationMessageId)
                
            case "onMessengerInitialized":
                callbacks[type]?.onMessengerInitialized()
                
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
                
                callbacks[type]?.onNewConversation(message: message, attachments: attachments)
                
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

                // Show system local notification
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

                callbacks[type]?.onNewMessageReceived(unreadMessage: unreadMessage)
                
            case "onNewConversationReceived":
                guard let data = messageData,
                      let conversationId = data["conversationId"] as? Int else { return }
                callbacks[type]?.onNewConversationReceived(conversationId: conversationId)
                
            case "onProfilingQuestionAnswered":
                guard let data = messageData,
                      let attribute = data["attribute"] as? String,
                      let value = data["value"] as? String else { return }
                callbacks[type]?.onProfilingQuestionAnswered(attribute: attribute, value: value)
                
            case "onProfilingQuestionAsked":
                guard let data = messageData,
                      let attribute = data["attribute"] as? String else { return }
                callbacks[type]?.onProfilingQuestionAsked(attribute: attribute)
                
            case "onRealtimeVideoAnswered":
                guard let data = messageData,
                      let call = try? RealtimeCall(from: data) else { return }
                callbacks[type]?.onRealtimeVideoAnswered(call: call)
                
            case "onRealtimeVideoCanceled":
                callbacks[type]?.onRealtimeVideoCanceled()
                
            case "onRealtimeVideoReceived":
                show()
                guard let data = messageData,
                      let call = try? RealtimeCall(from: data) else { return }
                callbacks[type]?.onRealtimeVideoReceived(call: call)
                
            case "onRealtimeVideoRejected":
                callbacks[type]?.onRealtimeVideoRejected()
                
            case "onSurveyAnswered":
                callbacks[type]?.onSurveyAnswered()
                
            case "onSurveyPresented":
                show(withoutNavigation: true)
                guard let data = messageData,
                      let survey = try? Survey(from: data) else { return }
                callbacks[type]?.onSurveyPresented(survey: survey)
                
            case "onSurveyRejected":
                callbacks[type]?.onSurveyRejected()
                
            default:
                print("Customerly: Unhandled message type: \(type)")
            }
        } catch {
            print("Customerly: Error processing message: \(messageBody)", error)
        }
    }
}

extension Customerly: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Customerly: WebView finished loading")
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Customerly: WebView error: \(error)")
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Customerly: WebView provisional navigation failed: \(error)")
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
