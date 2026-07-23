import Foundation

/// Encodes Swift values into safe JavaScript literals.
///
/// The SDK drives the web messenger by building small JS snippets and running them through
/// `WKWebView.evaluateJavaScript`. Interpolating raw strings into those snippets would let an
/// apostrophe break the call — or a crafted value inject arbitrary script into the messenger's
/// authenticated origin. Routing every interpolated argument through `JSValue.literal` produces a
/// JSON literal (valid JS), which is both injection-safe and escaping-correct.
enum JSValue {
    /// Returns a JavaScript literal for `value`.
    ///
    /// - Strings become quoted, escaped JSON strings (`O'Brien` -> `"O'Brien"`).
    /// - Numbers, booleans, arrays and dictionaries become their JSON form.
    /// - Anything that can't be represented as JSON falls back to `null`.
    static func literal(_ value: Any) -> String {
        // Wrap in an array before serializing: it lets JSONSerialization accept fragment values
        // (String, NSNumber, Bool) and — crucially — lets us validate with `isValidJSONObject`
        // first. Passing an unsupported type straight to `data(withJSONObject:)` raises an
        // Objective-C exception that `try?` cannot catch, which would crash the host app.
        let wrapped: [Any] = [value]
        guard JSONSerialization.isValidJSONObject(wrapped),
              let data = try? JSONSerialization.data(withJSONObject: wrapped),
              let json = String(data: data, encoding: .utf8),
              json.count >= 2 else {
            return "null"
        }
        // Strip the surrounding `[` and `]` we added.
        return String(json.dropFirst().dropLast())
    }
}
