import Foundation

public struct HelpCenterArticle {
    public let knowledge_base_article_id: Int64
    public let knowledge_base_collection_id: Int64
    public let app_id: String
    public let slug: String
    public let title: String
    public let description: String
    public let body: String
    public let sort: Int
    public let written_by: WrittenBy
    public let updated_at: TimeInterval
    
    public init(
        knowledge_base_article_id: Int64,
        knowledge_base_collection_id: Int64,
        app_id: String,
        slug: String,
        title: String,
        description: String,
        body: String,
        sort: Int,
        written_by: WrittenBy,
        updated_at: TimeInterval
    ) {
        self.knowledge_base_article_id = knowledge_base_article_id
        self.knowledge_base_collection_id = knowledge_base_collection_id
        self.app_id = app_id
        self.slug = slug
        self.title = title
        self.description = description
        self.body = body
        self.sort = sort
        self.written_by = written_by
        self.updated_at = updated_at
    }
    
    public init(from dict: [String: Any]) throws {
        guard let knowledgeBaseArticleId = dict["knowledge_base_article_id"] as? Int64,
              let knowledgeBaseCollectionId = dict["knowledge_base_collection_id"] as? Int64,
              let appId = dict["app_id"] as? String,
              let slug = dict["slug"] as? String,
              let title = dict["title"] as? String,
              let description = dict["description"] as? String,
              let body = dict["body"] as? String,
              let sort = dict["sort"] as? Int,
              let writtenBy = dict["written_by"] as? [String: Any],
              let updatedAt = dict["updated_at"] as? TimeInterval else {
            throw NSError(domain: "Customerly", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid HelpCenterArticle data"])
        }
        
        self.knowledge_base_article_id = knowledgeBaseArticleId
        self.knowledge_base_collection_id = knowledgeBaseCollectionId
        self.app_id = appId
        self.slug = slug
        self.title = title
        self.description = description
        self.body = body
        self.sort = sort
        self.written_by = try WrittenBy(from: writtenBy)
        self.updated_at = updatedAt
    }
    
    var dictionary: [String: Any] {
        return [
            "knowledge_base_article_id": knowledge_base_article_id,
            "knowledge_base_collection_id": knowledge_base_collection_id,
            "app_id": app_id,
            "slug": slug,
            "title": title,
            "description": description,
            "body": body,
            "sort": sort,
            "written_by": written_by.dictionary,
            "updated_at": updated_at
        ]
    }
}

public struct WrittenBy {
    public let account_id: Int64
    public let email: String?
    public let name: String
    
    public init(account_id: Int64, email: String?, name: String) {
        self.account_id = account_id
        self.email = email
        self.name = name
    }
    
    public init(from dict: [String: Any]) throws {
        guard let accountId = dict["account_id"] as? Int64,
              let name = dict["name"] as? String else {
            throw NSError(domain: "Customerly", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid WrittenBy data"])
        }
        
        self.account_id = accountId
        self.email = dict["email"] as? String
        self.name = name
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "account_id": account_id,
            "name": name
        ]
        if let email = email {
            dict["email"] = email
        }
        return dict
    }
}
