import Foundation

/// Type-safe container for the messenger event callbacks.
///
/// Each property holds the closure registered through the corresponding `Customerly.setOn*`
/// method. Storing the closures with their real signatures lets the compiler enforce types,
/// unlike an `Any`-erased approach where a mismatched closure would silently no-op.
struct CustomerlyCallbacks {
    var onChatClosed: (() -> Void)?
    var onChatOpened: (() -> Void)?
    var onHelpCenterArticleOpened: ((HelpCenterArticle) -> Void)?
    var onLeadGenerated: ((String?) -> Void)?
    var onMessageRead: ((Int, Int) -> Void)?
    var onMessengerInitialized: (() -> Void)?
    var onNewConversation: ((String, [AttachmentPayload]) -> Void)?
    var onNewMessageReceived: ((UnreadMessage) -> Void)?
    var onNewConversationReceived: ((Int) -> Void)?
    var onProfilingQuestionAnswered: ((String, String) -> Void)?
    var onProfilingQuestionAsked: ((String) -> Void)?
    var onRealtimeVideoAnswered: ((RealtimeCall) -> Void)?
    var onRealtimeVideoCanceled: (() -> Void)?
    var onRealtimeVideoReceived: ((RealtimeCall) -> Void)?
    var onRealtimeVideoRejected: (() -> Void)?
    var onSurveyAnswered: (() -> Void)?
    var onSurveyPresented: ((Survey) -> Void)?
    var onSurveyRejected: (() -> Void)?
}
