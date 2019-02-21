import AppKit

public struct SwiftIdentifier: Codable & Equatable {
  public var id: SwiftUUID
  public var string: SwiftString
}

public struct SwiftLoop: Codable & Equatable {
  public var pattern: SwiftIdentifier
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
  public var op: SwiftString
  public var id: SwiftUUID
}

public struct SwiftIdentifierExpression: Codable & Equatable {
  public var id: SwiftUUID
  public var identifier: SwiftIdentifier
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
    }
  }
}

public indirect enum SwiftExpression: Codable & Equatable {
  case binaryExpression(SwiftBinaryExpression)
  case identifierExpression(SwiftIdentifierExpression)

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
    }
  }
}
