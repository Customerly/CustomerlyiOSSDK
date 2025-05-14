import Foundation

/// Protocol for handling Customerly SDK events
public protocol CustomerlyCallback {
    /// Called when the messenger is initialized
    func onMessengerInitialized()
    
    /// Called when the chat is closed
    func onChatClosed()
    
    /// Called when the chat is opened
    func onChatOpened()
    
    /// Called when a help center article is opened
    func onHelpCenterArticleOpened(article: HelpCenterArticle)
    
    /// Called when a lead is generated
    func onLeadGenerated(email: String?)
    
    /// Called when a new message is received
    func onNewMessageReceived(accountId: Int, message: String, timestamp: TimeInterval, userId: Int, conversationId: Int)
    
    /// Called when a new conversation is created
    func onNewConversation(message: String, attachments: [AttachmentPayload])
    
    /// Called when a new conversation is received
    func onNewConversationReceived(conversationId: Int)
    
    /// Called when a profiling question is answered
    func onProfilingQuestionAnswered(attribute: String, value: String)
    
    /// Called when a profiling question is asked
    func onProfilingQuestionAsked(attribute: String)
    
    /// Called when a realtime video call is answered
    func onRealtimeVideoAnswered(call: RealtimeCall)
    
    /// Called when a realtime video call is canceled
    func onRealtimeVideoCanceled()
    
    /// Called when a realtime video call is received
    func onRealtimeVideoReceived(call: RealtimeCall)
    
    /// Called when a realtime video call is rejected
    func onRealtimeVideoRejected()
    
    /// Called when a survey is answered
    func onSurveyAnswered()
    
    /// Called when a survey is presented
    func onSurveyPresented(survey: Survey)
    
    /// Called when a survey is rejected
    func onSurveyRejected()
}

// Default implementations to make all methods optional
public extension CustomerlyCallback {
    func onMessengerInitialized() {}
    func onChatClosed() {}
    func onChatOpened() {}
    func onHelpCenterArticleOpened(article: HelpCenterArticle) {}
    func onLeadGenerated(email: String?) {}
    func onNewMessageReceived(accountId: Int, message: String, timestamp: TimeInterval, userId: Int, conversationId: Int) {}
    func onNewConversation(message: String, attachments: [AttachmentPayload]) {}
    func onNewConversationReceived(conversationId: Int) {}
    func onProfilingQuestionAnswered(attribute: String, value: String) {}
    func onProfilingQuestionAsked(attribute: String) {}
    func onRealtimeVideoAnswered(call: RealtimeCall) {}
    func onRealtimeVideoCanceled() {}
    func onRealtimeVideoReceived(call: RealtimeCall) {}
    func onRealtimeVideoRejected() {}
    func onSurveyAnswered() {}
    func onSurveyPresented(survey: Survey) {}
    func onSurveyRejected() {}
}

/// Generic callback wrapper that implements CustomerlyCallback
public class CallbackWrapper: CustomerlyCallback {
    private let callback: Any

    public init<T>(_ callback: T) {
        self.callback = callback
    }

    public func onMessengerInitialized() { (callback as? () -> Void)?() }
    public func onChatClosed() { (callback as? () -> Void)?() }
    public func onChatOpened() { (callback as? () -> Void)?() }
    public func onHelpCenterArticleOpened(article: HelpCenterArticle) { (callback as? (HelpCenterArticle) -> Void)?(article) }
    public func onLeadGenerated(email: String?) { (callback as? (String?) -> Void)?(email) }
    public func onNewConversation(message: String, attachments: [AttachmentPayload]) { (callback as? (String, [AttachmentPayload]) -> Void)?(message, attachments) }
    public func onNewMessageReceived(accountId: Int, message: String, timestamp: TimeInterval, userId: Int, conversationId: Int) {
        (callback as? (Int, String, TimeInterval, Int, Int) -> Void)?(accountId, message, timestamp, userId, conversationId)
    }
    public func onNewConversationReceived(conversationId: Int) { (callback as? (Int) -> Void)?(conversationId) }
    public func onProfilingQuestionAnswered(attribute: String, value: String) { (callback as? (String, String) -> Void)?(attribute, value) }
    public func onProfilingQuestionAsked(attribute: String) { (callback as? (String) -> Void)?(attribute) }
    public func onRealtimeVideoAnswered(call: RealtimeCall) { (callback as? (RealtimeCall) -> Void)?(call) }
    public func onRealtimeVideoCanceled() { (callback as? () -> Void)?() }
    public func onRealtimeVideoReceived(call: RealtimeCall) { (callback as? (RealtimeCall) -> Void)?(call) }
    public func onRealtimeVideoRejected() { (callback as? () -> Void)?() }
    public func onSurveyAnswered() { (callback as? () -> Void)?() }
    public func onSurveyPresented(survey: Survey) { (callback as? (Survey) -> Void)?(survey) }
    public func onSurveyRejected() { (callback as? () -> Void)?() }
}
