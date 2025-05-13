import Foundation

/// Configuration settings for the Customerly SDK
public struct CustomerlySettings {
    /// The app ID for your Customerly account
    public let app_id: String
    
    /// Optional user ID for the current user
    public var user_id: String?
    
    /// Optional name of the current user
    public var name: String?
    
    /// Optional email of the current user
    public var email: String?
    
    /// Optional email hash of the current user
    public var email_hash: String?
    
    /// Optional accent color for the messenger UI
    public var accentColor: String?
    
    /// Optional contrast color for the messenger UI
    public var contrastColor: String?
    
    /// Whether attachments are available in the messenger
    public var attachmentsAvailable: Bool?
    
    /// Whether to force single conversation mode
    public var singleConversation: Bool?
    
    /// Optional last page viewed by the user
    public var last_page_viewed: String?
    
    /// Whether to force lead generation
    public var force_lead: Bool?
    
    /// Optional user attributes
    public var attributes: [String: Any]?
    
    /// Optional company information
    public var company: Company?
    
    /// Optional user events
    public var events: [Event]?
    
    public init(app_id: String) {
        self.app_id = app_id
    }
    
    /// Dictionary representation of the settings
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "app_id": app_id,
            "sdkMode": true
        ]
        
        user_id.map { dict["user_id"] = $0 }
        name.map { dict["name"] = $0 }
        email.map { dict["email"] = $0 }
        email_hash.map { dict["email_hash"] = $0 }
        accentColor.map { dict["accentColor"] = $0 }
        contrastColor.map { dict["contrastColor"] = $0 }
        attachmentsAvailable.map { dict["attachmentsAvailable"] = $0 }
        singleConversation.map { dict["singleConversation"] = $0 }
        last_page_viewed.map { dict["last_page_viewed"] = $0 }
        force_lead.map { dict["force_lead"] = $0 }
        attributes.map { dict["attributes"] = $0 }
        company.map { dict["company"] = $0.dictionary }
        events.map { dict["events"] = $0.map { $0.dictionary } }
        
        return dict
    }
}

/// Company information for the current user
public struct Company {
    /// The company ID
    public let company_id: String
    
    /// The company name
    public let name: String
    
    /// Additional company attributes
    public var additionalAttributes: [String: Any]
    
    public init(company_id: String, name: String, additionalAttributes: [String: Any] = [:]) {
        self.company_id = company_id
        self.name = name
        self.additionalAttributes = additionalAttributes
    }
    
    /// Dictionary representation of the company
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "company_id": company_id,
            "name": name
        ]
        
        additionalAttributes.forEach { dict[$0.key] = $0.value }
        
        return dict
    }
}

/// User event information
public struct Event {
    /// The event name
    public let name: String
    
    /// Optional event date
    public var date: Date?
    
    public init(name: String, date: Date? = nil) {
        self.name = name
        self.date = date
    }
    
    /// Dictionary representation of the event
    var dictionary: [String: Any] {
        var dict: [String: Any] = ["name": name]
        date.map { dict["date"] = $0.timeIntervalSince1970 }
        return dict
    }
} 