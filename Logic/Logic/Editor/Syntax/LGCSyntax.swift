import AppKit

public struct LGCIdentifier: Codable & Equatable {
  public init(id: UUID, string: String) {
    self.id = id
    self.string = string
  }

  public var id: UUID
  public var string: String
}

public struct LGCLoop: Codable & Equatable {
  public init(pattern: LGCPattern, expression: LGCExpression, block: LGCList<LGCStatement>, id: UUID) {
    self.pattern = pattern
    self.expression = expression
    self.block = block
    self.id = id
  }

  public var pattern: LGCPattern
  public var expression: LGCExpression
  public var block: LGCList<LGCStatement>
  public var id: UUID
}

public struct LGCBranch: Codable & Equatable {
  public init(id: UUID, condition: LGCExpression, block: LGCList<LGCStatement>) {
    self.id = id
    self.condition = condition
    self.block = block
  }

  public var id: UUID
  public var condition: LGCExpression
  public var block: LGCList<LGCStatement>
}

public struct LGCDecl: Codable & Equatable {
  public init(content: LGCDeclaration, id: UUID) {
    self.content = content
    self.id = id
  }

  public var content: LGCDeclaration
  public var id: UUID
}

public struct LGCExpressionStatement: Codable & Equatable {
  public init(id: UUID, expression: LGCExpression) {
    self.id = id
    self.expression = expression
  }

  public var id: UUID
  public var expression: LGCExpression
}

public struct LGCPlaceholderStatement: Codable & Equatable {
  public init(id: UUID) {
    self.id = id
  }

  public var id: UUID
}

public struct LGCVariable: Codable & Equatable {
  public init(id: UUID) {
    self.id = id
  }

  public var id: UUID
}

public struct LGCFunction: Codable & Equatable {
  public init(id: UUID) {
    self.id = id
  }

  public var id: UUID
}

public struct LGCBinaryExpression: Codable & Equatable {
  public init(left: LGCExpression, right: LGCExpression, op: LGCBinaryOperator, id: UUID) {
    self.left = left
    self.right = right
    self.op = op
    self.id = id
  }

  public var left: LGCExpression
  public var right: LGCExpression
  public var op: LGCBinaryOperator
  public var id: UUID
}

public struct LGCIdentifierExpression: Codable & Equatable {
  public init(id: UUID, identifier: LGCIdentifier) {
    self.id = id
    self.identifier = identifier
  }

  public var id: UUID
  public var identifier: LGCIdentifier
}

public struct LGCFunctionCallExpression: Codable & Equatable {
  public init(id: UUID, expression: LGCExpression, arguments: LGCList<LGCFunctionCallArgument>) {
    self.id = id
    self.expression = expression
    self.arguments = arguments
  }

  public var id: UUID
  public var expression: LGCExpression
  public var arguments: LGCList<LGCFunctionCallArgument>
}

public struct LGCPattern: Codable & Equatable {
  public init(id: UUID, name: String) {
    self.id = id
    self.name = name
  }

  public var id: UUID
  public var name: String
}

public struct LGCIsEqualTo: Codable & Equatable {
  public init(id: UUID) {
    self.id = id
  }

  public var id: UUID
}

public struct LGCIsNotEqualTo: Codable & Equatable {
  public init(id: UUID) {
    self.id = id
  }

  public var id: UUID
}

public struct LGCIsLessThan: Codable & Equatable {
  public init(id: UUID) {
    self.id = id
  }

  public var id: UUID
}

public struct LGCIsGreaterThan: Codable & Equatable {
  public init(id: UUID) {
    self.id = id
  }

  public var id: UUID
}

public struct LGCIsLessThanOrEqualTo: Codable & Equatable {
  public init(id: UUID) {
    self.id = id
  }

  public var id: UUID
}

public struct LGCIsGreaterThanOrEqualTo: Codable & Equatable {
  public init(id: UUID) {
    self.id = id
  }

  public var id: UUID
}

public struct LGCSetEqualTo: Codable & Equatable {
  public init(id: UUID) {
    self.id = id
  }

  public var id: UUID
}

public struct LGCProgram: Codable & Equatable {
  public init(id: UUID, block: LGCList<LGCStatement>) {
    self.id = id
    self.block = block
  }

  public var id: UUID
  public var block: LGCList<LGCStatement>
}

public struct LGCFunctionCallArgument: Codable & Equatable {
  public init(id: UUID, label: String, expression: LGCExpression) {
    self.id = id
    self.label = label
    self.expression = expression
  }

