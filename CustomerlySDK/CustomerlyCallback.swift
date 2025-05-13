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

/// Model for help center articles
public struct HelpCenterArticle {
    /// The article ID
    public let knowledge_base_article_id: Int64
    
    /// The collection ID
    public let knowledge_base_collection_id: Int64
    
    /// The app ID
    public let app_id: String
    
    /// The article slug
    public let slug: String
    
    /// The article title
    public let title: String
    
    /// The article description
    public let description: String
    
    /// The article body
    public let body: String
    
    /// The article sort order
    public let sort: Int
    
    /// The article author
    public let written_by: WrittenBy
    
    /// The last update timestamp
    public let updated_at: TimeInterval
}

/// Model for article authors
public struct WrittenBy {
    /// The author's account ID
    public let account_id: Int64
    
    /// The author's email
    public let email: String?
    
    /// The author's name
    public let name: String
}

/// Model for attachment payloads
public struct AttachmentPayload {
    /// The attachment name
    public let name: String
    
    /// The attachment size in bytes
    public let size: Int64
    
    /// The attachment content as base64 string
    public let base64: String
}

/// Model for realtime video calls
public struct RealtimeCall {
    /// The call ID
    public let call_id: String
    
    /// The caller's account ID
    public let caller_account_id: Int64
    
    /// The caller's name
    public let caller_name: String
    
    /// The caller's email
    public let caller_email: String?
    
    /// The call type
    public let call_type: String
    
    /// The call status
    public let status: String
    
    /// The call start time
    public let start_time: TimeInterval?
    
    /// The call end time
    public let end_time: TimeInterval?
}

/// Model for surveys
public struct Survey {
    /// The survey ID
    public let survey_id: Int64
    
    /// The survey creator
    public let creator: Account
    
    /// The thank you text shown after completing the survey
    public let thank_you_text: String?
    
    /// When the survey was seen
    public let seen_at: TimeInterval?
    
    /// The survey question
    public let question: SurveyQuestion?
}

/// Model for survey questions
public struct SurveyQuestion {
    /// The survey ID
    public let survey_id: Int64
    
    /// The question ID
    public let survey_question_id: Int64
    
    /// The question step number
    public let step: Int
    
    /// The question text
    public let text: String
    
    /// The question type
    public let type: String
    
    /// The question options
    public let options: [String]?
}

/// Model for accounts
public struct Account {
    /// The account ID
    public let account_id: Int64
    
    /// The account name
    public let name: String?
    
    /// Whether the account is an AI
    public let is_ai: Bool
} 