import Foundation

public struct Account {
    public let account_id: Int64
    public let name: String?
    public let is_ai: Bool?
    
    public init(account_id: Int64, name: String? = nil, is_ai: Bool? = nil) {
        self.account_id = account_id
        self.name = name
        self.is_ai = is_ai
    }
    
    public init(from dict: [String: Any]) throws {
        guard let accountId = dict["account_id"] as? Int64 else {
            throw NSError(domain: "Customerly", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Account data"])
        }
        
        self.account_id = accountId
        self.name = dict["name"] as? String
        self.is_ai = dict["is_ai"] as? Bool
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "account_id": account_id
        ]
        
        if let name = name {
            dict["name"] = name
        }
        if let isAI = is_ai {
            dict["is_ai"] = isAI
        }
        
        return dict
    }
}
