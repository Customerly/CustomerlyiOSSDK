import Foundation

public struct CustomerlySettings {
    public let app_id: String
    public var user_id: String?
    public var name: String?
    public var email: String?
    public var email_hash: String?
    public var accentColor: String?
    public var contrastColor: String?
    public var attachmentsAvailable: Bool?
    public var singleConversation: Bool?
    public var last_page_viewed: String?
    public var force_lead: Bool?
    public var attributes: [String: Any]?
    public var company: Company?
    public var events: [Event]?
    
    public init(
        app_id: String,
        user_id: String? = nil,
        name: String? = nil,
        email: String? = nil,
        email_hash: String? = nil,
        accentColor: String? = nil,
        contrastColor: String? = nil,
        attachmentsAvailable: Bool? = nil,
        singleConversation: Bool? = nil,
        last_page_viewed: String? = nil,
        force_lead: Bool? = nil,
        attributes: [String: Any]? = nil,
        company: Company? = nil,
        events: [Event]? = nil
    ) {
        self.app_id = app_id
        self.user_id = user_id
        self.name = name
        self.email = email
        self.email_hash = email_hash
        self.accentColor = accentColor
        self.contrastColor = contrastColor
        self.attachmentsAvailable = attachmentsAvailable
        self.singleConversation = singleConversation
        self.last_page_viewed = last_page_viewed
        self.force_lead = force_lead
        self.attributes = attributes
        self.company = company
        self.events = events
    }
    
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

public struct Company {
    public let company_id: String
    public let name: String
    public var additionalAttributes: [String: Any]
    
    public init(company_id: String, name: String, additionalAttributes: [String: Any] = [:]) {
        self.company_id = company_id
        self.name = name
        self.additionalAttributes = additionalAttributes
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "company_id": company_id,
            "name": name
        ]
        
        additionalAttributes.forEach { dict[$0.key] = $0.value }
        
        return dict
    }
}

public struct Event {
    public let name: String
    public var date: Date?
    
    public init(name: String, date: Date? = nil) {
        self.name = name
        self.date = date
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = ["name": name]
        date.map { dict["date"] = $0.timeIntervalSince1970 }
        return dict
    }
}
