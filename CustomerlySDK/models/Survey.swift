import Foundation

public enum SurveyQuestionType: Int {
    case button = 0
    case radioButton = 1
    case select = 2
    case scale = 3
    case star = 4
    case integer = 5
    case textbox = 6
    case textarea = 7
}

public struct Survey {
    public let survey_id: Int64
    public let creator: Account
    public let thank_you_text: String?
    public let seen_at: TimeInterval?
    public let question: SurveyQuestion?
    
    public init(
        survey_id: Int64,
        creator: Account,
        thank_you_text: String? = nil,
        seen_at: TimeInterval? = nil,
        question: SurveyQuestion? = nil
    ) {
        self.survey_id = survey_id
        self.creator = creator
        self.thank_you_text = thank_you_text
        self.seen_at = seen_at
        self.question = question
    }
    
    public init(from dict: [String: Any]) throws {
        guard let surveyId = dict["survey_id"] as? Int64,
              let creator = dict["creator"] as? [String: Any] else {
            throw NSError(domain: "Customerly", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Survey data"])
        }
        
        self.survey_id = surveyId
        self.creator = try Account(from: creator)
        self.thank_you_text = dict["thank_you_text"] as? String
        self.seen_at = dict["seen_at"] as? TimeInterval
        
        if let question = dict["question"] as? [String: Any] {
            self.question = try SurveyQuestion(from: question)
        } else {
            self.question = nil
        }
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "survey_id": survey_id,
            "creator": creator.dictionary
        ]
        
        if let thankYouText = thank_you_text {
            dict["thank_you_text"] = thankYouText
        }
        if let seenAt = seen_at {
            dict["seen_at"] = seenAt
        }
        if let question = question {
            dict["question"] = question.dictionary
        }
        
        return dict
    }
}

public struct SurveyQuestion {
    public let survey_id: Int64
    public let survey_question_id: Int64
    public let step: Int
    public let title: String?
    public let subtitle: String?
    public let type: SurveyQuestionType
    public let limits: QuestionLimits?
    public let choices: [SurveyQuestionChoice]
    
    public init(
        survey_id: Int64,
        survey_question_id: Int64,
        step: Int,
        title: String? = nil,
        subtitle: String? = nil,
        type: SurveyQuestionType,
        limits: QuestionLimits? = nil,
        choices: [SurveyQuestionChoice]
    ) {
        self.survey_id = survey_id
        self.survey_question_id = survey_question_id
        self.step = step
        self.title = title
        self.subtitle = subtitle
        self.type = type
        self.limits = limits
        self.choices = choices
    }
    
    public init(from dict: [String: Any]) throws {
        guard let surveyId = dict["survey_id"] as? Int64,
              let surveyQuestionId = dict["survey_question_id"] as? Int64,
              let step = dict["step"] as? Int,
              let type = dict["type"] as? Int,
              let choices = dict["choices"] as? [[String: Any]] else {
            throw NSError(domain: "Customerly", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid SurveyQuestion data"])
        }
        
        self.survey_id = surveyId
        self.survey_question_id = surveyQuestionId
        self.step = step
        self.title = dict["title"] as? String
        self.subtitle = dict["subtitle"] as? String
        self.type = SurveyQuestionType(rawValue: type) ?? .textbox
        
        if let limits = dict["limits"] as? [String: Any] {
            self.limits = try QuestionLimits(from: limits)
        } else {
            self.limits = nil
        }
        
        self.choices = try choices.map { try SurveyQuestionChoice(from: $0) }
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "survey_id": survey_id,
            "survey_question_id": survey_question_id,
            "step": step,
            "type": type.rawValue,
            "choices": choices.map { $0.dictionary }
        ]
        
        if let title = title {
            dict["title"] = title
        }
        if let subtitle = subtitle {
            dict["subtitle"] = subtitle
        }
        if let limits = limits {
            dict["limits"] = limits.dictionary
        }
        
        return dict
    }
}

public struct QuestionLimits {
    public let from: Int
    public let to: Int
    
    public init(from: Int, to: Int) {
        self.from = from
        self.to = to
    }
    
    public init(from dict: [String: Any]) throws {
        guard let from = dict["from"] as? Int,
              let to = dict["to"] as? Int else {
            throw NSError(domain: "Customerly", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid QuestionLimits data"])
        }
        
        self.from = from
        self.to = to
    }
    
    var dictionary: [String: Any] {
        return [
            "from": from,
            "to": to
        ]
    }
}

public struct SurveyQuestionChoice {
    public let survey_id: Int64
    public let survey_question_id: Int64
    public let survey_choice_id: Int64
    public let step: Int
    public let value: String?
    
    public init(
        survey_id: Int64,
        survey_question_id: Int64,
        survey_choice_id: Int64,
        step: Int,
        value: String? = nil
    ) {
        self.survey_id = survey_id
        self.survey_question_id = survey_question_id
        self.survey_choice_id = survey_choice_id
        self.step = step
        self.value = value
    }
    
    public init(from dict: [String: Any]) throws {
        guard let surveyId = dict["survey_id"] as? Int64,
              let surveyQuestionId = dict["survey_question_id"] as? Int64,
              let surveyChoiceId = dict["survey_choice_id"] as? Int64,
              let step = dict["step"] as? Int else {
            throw NSError(domain: "Customerly", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid SurveyQuestionChoice data"])
        }
        
        self.survey_id = surveyId
        self.survey_question_id = surveyQuestionId
        self.survey_choice_id = surveyChoiceId
        self.step = step
        self.value = dict["value"] as? String
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "survey_id": survey_id,
            "survey_question_id": survey_question_id,
            "survey_choice_id": survey_choice_id,
            "step": step
        ]
        
        if let value = value {
            dict["value"] = value
        }
        
        return dict
    }
} 