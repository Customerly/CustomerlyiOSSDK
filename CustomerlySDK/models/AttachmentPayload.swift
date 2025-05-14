import Foundation

public struct AttachmentPayload {
    public let name: String
    public let size: Int
    public let base64: String
    
    public init(name: String, size: Int, base64: String) {
        self.name = name
        self.size = size
        self.base64 = base64
    }
    
    public init(from dict: [String: Any]) throws {
        guard let name = dict["name"] as? String,
              let size = dict["size"] as? Int,
              let base64 = dict["base64"] as? String else {
            throw NSError(domain: "Customerly", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid AttachmentPayload data"])
        }
        
        self.name = name
        self.size = size
        self.base64 = base64
    }
    
    var dictionary: [String: Any] {
        return [
            "name": name,
            "size": size,
            "base64": base64
        ]
    }
}
