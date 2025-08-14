import Foundation

public struct UnreadMessage {
    public let accountId: Int64?
    public let accountName: String?
    public let message: String?
    public let timestamp: Int64
    public let userId: Int64?
    public let conversationId: Int64
    
    public init(accountId: Int64? = nil, accountName: String? = nil, message: String? = nil, timestamp: Int64, userId: Int64? = nil, conversationId: Int64) {
        self.accountId = accountId
        self.accountName = accountName
        self.message = message
        self.timestamp = timestamp
        self.userId = userId
        self.conversationId = conversationId
    }
    
    public init(from dict: [String: Any]) throws {
        guard let timestamp = dict["timestamp"] as? Int64,
              let conversationId = dict["conversationId"] as? Int64 else {
            throw NSError(domain: "Customerly", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid UnreadMessage data"])
        }
        
        self.accountId = dict["accountId"] as? Int64
        self.accountName = dict["accountName"] as? String
        self.message = dict["message"] as? String
        self.timestamp = timestamp
        self.userId = dict["userId"] as? Int64
        self.conversationId = conversationId
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "timestamp": timestamp,
            "conversationId": conversationId
        ]
        
        if let accountId = accountId {
            dict["accountId"] = accountId
        }
        if let accountName = accountName {
            dict["accountName"] = accountName
        }
        if let message = message {
            dict["message"] = message
        }
        if let userId = userId {
            dict["userId"] = userId
        }
        
        return dict
    }
}
