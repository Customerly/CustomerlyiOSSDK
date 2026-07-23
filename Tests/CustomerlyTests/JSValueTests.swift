import XCTest
@testable import CustomerlySDK

/// Verifies that every value the SDK interpolates into a `evaluateJavaScript` snippet is encoded
/// safely — the fix for the string-injection / call-breakage class of bugs.
final class JSValueTests: XCTestCase {

    func testPlainStringIsQuoted() {
        XCTAssertEqual(JSValue.literal("hello"), "\"hello\"")
    }

    func testApostropheDoesNotBreakTheCall() {
        // The classic real-world failure: a name like O'Brien used to produce customerly.event('O'Brien').
        let literal = JSValue.literal("O'Brien")
        XCTAssertEqual(literal, "\"O'Brien\"")
        // And the resulting snippet round-trips back to the original string.
        XCTAssertEqual(decodeJSONString(literal), "O'Brien")
    }

    func testDoubleQuotesAndBackslashesAreEscaped() {
        let input = #"say "hi" \ now"#
        let literal = JSValue.literal(input)
        XCTAssertEqual(decodeJSONString(literal), input)
        // The escaped payload must not contain a bare, unescaped double quote in the interior.
        XCTAssertTrue(literal.hasPrefix("\""))
        XCTAssertTrue(literal.hasSuffix("\""))
    }

    func testNewlinesAreEscaped() {
        let input = "line1\nline2"
        let literal = JSValue.literal(input)
        XCTAssertFalse(literal.contains("\n"), "raw newline would break the JS statement")
        XCTAssertEqual(decodeJSONString(literal), input)
    }

    func testScriptInjectionAttemptIsNeutralized() {
        // Attempted breakout: close the string, run code, comment out the rest.
        let malicious = "');window.__pwned=true;//"
        let literal = JSValue.literal(malicious)
        // It stays a single JSON string literal; decoding yields the original text verbatim.
        XCTAssertEqual(decodeJSONString(literal), malicious)
        XCTAssertFalse(literal.contains("window.__pwned=true;//\""),
                       "payload must remain inside the quoted string")
    }

    func testNumbersAndBooleans() {
        XCTAssertEqual(JSValue.literal(42), "42")
        XCTAssertEqual(JSValue.literal(true), "true")
        XCTAssertEqual(JSValue.literal(false), "false")
    }

    func testDictionaryProducesValidJSON() {
        let literal = JSValue.literal(["source": "sdk_test"])
        let data = literal.data(using: .utf8)!
        let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        XCTAssertEqual(parsed, ["source": "sdk_test"])
    }

    func testUnrepresentableValueFallsBackToNull() {
        XCTAssertEqual(JSValue.literal(Data([0x00])), "null")
    }

    // MARK: - Helpers

    private func decodeJSONString(_ literal: String) -> String? {
        guard let data = literal.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) as? String
    }
}
