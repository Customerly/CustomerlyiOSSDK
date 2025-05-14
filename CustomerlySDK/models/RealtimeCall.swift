import Foundation

public struct RealtimeCall {
    public let account: Account
    public let url: String
    public let conversation_id: Int64
    public let user: RealtimeCallUser
    
    public init(account: Account, url: String, conversation_id: Int64, user: RealtimeCallUser) {
        self.account = account
        self.url = url
        self.conversation_id = conversation_id
        self.user = user
    }
    
    public init(from dict: [String: Any]) throws {
        guard let account = dict["account"] as? [String: Any],
              let url = dict["url"] as? String,
              let conversationId = dict["conversation_id"] as? Int64,
              let user = dict["user"] as? [String: Any] else {
            throw NSError(domain: "Customerly", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid RealtimeCall data"])
        }
        
        self.account = try Account(from: account)
        self.url = url
        self.conversation_id = conversationId
        self.user = try RealtimeCallUser(from: user)
    }
    
    var dictionary: [String: Any] {
        return [
            "account": account.dictionary,
            "url": url,
            "conversation_id": conversation_id,
            "user": user.dictionary
        ]
    }
}

public struct RealtimeCallUser {
    public let user_id: Int64
    
    public init(user_id: Int64) {
        self.user_id = user_id
    }
    
    public init(from dict: [String: Any]) throws {
        guard let userId = dict["user_id"] as? Int64 else {
            throw NSError(domain: "Customerly", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid RealtimeCallUser data"])
        }
        
        self.user_id = userId
    }
    
    var dictionary: [String: Any] {
        return ["user_id": user_id]
    }
}
