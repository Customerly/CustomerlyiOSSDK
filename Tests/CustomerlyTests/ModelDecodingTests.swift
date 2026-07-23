import XCTest
@testable import CustomerlySDK

/// Exercises the hand-written `init(from: [String: Any])` decoders and their `dictionary`
/// round-trips for the payloads the messenger posts to the native layer.
final class ModelDecodingTests: XCTestCase {

    func testAccountDecodesRequiredAndOptionalFields() throws {
        let account = try Account(from: ["account_id": Int64(7), "name": "Aura", "is_ai": true])
        XCTAssertEqual(account.account_id, 7)
        XCTAssertEqual(account.name, "Aura")
        XCTAssertEqual(account.is_ai, true)
    }

    func testAccountThrowsWithoutId() {
        XCTAssertThrowsError(try Account(from: ["name": "no id"]))
    }

    func testUnreadMessageDecodeAndRoundTrip() throws {
        let dict: [String: Any] = [
            "accountId": Int64(1),
            "accountName": "Support",
            "message": "Hi there",
            "timestamp": Int64(1_700_000_000),
            "userId": Int64(99),
            "conversationId": Int64(1234)
        ]
        let message = try UnreadMessage(from: dict)
        XCTAssertEqual(message.conversationId, 1234)
        XCTAssertEqual(message.accountName, "Support")

        // Round-trip through the dictionary representation.
        let rebuilt = try UnreadMessage(from: message.dictionary)
        XCTAssertEqual(rebuilt.conversationId, message.conversationId)
        XCTAssertEqual(rebuilt.timestamp, message.timestamp)
        XCTAssertEqual(rebuilt.message, message.message)
    }

    func testUnreadMessageThrowsWithoutConversationId() {
        XCTAssertThrowsError(try UnreadMessage(from: ["timestamp": Int64(0)]))
    }

    func testSurveyDecodesNestedQuestionAndChoices() throws {
        let dict: [String: Any] = [
            "survey_id": Int64(5),
            "creator": ["account_id": Int64(2), "name": "PM"],
            "question": [
                "survey_id": Int64(5),
                "survey_question_id": Int64(50),
                "step": 1,
                "type": SurveyQuestionType.scale.rawValue,
                "choices": [
                    ["survey_id": Int64(5), "survey_question_id": Int64(50), "survey_choice_id": Int64(500), "step": 1, "value": "Yes"]
                ]
            ]
        ]
        let survey = try Survey(from: dict)
        XCTAssertEqual(survey.survey_id, 5)
        XCTAssertEqual(survey.creator.name, "PM")
        XCTAssertEqual(survey.question?.type, .scale)
        XCTAssertEqual(survey.question?.choices.first?.value, "Yes")
    }

    func testSurveyUnknownQuestionTypeFallsBackToTextbox() throws {
        let dict: [String: Any] = [
            "survey_id": Int64(5),
            "creator": ["account_id": Int64(2), "name": "PM"],
            "question": [
                "survey_id": Int64(5),
                "survey_question_id": Int64(50),
                "step": 1,
                "type": 999,
                "choices": [[String: Any]]()
            ]
        ]
        let survey = try Survey(from: dict)
        XCTAssertEqual(survey.question?.type, .textbox)
    }

    func testHelpCenterArticleRequiresAllFields() {
        XCTAssertThrowsError(try HelpCenterArticle(from: ["slug": "partial"]))
    }

    func testHelpCenterArticleDecodesWithAndWithoutBody() throws {
        // The messenger's `HelpCenterArticle` callback type does not include `body`; the decoder
        // must not require it.
        var dict: [String: Any] = [
            "knowledge_base_article_id": Int64(1),
            "knowledge_base_collection_id": Int64(2),
            "app_id": "app",
            "slug": "getting-started",
            "title": "Title",
            "description": "Desc",
            "sort": 0,
            "written_by": ["account_id": Int64(3), "name": "Author"],
            "updated_at": TimeInterval(1_700_000_000)
        ]

        let withoutBody = try HelpCenterArticle(from: dict)
        XCTAssertNil(withoutBody.body)

        dict["body"] = "<p>Full body</p>"
        let withBody = try HelpCenterArticle(from: dict)
        XCTAssertEqual(withBody.body, "<p>Full body</p>")
    }
}
