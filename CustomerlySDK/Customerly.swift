import UIKit
import WebKit
import UserNotifications

/// Main entry point for the Customerly SDK
public class Customerly: NSObject {
    /// Shared singleton instance
    public static let shared = Customerly()

    /// Preloaded WKWebView instance
    private var webView: WKWebView?

    /// Container view controller presenting the messenger
    private var controller: UIViewController?

    /// Settings for the SDK
    private var settings: CustomerlySettings?

    /// Callback handler for various events
    private var callback: CustomerlyCallback?

    /// Dictionary to store callbacks by type
    private var callbacks: [String: CustomerlyCallback] = [:]

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
    }

    @objc private func applicationWillTerminate() {
        saveCookies()
    }

    /// Loads and initializes the SDK with the provided settings
    /// - Parameter settings: Configuration settings for the SDK
    public func load(settings: CustomerlySettings) {
        guard webView == nil else {
            return
        }

        self.settings = settings

        // Configure WKWebView with message handler
        let config = WKWebViewConfiguration()
        let userContent = config.userContentController
        userContent.add(self, name: "customerlyNative")

        // Initialize and load the messenger
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = self
        wv.isHidden = true
        wv.backgroundColor = .white
        wv.isOpaque = false
        wv.scrollView.isScrollEnabled = false
        wv.scrollView.bounces = false

        // Keep reference
        self.webView = wv

        // Load saved cookies
        loadCookies()

        // Load the messenger HTML
        loadMessengerHTML()
    }

    /// Sets the callback handler for SDK events
    /// - Parameter callback: The callback handler to receive events
    public func setCallback(_ callback: CustomerlyCallback) {
        self.callback = callback
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
        guard let webView = webView else { return }
        
        let dataStore = WKWebsiteDataStore.default()
        let cookieStore = dataStore.httpCookieStore
        
        cookieStore.getAllCookies { cookies in
            for cookie in cookies {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
    }

    private func loadCookies() {
        guard let webView = webView else { return }
        
        let dataStore = WKWebsiteDataStore.default()
        let cookieStore = dataStore.httpCookieStore
        
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                cookieStore.setCookie(cookie)
            }
        }
    }

    private func evaluateJavascript(_ script: String, safe: Bool = false, resultCallback: ((Any?, Error?) -> Void)? = nil) {
        guard let webView = webView else {
            print("Customerly: Error - WebView not loaded")
            return
        }

        if safe {
            DispatchQueue.main.async {
                webView.evaluateJavaScript(script) { result, error in
                    resultCallback?(result, error)
                }
            }
        } else {
            webView.evaluateJavaScript(script) { result, error in
                resultCallback?(result, error)
            }
        }
    }

    /// Presents the messenger by showing the preloaded WebView
    /// - Parameters:
    ///   - parent: The view controller from which to present the messenger modally
    ///   - withoutNavigation: Whether to show without navigation controls
    ///   - safe: Whether to show in a safe way (handling edge cases)
    public func show(on parent: UIViewController, withoutNavigation: Bool = false, safe: Bool = false) {
        guard let wv = webView else {
            print("Customerly: Error - WebView not loaded")
            assertionFailure("Messenger not loaded. Call load() first.")
            return
        }

        // Create a container view controller
        let containerVC = UIViewController()
        containerVC.view.backgroundColor = .white

        // Create a container view for the WebView
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerVC.view.addSubview(containerView)

        // Add constraints to make the container view fill the screen
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: containerVC.view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: containerVC.view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: containerVC.view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: containerVC.view.bottomAnchor)
        ])

        // Add the WebView to the container view
        wv.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(wv)

        // Add constraints to make the WebView fill the container view
        NSLayoutConstraint.activate([
            wv.topAnchor.constraint(equalTo: containerView.topAnchor),
            wv.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            wv.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            wv.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        // Show the WebView
        wv.isHidden = false

        // Present the container view controller
        parent.present(containerVC, animated: true) {
            self.controller = containerVC
            
            // Evaluate JavaScript to open the messenger
            self.evaluateJavascript("customerly.open()", safe: safe)
            
            // Navigate to root if navigation is enabled
            if !withoutNavigation {
                self.evaluateJavascript("_customerly_sdk.navigate('/', true)", safe: safe)
            }
        }
    }

    /// Hides the messenger
    public func hide() {
        controller?.dismiss(animated: true) {
            self.controller = nil
            self.webView?.isHidden = true
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
    /// - Parameters:
    ///   - parent: The view controller from which to present the messenger
    ///   - message: The message to show
    public func showNewMessage(on parent: UIViewController, message: String) {
        show(on: parent)
        evaluateJavascript("customerly.showNewMessage('\(message)')")
    }

    /// Sends a new message
    /// - Parameters:
    ///   - parent: The view controller from which to present the messenger
    ///   - message: The message to send
    public func sendNewMessage(on parent: UIViewController, message: String) {
        show(on: parent)
        evaluateJavascript("customerly.sendNewMessage('\(message)')")
    }

    /// Shows a specific article
    /// - Parameters:
    ///   - parent: The view controller from which to present the messenger
    ///   - collectionSlug: The collection slug
    ///   - articleSlug: The article slug
    public func showArticle(on parent: UIViewController, collectionSlug: String, articleSlug: String) {
        show(on: parent)
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

    /// Removes a callback for a specific event type
    /// - Parameter type: The type of event to remove the callback for
    private func removeCallback(type: String) {
        guard webView != nil else {
            print("Customerly: Error - WebView not loaded")
            return
        }
        
        callbacks.removeValue(forKey: type)
    }

    /// Removes all registered callbacks
    public func removeAllCallbacks() {
        guard webView != nil else {
            print("Customerly: Error - WebView not loaded")
            return
        }
        
        callbacks.removeAll()
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
    public func setOnNewMessageReceived(_ callback: @escaping (Int, String, TimeInterval, Int, Int) -> Void) {
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
}

extension Customerly: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController,
                                    didReceive message: WKScriptMessage) {
        guard message.name == "customerlyNative",
              let message = message.body as? String else { return }

        guard let data = message.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return
        }

        // TODO: Handle messages like JSBridge on Android
        if let callback = callbacks[type] {
            switch type {
            case "onMessengerInitialized":
                callback.onMessengerInitialized()
            case "onChatClosed":
                callback.onChatClosed()
                hide()
            case "onChatOpened":
                callback.onChatOpened()
            case "onNewMessageReceived":
                    guard let data = json["data"] as? [String: Any],
                          let accountId = data["account_id"] as? Int,
                          let message = data["message"] as? String,
                          let timestamp = data["timestamp"] as? TimeInterval,
                          let userId = data["user_id"] as? Int,
                          let conversationId = data["conversation_id"] as? Int else {
                        return
                    }

                    callback.onNewMessageReceived(accountId: accountId,
                                                message: message,
                                                timestamp: timestamp,
                                                userId: userId,
                                                conversationId: conversationId)
            case "onNewConversation":
                guard let data = json["data"] as? [String: Any],
                      let message = data["message"] as? String,
                      let attachments = data["attachments"] as? [[String: Any]] else {
                    return
                }

                let attachmentPayloads = attachments.compactMap { dict -> AttachmentPayload? in
                    guard let name = dict["name"] as? String,
                          let size = dict["size"] as? Int64,
                          let base64 = dict["base64"] as? String else {
                        return nil
                    }
                    return AttachmentPayload(name: name, size: size, base64: base64)
                }

                callback.onNewConversation(message: message, attachments: attachmentPayloads)
            case "onSurveyPresented":
                guard let data = json["data"] as? [String: Any],
                      let surveyId = data["survey_id"] as? Int64,
                      let creator = data["creator"] as? [String: Any],
                      let creatorId = creator["account_id"] as? Int64,
                      let creatorName = creator["name"] as? String,
                      let isAI = creator["is_ai"] as? Bool else {
                    return
                }

                let account = Account(account_id: creatorId, name: creatorName, is_ai: isAI)
                let survey = Survey(survey_id: surveyId,
                                  creator: account,
                                  thank_you_text: data["thank_you_text"] as? String,
                                  seen_at: data["seen_at"] as? TimeInterval,
                                  question: nil) // TODO: Implement question parsing

                callback.onSurveyPresented(survey: survey)
            default:
                print("Customerly: Unhandled message type: \(type)")
            }
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
}
