import Foundation

public protocol CustomerlyCallback {
    func onChatClosed()
    func onChatOpened()
    func onHelpCenterArticleOpened(article: HelpCenterArticle)
    func onLeadGenerated(email: String?)
    func onMessageRead(conversationId: Int, conversationMessageId: Int)
    func onMessengerInitialized()
    func onNewMessageReceived(unreadMessage: UnreadMessage)
    func onNewConversation(message: String, attachments: [AttachmentPayload])
    func onNewConversationReceived(conversationId: Int)
    func onProfilingQuestionAnswered(attribute: String, value: String)
    func onProfilingQuestionAsked(attribute: String)
    func onRealtimeVideoAnswered(call: RealtimeCall)
    func onRealtimeVideoCanceled()
    func onRealtimeVideoReceived(call: RealtimeCall)
    func onRealtimeVideoRejected()
    func onSurveyAnswered()
    func onSurveyPresented(survey: Survey)
    func onSurveyRejected()
}

public extension CustomerlyCallback {
    func onChatClosed() {}
    func onChatOpened() {}
    func onHelpCenterArticleOpened(article: HelpCenterArticle) {}
    func onLeadGenerated(email: String?) {}
    func onMessageRead(conversationId: Int, conversationMessageId: Int) {}
    func onMessengerInitialized() {}
    func onNewMessageReceived(unreadMessage: UnreadMessage) {}
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

public class CallbackWrapper: CustomerlyCallback {
    private let callback: Any

    public init<T>(_ callback: T) {
        self.callback = callback
    }

    public func onChatClosed() { (callback as? () -> Void)?() }
    public func onChatOpened() { (callback as? () -> Void)?() }
    public func onHelpCenterArticleOpened(article: HelpCenterArticle) { (callback as? (HelpCenterArticle) -> Void)?(article) }
    public func onLeadGenerated(email: String?) { (callback as? (String?) -> Void)?(email) }
    public func onMessageRead(conversationId: Int, conversationMessageId: Int) { (callback as? (Int, Int) -> Void)?(conversationId, conversationMessageId) }
    public func onMessengerInitialized() { (callback as? () -> Void)?() }
    public func onNewConversation(message: String, attachments: [AttachmentPayload]) { (callback as? (String, [AttachmentPayload]) -> Void)?(message, attachments) }
    public func onNewMessageReceived(unreadMessage: UnreadMessage) {
        (callback as? (UnreadMessage) -> Void)?(unreadMessage)
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
