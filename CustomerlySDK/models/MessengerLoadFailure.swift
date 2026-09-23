import Foundation

/// Why the messenger couldn't boot, passed to `Customerly.setOnMessengerLoadFailed`.
public struct MessengerLoadFailure {
    /// HTTP status of the failed messenger boot request, nil on network errors.
    public let status: Int?
    public let message: String?

    public init(status: Int? = nil, message: String? = nil) {
        self.status = status
        self.message = message
    }

    public init(from dict: [String: Any]) {
        self.status = dict["status"] as? Int
        self.message = dict["message"] as? String
    }

    var dictionary: [String: Any] {
        var dict: [String: Any] = [:]

        if let status = status {
            dict["status"] = status
        }
        if let message = message {
            dict["message"] = message
        }

        return dict
    }
}