  public var id: UUID
  public var label: String
  public var expression: LGCExpression
}

public indirect enum LGCStatement: Codable & Equatable {
  case loop(LGCLoop)
  case branch(LGCBranch)
  case decl(LGCDecl)
  case expressionStatement(LGCExpressionStatement)
  case placeholderStatement(LGCPlaceholderStatement)

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
        self = .loop(try container.decode(LGCLoop.self, forKey: .data))
      case "branch":
        self = .branch(try container.decode(LGCBranch.self, forKey: .data))
      case "decl":
        self = .decl(try container.decode(LGCDecl.self, forKey: .data))
      case "expressionStatement":
        self = .expressionStatement(try container.decode(LGCExpressionStatement.self, forKey: .data))
      case "placeholderStatement":
        self = .placeholderStatement(try container.decode(LGCPlaceholderStatement.self, forKey: .data))
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

public indirect enum LGCList<T: Equatable & Codable>: Codable & Equatable {
  case next(T, LGCList)
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

public indirect enum LGCDeclaration: Codable & Equatable {
  case variable(LGCVariable)
  case function(LGCFunction)

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
        self = .variable(try container.decode(LGCVariable.self, forKey: .data))
      case "function":
        self = .function(try container.decode(LGCFunction.self, forKey: .data))
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

public indirect enum LGCSyntaxNode: Codable & Equatable {
  case statement(LGCStatement)
  case declaration(LGCDeclaration)
  case identifier(LGCIdentifier)
  case expression(LGCExpression)
  case pattern(LGCPattern)
  case binaryOperator(LGCBinaryOperator)
  case program(LGCProgram)

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
        self = .statement(try container.decode(LGCStatement.self, forKey: .data))
      case "declaration":
        self = .declaration(try container.decode(LGCDeclaration.self, forKey: .data))
      case "identifier":
        self = .identifier(try container.decode(LGCIdentifier.self, forKey: .data))
      case "expression":
        self = .expression(try container.decode(LGCExpression.self, forKey: .data))
      case "pattern":
        self = .pattern(try container.decode(LGCPattern.self, forKey: .data))
      case "binaryOperator":
        self = .binaryOperator(try container.decode(LGCBinaryOperator.self, forKey: .data))
      case "program":
        self = .program(try container.decode(LGCProgram.self, forKey: .data))
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

public indirect enum LGCExpression: Codable & Equatable {
  case binaryExpression(LGCBinaryExpression)
  case identifierExpression(LGCIdentifierExpression)
  case functionCallExpression(LGCFunctionCallExpression)

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
        self = .binaryExpression(try container.decode(LGCBinaryExpression.self, forKey: .data))
      case "identifierExpression":
        self = .identifierExpression(try container.decode(LGCIdentifierExpression.self, forKey: .data))
      case "functionCallExpression":
        self = .functionCallExpression(try container.decode(LGCFunctionCallExpression.self, forKey: .data))
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

public indirect enum LGCBinaryOperator: Codable & Equatable {
  case isEqualTo(LGCIsEqualTo)
  case isNotEqualTo(LGCIsNotEqualTo)
  case isLessThan(LGCIsLessThan)
  case isGreaterThan(LGCIsGreaterThan)
  case isLessThanOrEqualTo(LGCIsLessThanOrEqualTo)
  case isGreaterThanOrEqualTo(LGCIsGreaterThanOrEqualTo)
  case setEqualTo(LGCSetEqualTo)

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
        self = .isEqualTo(try container.decode(LGCIsEqualTo.self, forKey: .data))
      case "isNotEqualTo":
        self = .isNotEqualTo(try container.decode(LGCIsNotEqualTo.self, forKey: .data))
      case "isLessThan":
        self = .isLessThan(try container.decode(LGCIsLessThan.self, forKey: .data))
      case "isGreaterThan":
        self = .isGreaterThan(try container.decode(LGCIsGreaterThan.self, forKey: .data))
      case "isLessThanOrEqualTo":
        self = .isLessThanOrEqualTo(try container.decode(LGCIsLessThanOrEqualTo.self, forKey: .data))
      case "isGreaterThanOrEqualTo":
        self = .isGreaterThanOrEqualTo(try container.decode(LGCIsGreaterThanOrEqualTo.self, forKey: .data))
      case "setEqualTo":
        self = .setEqualTo(try container.decode(LGCSetEqualTo.self, forKey: .data))
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
