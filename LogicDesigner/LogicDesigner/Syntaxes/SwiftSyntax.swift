import AppKit

public struct SwiftIdentifier: Codable & Equatable {
  public var id: SwiftUUID
  public var string: SwiftString
}

public struct SwiftLoop: Codable & Equatable {
  public var pattern: SwiftPattern
  public var expression: SwiftExpression
  public var block: SwiftList<SwiftStatement>
  public var id: SwiftUUID
}

public struct SwiftBranch: Codable & Equatable {
  public var id: SwiftUUID
  public var condition: SwiftExpression
  public var block: SwiftList<SwiftStatement>
}

public struct SwiftDecl: Codable & Equatable {
  public var content: SwiftDeclaration
  public var id: SwiftUUID
}

public struct SwiftExpressionStatement: Codable & Equatable {
  public var id: SwiftUUID
  public var expression: SwiftExpression
}

public struct SwiftPlaceholderStatement: Codable & Equatable {
  public var id: SwiftUUID
}

public struct SwiftVariable: Codable & Equatable {
  public var id: SwiftUUID
}

public struct SwiftFunction: Codable & Equatable {
  public var id: SwiftUUID
}

public struct SwiftBinaryExpression: Codable & Equatable {
  public var left: SwiftExpression
  public var right: SwiftExpression
  public var op: SwiftBinaryOperator
  public var id: SwiftUUID
}

public struct SwiftIdentifierExpression: Codable & Equatable {
  public var id: SwiftUUID
  public var identifier: SwiftIdentifier
}

public struct SwiftFunctionCallExpression: Codable & Equatable {
  public var id: SwiftUUID
  public var expression: SwiftExpression
  public var arguments: SwiftList<SwiftFunctionCallArgument>
}

public struct SwiftPattern: Codable & Equatable {
  public var id: SwiftUUID
  public var name: SwiftString
}

public struct SwiftIsEqualTo: Codable & Equatable {
  public var id: SwiftUUID
}

public struct SwiftIsNotEqualTo: Codable & Equatable {
  public var id: SwiftUUID
}

public struct SwiftIsLessThan: Codable & Equatable {
  public var id: SwiftUUID
}

public struct SwiftIsGreaterThan: Codable & Equatable {
  public var id: SwiftUUID
}

public struct SwiftIsLessThanOrEqualTo: Codable & Equatable {
  public var id: SwiftUUID
}

public struct SwiftIsGreaterThanOrEqualTo: Codable & Equatable {
  public var id: SwiftUUID
}

public struct SwiftSetEqualTo: Codable & Equatable {
  public var id: SwiftUUID
}

public struct SwiftProgram: Codable & Equatable {
  public var id: SwiftUUID
  public var block: SwiftList<SwiftStatement>
}

public struct SwiftFunctionCallArgument: Codable & Equatable {
  public var id: SwiftUUID
  public var label: SwiftString
  public var expression: SwiftExpression
}

