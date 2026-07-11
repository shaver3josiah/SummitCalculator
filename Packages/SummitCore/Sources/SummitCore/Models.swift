import Foundation

public enum CalcOp: String, Codable, Sendable {
    case add
    case subtract
    case multiply
    case divide
}

public struct CalcResult: Equatable, Sendable {
    public let display: String
    public let expression: String
    public let sequence: String

    public init(display: String, expression: String, sequence: String) {
        self.display = display
        self.expression = expression
        self.sequence = sequence
    }
}

public struct Egg: Codable, Equatable, Sendable {
    public let id: String
    public let kind: String
    public let title: String
    public let dateLabel: String
    public let lines: [String]
    public let more: [String]?
    public let triggers: [String]

    public init(id: String, kind: String, title: String, dateLabel: String, lines: [String], more: [String]?, triggers: [String]) {
        self.id = id
        self.kind = kind
        self.title = title
        self.dateLabel = dateLabel
        self.lines = lines
        self.more = more
        self.triggers = triggers
    }
}

public struct Fund: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var ratePct: Double

    public init(id: UUID, name: String, ratePct: Double) {
        self.id = id
        self.name = name
        self.ratePct = ratePct
    }
}

public struct HistoryEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var ts: Date
    public var type: String
    public var title: String
    public var value: String
    public var extra: [String: String]

    public init(id: String, ts: Date, type: String, title: String, value: String, extra: [String: String]) {
        self.id = id
        self.ts = ts
        self.type = type
        self.title = title
        self.value = value
        self.extra = extra
    }
}

public struct ThemeSpec: Codable, Equatable, Sendable {
    public var name: String
    public var tokens: [String: String]

    public init(name: String, tokens: [String: String]) {
        self.name = name
        self.tokens = tokens
    }
}

public struct Food: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var group: String
    public var measure: String
    public var glyph: String
    public var artKey: String?

    public init(id: String, name: String, group: String, measure: String, glyph: String, artKey: String?) {
        self.id = id
        self.name = name
        self.group = group
        self.measure = measure
        self.glyph = glyph
        self.artKey = artKey
    }
}

public struct ParsedIngredient: Codable, Equatable, Sendable {
    public var qty: Double?
    public var unit: String?
    public var name: String
    public var raw: String

    public init(qty: Double?, unit: String?, name: String, raw: String) {
        self.qty = qty
        self.unit = unit
        self.name = name
        self.raw = raw
    }
}
