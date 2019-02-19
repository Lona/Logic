import AppKit

public struct SwiftLoop: Codable & Equatable {
    public var pattern: SwiftIdentifier
    public var expression: SwiftIdentifier
    public var statements: SwiftList<SwiftStatement>
}

public enum SwiftStatement: Codable & Equatable {
    case loop(SwiftLoop)
    case branch
    case declaration(SwiftDeclaration)

    // MARK: Codable

    public enum CodingKeys: CodingKey {
        case type
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "loop":
            self = .loop(try container.decode(SwiftLoop.self, forKey: .data))
        case "branch":
            self = .branch
        case "declaration":
            self = .declaration(try container.decode(SwiftDeclaration.self, forKey: .data))
        default:
            fatalError("Failed to decode enum due to invalid case type.")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .loop(let value):
            try container.encode("loop", forKey: .type)
            try container.encode(value, forKey: .data)
        case .branch:
            try container.encode("branch", forKey: .type)
        case .declaration(let value):
            try container.encode("declaration", forKey: .type)
            try container.encode(value, forKey: .data)
        }
    }
}

public indirect enum SwiftList<T: Equatable & Codable>: Codable & Equatable {
    case next(T, SwiftList)
    case empty

    // MARK: Codable

    public init(from decoder: Decoder) throws {
        var unkeyedContainer = try decoder.unkeyedContainer()

        self = .empty

        while !unkeyedContainer.isAtEnd {
            let item = try unkeyedContainer.decode(T.self)
            self = .next(item, self)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var unkeyedContainer = encoder.unkeyedContainer()

        var head = self

        while case let .next(item, next) = head {
            try unkeyedContainer.encode(item)
            head = next
        }
    }
}

public enum SwiftDeclaration: Codable & Equatable {
    case variable(SwiftIdentifier)
    case function(SwiftIdentifier)

    // MARK: Codable

    public enum CodingKeys: CodingKey {
        case type
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "variable":
            self = .variable(try container.decode(SwiftIdentifier.self, forKey: .data))
        case "function":
            self = .function(try container.decode(SwiftIdentifier.self, forKey: .data))
        default:
            fatalError("Failed to decode enum due to invalid case type.")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .variable(let value):
            try container.encode("variable", forKey: .type)
            try container.encode(value, forKey: .data)
        case .function(let value):
            try container.encode("function", forKey: .type)
            try container.encode(value, forKey: .data)
        }
    }
}