public indirect enum SwiftStatement: Codable & Equatable {
  case loop(SwiftLoop)
  case branch(SwiftBranch)
  case decl(SwiftDecl)
  case expressionStatement(SwiftExpressionStatement)
  case placeholderStatement(SwiftPlaceholderStatement)

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
        self = .branch(try container.decode(SwiftBranch.self, forKey: .data))
      case "decl":
        self = .decl(try container.decode(SwiftDecl.self, forKey: .data))
      case "expressionStatement":
        self = .expressionStatement(try container.decode(SwiftExpressionStatement.self, forKey: .data))
      case "placeholderStatement":
        self = .placeholderStatement(try container.decode(SwiftPlaceholderStatement.self, forKey: .data))
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
      case .branch(let value):
        try container.encode("branch", forKey: .type)
        try container.encode(value, forKey: .data)
      case .decl(let value):
        try container.encode("decl", forKey: .type)
        try container.encode(value, forKey: .data)
      case .expressionStatement(let value):
        try container.encode("expressionStatement", forKey: .type)
        try container.encode(value, forKey: .data)
      case .placeholderStatement(let value):
        try container.encode("placeholderStatement", forKey: .type)
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

    var items: [T] = []
    while !unkeyedContainer.isAtEnd {
      items.append(try unkeyedContainer.decode(T.self))
    }

    self = .empty
    while let item = items.popLast() {
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

public indirect enum SwiftDeclaration: Codable & Equatable {
  case variable(SwiftVariable)
  case function(SwiftFunction)

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
        self = .variable(try container.decode(SwiftVariable.self, forKey: .data))
      case "function":
        self = .function(try container.decode(SwiftFunction.self, forKey: .data))
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

public indirect enum SwiftSyntaxNode: Codable & Equatable {
  case statement(SwiftStatement)
  case declaration(SwiftDeclaration)
  case identifier(SwiftIdentifier)
  case expression(SwiftExpression)
  case pattern(SwiftPattern)
  case binaryOperator(SwiftBinaryOperator)
  case program(SwiftProgram)

  // MARK: Codable

  public enum CodingKeys: CodingKey {
    case type
    case data
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
      case "statement":
        self = .statement(try container.decode(SwiftStatement.self, forKey: .data))
      case "declaration":
        self = .declaration(try container.decode(SwiftDeclaration.self, forKey: .data))
      case "identifier":
        self = .identifier(try container.decode(SwiftIdentifier.self, forKey: .data))
      case "expression":
        self = .expression(try container.decode(SwiftExpression.self, forKey: .data))
      case "pattern":
        self = .pattern(try container.decode(SwiftPattern.self, forKey: .data))
      case "binaryOperator":
        self = .binaryOperator(try container.decode(SwiftBinaryOperator.self, forKey: .data))
      case "program":
        self = .program(try container.decode(SwiftProgram.self, forKey: .data))
      default:
        fatalError("Failed to decode enum due to invalid case type.")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
      case .statement(let value):
        try container.encode("statement", forKey: .type)
        try container.encode(value, forKey: .data)
      case .declaration(let value):
        try container.encode("declaration", forKey: .type)
        try container.encode(value, forKey: .data)
      case .identifier(let value):
        try container.encode("identifier", forKey: .type)
        try container.encode(value, forKey: .data)
      case .expression(let value):
        try container.encode("expression", forKey: .type)
        try container.encode(value, forKey: .data)
      case .pattern(let value):
        try container.encode("pattern", forKey: .type)
        try container.encode(value, forKey: .data)
      case .binaryOperator(let value):
        try container.encode("binaryOperator", forKey: .type)
        try container.encode(value, forKey: .data)
      case .program(let value):
        try container.encode("program", forKey: .type)
        try container.encode(value, forKey: .data)
    }
  }
}

public indirect enum SwiftExpression: Codable & Equatable {
  case binaryExpression(SwiftBinaryExpression)
  case identifierExpression(SwiftIdentifierExpression)
  case functionCallExpression(SwiftFunctionCallExpression)

  // MARK: Codable

  public enum CodingKeys: CodingKey {
    case type
    case data
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
      case "binaryExpression":
        self = .binaryExpression(try container.decode(SwiftBinaryExpression.self, forKey: .data))
      case "identifierExpression":
        self = .identifierExpression(try container.decode(SwiftIdentifierExpression.self, forKey: .data))
      case "functionCallExpression":
        self = .functionCallExpression(try container.decode(SwiftFunctionCallExpression.self, forKey: .data))
      default:
        fatalError("Failed to decode enum due to invalid case type.")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
      case .binaryExpression(let value):
        try container.encode("binaryExpression", forKey: .type)
        try container.encode(value, forKey: .data)
      case .identifierExpression(let value):
        try container.encode("identifierExpression", forKey: .type)
        try container.encode(value, forKey: .data)
      case .functionCallExpression(let value):
        try container.encode("functionCallExpression", forKey: .type)
        try container.encode(value, forKey: .data)
    }
  }
}

public indirect enum SwiftBinaryOperator: Codable & Equatable {
  case isEqualTo(SwiftIsEqualTo)
  case isNotEqualTo(SwiftIsNotEqualTo)
  case isLessThan(SwiftIsLessThan)
  case isGreaterThan(SwiftIsGreaterThan)
  case isLessThanOrEqualTo(SwiftIsLessThanOrEqualTo)
  case isGreaterThanOrEqualTo(SwiftIsGreaterThanOrEqualTo)
  case setEqualTo(SwiftSetEqualTo)

  // MARK: Codable

  public enum CodingKeys: CodingKey {
    case type
    case data
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
      case "isEqualTo":
        self = .isEqualTo(try container.decode(SwiftIsEqualTo.self, forKey: .data))
      case "isNotEqualTo":
        self = .isNotEqualTo(try container.decode(SwiftIsNotEqualTo.self, forKey: .data))
      case "isLessThan":
        self = .isLessThan(try container.decode(SwiftIsLessThan.self, forKey: .data))
      case "isGreaterThan":
        self = .isGreaterThan(try container.decode(SwiftIsGreaterThan.self, forKey: .data))
      case "isLessThanOrEqualTo":
        self = .isLessThanOrEqualTo(try container.decode(SwiftIsLessThanOrEqualTo.self, forKey: .data))
      case "isGreaterThanOrEqualTo":
        self = .isGreaterThanOrEqualTo(try container.decode(SwiftIsGreaterThanOrEqualTo.self, forKey: .data))
      case "setEqualTo":
        self = .setEqualTo(try container.decode(SwiftSetEqualTo.self, forKey: .data))
      default:
        fatalError("Failed to decode enum due to invalid case type.")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
      case .isEqualTo(let value):
        try container.encode("isEqualTo", forKey: .type)
        try container.encode(value, forKey: .data)
      case .isNotEqualTo(let value):
        try container.encode("isNotEqualTo", forKey: .type)
        try container.encode(value, forKey: .data)
      case .isLessThan(let value):
        try container.encode("isLessThan", forKey: .type)
        try container.encode(value, forKey: .data)
      case .isGreaterThan(let value):
        try container.encode("isGreaterThan", forKey: .type)
        try container.encode(value, forKey: .data)
      case .isLessThanOrEqualTo(let value):
        try container.encode("isLessThanOrEqualTo", forKey: .type)
        try container.encode(value, forKey: .data)
      case .isGreaterThanOrEqualTo(let value):
        try container.encode("isGreaterThanOrEqualTo", forKey: .type)
        try container.encode(value, forKey: .data)
      case .setEqualTo(let value):
        try container.encode("setEqualTo", forKey: .type)
        try container.encode(value, forKey: .data)
    }
  }
}
