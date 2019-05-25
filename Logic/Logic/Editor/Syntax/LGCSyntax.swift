import AppKit

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

public struct LGCIdentifier: Codable & Equatable {
  public init(id: UUID, string: String, isPlaceholder: Bool) {
    self.id = id
    self.string = string
    self.isPlaceholder = isPlaceholder
  }

  public var id: UUID
  public var string: String
  public var isPlaceholder: Bool
}

public indirect enum LGCDeclaration: Codable & Equatable {
  case variable(id: UUID, name: LGCPattern, annotation: Optional<LGCTypeAnnotation>, initializer: Optional<LGCExpression>)
  case function(id: UUID, name: LGCPattern, returnType: LGCTypeAnnotation, parameters: LGCList<LGCFunctionParameter>, block: LGCList<LGCStatement>)
  case enumeration(id: UUID, name: LGCPattern, cases: LGCList<LGCEnumerationCase>)
  case namespace(id: UUID, name: LGCPattern, declarations: LGCList<LGCDeclaration>)
  case placeholder(id: UUID)

  // MARK: Codable

  public enum CodingKeys: CodingKey {
    case type
    case data
  }

  public enum DataCodingKeys: CodingKey {
    case id
    case name
    case annotation
    case initializer
    case returnType
    case parameters
    case block
    case cases
    case declarations
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
      case "variable":
        self =
          .variable(
            id: try data.decode(UUID.self, forKey: .id),
            name: try data.decode(LGCPattern.self, forKey: .name),
            annotation: try data.decode(Optional.self, forKey: .annotation),
            initializer: try data.decode(Optional.self, forKey: .initializer))
      case "function":
        self =
          .function(
            id: try data.decode(UUID.self, forKey: .id),
            name: try data.decode(LGCPattern.self, forKey: .name),
            returnType: try data.decode(LGCTypeAnnotation.self, forKey: .returnType),
            parameters: try data.decode(LGCList.self, forKey: .parameters),
            block: try data.decode(LGCList.self, forKey: .block))
      case "enumeration":
        self =
          .enumeration(
            id: try data.decode(UUID.self, forKey: .id),
            name: try data.decode(LGCPattern.self, forKey: .name),
            cases: try data.decode(LGCList.self, forKey: .cases))
      case "namespace":
        self =
          .namespace(
            id: try data.decode(UUID.self, forKey: .id),
            name: try data.decode(LGCPattern.self, forKey: .name),
            declarations: try data.decode(LGCList.self, forKey: .declarations))
      case "placeholder":
        self = .placeholder(id: try data.decode(UUID.self, forKey: .id))
      default:
        fatalError("Failed to decode enum due to invalid case type.")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    var data = container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)

    switch self {
      case .variable(let value):
        try container.encode("variable", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.name, forKey: .name)
        try data.encode(value.annotation, forKey: .annotation)
        try data.encode(value.initializer, forKey: .initializer)
      case .function(let value):
        try container.encode("function", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.name, forKey: .name)
        try data.encode(value.returnType, forKey: .returnType)
        try data.encode(value.parameters, forKey: .parameters)
        try data.encode(value.block, forKey: .block)
      case .enumeration(let value):
        try container.encode("enumeration", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.name, forKey: .name)
        try data.encode(value.cases, forKey: .cases)
      case .namespace(let value):
        try container.encode("namespace", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.name, forKey: .name)
        try data.encode(value.declarations, forKey: .declarations)
      case .placeholder(let value):
        try container.encode("placeholder", forKey: .type)
        try data.encode(value, forKey: .id)
    }
  }
}

public indirect enum LGCEnumerationCase: Codable & Equatable {
  case placeholder(id: UUID)
  case enumerationCase(id: UUID, name: LGCPattern, associatedValueTypes: LGCList<LGCTypeAnnotation>)

  // MARK: Codable

  public enum CodingKeys: CodingKey {
    case type
    case data
  }

  public enum DataCodingKeys: CodingKey {
    case id
    case name
    case associatedValueTypes
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
      case "placeholder":
        self = .placeholder(id: try data.decode(UUID.self, forKey: .id))
      case "enumerationCase":
        self =
          .enumerationCase(
            id: try data.decode(UUID.self, forKey: .id),
            name: try data.decode(LGCPattern.self, forKey: .name),
            associatedValueTypes: try data.decode(LGCList.self, forKey: .associatedValueTypes))
      default:
        fatalError("Failed to decode enum due to invalid case type.")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    var data = container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)

    switch self {
      case .placeholder(let value):
        try container.encode("placeholder", forKey: .type)
        try data.encode(value, forKey: .id)
      case .enumerationCase(let value):
        try container.encode("enumerationCase", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.name, forKey: .name)
        try data.encode(value.associatedValueTypes, forKey: .associatedValueTypes)
    }
  }
}

public struct LGCPattern: Codable & Equatable {
  public init(id: UUID, name: String) {
    self.id = id
    self.name = name
  }

  public var id: UUID
  public var name: String
}

public indirect enum LGCBinaryOperator: Codable & Equatable {
  case isEqualTo(id: UUID)
  case isNotEqualTo(id: UUID)
  case isLessThan(id: UUID)
  case isGreaterThan(id: UUID)
  case isLessThanOrEqualTo(id: UUID)
  case isGreaterThanOrEqualTo(id: UUID)
  case setEqualTo(id: UUID)

  // MARK: Codable

  public enum CodingKeys: CodingKey {
    case type
    case data
  }

  public enum DataCodingKeys: CodingKey {
    case id
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
      case "isEqualTo":
        self = .isEqualTo(id: try data.decode(UUID.self, forKey: .id))
      case "isNotEqualTo":
        self = .isNotEqualTo(id: try data.decode(UUID.self, forKey: .id))
      case "isLessThan":
        self = .isLessThan(id: try data.decode(UUID.self, forKey: .id))
      case "isGreaterThan":
        self = .isGreaterThan(id: try data.decode(UUID.self, forKey: .id))
      case "isLessThanOrEqualTo":
        self = .isLessThanOrEqualTo(id: try data.decode(UUID.self, forKey: .id))
      case "isGreaterThanOrEqualTo":
        self = .isGreaterThanOrEqualTo(id: try data.decode(UUID.self, forKey: .id))
      case "setEqualTo":
        self = .setEqualTo(id: try data.decode(UUID.self, forKey: .id))
      default:
        fatalError("Failed to decode enum due to invalid case type.")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    var data = container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)

    switch self {
      case .isEqualTo(let value):
        try container.encode("isEqualTo", forKey: .type)
        try data.encode(value, forKey: .id)
      case .isNotEqualTo(let value):
        try container.encode("isNotEqualTo", forKey: .type)
        try data.encode(value, forKey: .id)
      case .isLessThan(let value):
        try container.encode("isLessThan", forKey: .type)
        try data.encode(value, forKey: .id)
      case .isGreaterThan(let value):
        try container.encode("isGreaterThan", forKey: .type)
        try data.encode(value, forKey: .id)
      case .isLessThanOrEqualTo(let value):
        try container.encode("isLessThanOrEqualTo", forKey: .type)
        try data.encode(value, forKey: .id)
      case .isGreaterThanOrEqualTo(let value):
        try container.encode("isGreaterThanOrEqualTo", forKey: .type)
        try data.encode(value, forKey: .id)
      case .setEqualTo(let value):
        try container.encode("setEqualTo", forKey: .type)
        try data.encode(value, forKey: .id)
    }
  }
}

public struct LGCFunctionCallArgument: Codable & Equatable {
  public init(id: UUID, label: Optional<String>, expression: LGCExpression) {
    self.id = id
    self.label = label
    self.expression = expression
  }

  public var id: UUID
  public var label: Optional<String>
  public var expression: LGCExpression
}

public indirect enum LGCExpression: Codable & Equatable {
  case binaryExpression(left: LGCExpression, right: LGCExpression, op: LGCBinaryOperator, id: UUID)
  case identifierExpression(id: UUID, identifier: LGCIdentifier)
  case functionCallExpression(id: UUID, expression: LGCExpression, arguments: LGCList<LGCFunctionCallArgument>)
  case literalExpression(id: UUID, literal: LGCLiteral)
  case memberExpression(id: UUID, expression: LGCExpression, memberName: LGCIdentifier)

  // MARK: Codable

  public enum CodingKeys: CodingKey {
    case type
    case data
  }

  public enum DataCodingKeys: CodingKey {
    case left
    case right
    case op
    case id
    case identifier
    case expression
    case arguments
    case literal
    case memberName
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
      case "binaryExpression":
        self =
          .binaryExpression(
            left: try data.decode(LGCExpression.self, forKey: .left),
            right: try data.decode(LGCExpression.self, forKey: .right),
            op: try data.decode(LGCBinaryOperator.self, forKey: .op),
            id: try data.decode(UUID.self, forKey: .id))
      case "identifierExpression":
        self =
          .identifierExpression(
            id: try data.decode(UUID.self, forKey: .id),
            identifier: try data.decode(LGCIdentifier.self, forKey: .identifier))
      case "functionCallExpression":
        self =
          .functionCallExpression(
            id: try data.decode(UUID.self, forKey: .id),
            expression: try data.decode(LGCExpression.self, forKey: .expression),
            arguments: try data.decode(LGCList.self, forKey: .arguments))
      case "literalExpression":
        self =
          .literalExpression(
            id: try data.decode(UUID.self, forKey: .id),
            literal: try data.decode(LGCLiteral.self, forKey: .literal))
      case "memberExpression":
        self =
          .memberExpression(
            id: try data.decode(UUID.self, forKey: .id),
            expression: try data.decode(LGCExpression.self, forKey: .expression),
            memberName: try data.decode(LGCIdentifier.self, forKey: .memberName))
      default:
        fatalError("Failed to decode enum due to invalid case type.")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    var data = container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)

    switch self {
      case .binaryExpression(let value):
        try container.encode("binaryExpression", forKey: .type)
        try data.encode(value.left, forKey: .left)
        try data.encode(value.right, forKey: .right)
        try data.encode(value.op, forKey: .op)
        try data.encode(value.id, forKey: .id)
      case .identifierExpression(let value):
        try container.encode("identifierExpression", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.identifier, forKey: .identifier)
      case .functionCallExpression(let value):
        try container.encode("functionCallExpression", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.expression, forKey: .expression)
        try data.encode(value.arguments, forKey: .arguments)
      case .literalExpression(let value):
        try container.encode("literalExpression", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.literal, forKey: .literal)
      case .memberExpression(let value):
        try container.encode("memberExpression", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.expression, forKey: .expression)
        try data.encode(value.memberName, forKey: .memberName)
    }
  }
}

public indirect enum LGCStatement: Codable & Equatable {
  case loop(pattern: LGCPattern, expression: LGCExpression, block: LGCList<LGCStatement>, id: UUID)
  case branch(id: UUID, condition: LGCExpression, block: LGCList<LGCStatement>)
  case declaration(id: UUID, content: LGCDeclaration)
  case expressionStatement(id: UUID, expression: LGCExpression)
  case placeholderStatement(id: UUID)

  // MARK: Codable

  public enum CodingKeys: CodingKey {
    case type
    case data
  }

  public enum DataCodingKeys: CodingKey {
    case pattern
    case expression
    case block
    case id
    case condition
    case content
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
      case "loop":
        self =
          .loop(
            pattern: try data.decode(LGCPattern.self, forKey: .pattern),
            expression: try data.decode(LGCExpression.self, forKey: .expression),
            block: try data.decode(LGCList.self, forKey: .block),
            id: try data.decode(UUID.self, forKey: .id))
      case "branch":
        self =
          .branch(
            id: try data.decode(UUID.self, forKey: .id),
            condition: try data.decode(LGCExpression.self, forKey: .condition),
            block: try data.decode(LGCList.self, forKey: .block))
      case "declaration":
        self =
          .declaration(
            id: try data.decode(UUID.self, forKey: .id),
            content: try data.decode(LGCDeclaration.self, forKey: .content))
      case "expressionStatement":
        self =
          .expressionStatement(
            id: try data.decode(UUID.self, forKey: .id),
            expression: try data.decode(LGCExpression.self, forKey: .expression))
      case "placeholderStatement":
        self = .placeholderStatement(id: try data.decode(UUID.self, forKey: .id))
      default:
        fatalError("Failed to decode enum due to invalid case type.")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    var data = container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)

    switch self {
      case .loop(let value):
        try container.encode("loop", forKey: .type)
        try data.encode(value.pattern, forKey: .pattern)
        try data.encode(value.expression, forKey: .expression)
        try data.encode(value.block, forKey: .block)
        try data.encode(value.id, forKey: .id)
      case .branch(let value):
        try container.encode("branch", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.condition, forKey: .condition)
        try data.encode(value.block, forKey: .block)
      case .declaration(let value):
        try container.encode("declaration", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.content, forKey: .content)
      case .expressionStatement(let value):
        try container.encode("expressionStatement", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.expression, forKey: .expression)
      case .placeholderStatement(let value):
        try container.encode("placeholderStatement", forKey: .type)
        try data.encode(value, forKey: .id)
    }
  }
}

public struct LGCProgram: Codable & Equatable {
  public init(id: UUID, block: LGCList<LGCStatement>) {
    self.id = id
    self.block = block
  }

  public var id: UUID
  public var block: LGCList<LGCStatement>
}

public indirect enum LGCSyntaxNode: Codable & Equatable {
  case statement(LGCStatement)
  case declaration(LGCDeclaration)
  case identifier(LGCIdentifier)
  case expression(LGCExpression)
  case pattern(LGCPattern)
  case binaryOperator(LGCBinaryOperator)
  case program(LGCProgram)
  case functionParameter(LGCFunctionParameter)
  case functionParameterDefaultValue(LGCFunctionParameterDefaultValue)
  case typeAnnotation(LGCTypeAnnotation)
  case literal(LGCLiteral)
  case topLevelParameters(LGCTopLevelParameters)
  case enumerationCase(LGCEnumerationCase)

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
      case "functionParameter":
        self = .functionParameter(try container.decode(LGCFunctionParameter.self, forKey: .data))
      case "functionParameterDefaultValue":
        self =
          .functionParameterDefaultValue(try container.decode(LGCFunctionParameterDefaultValue.self, forKey: .data))
      case "typeAnnotation":
        self = .typeAnnotation(try container.decode(LGCTypeAnnotation.self, forKey: .data))
      case "literal":
        self = .literal(try container.decode(LGCLiteral.self, forKey: .data))
      case "topLevelParameters":
        self = .topLevelParameters(try container.decode(LGCTopLevelParameters.self, forKey: .data))
      case "enumerationCase":
        self = .enumerationCase(try container.decode(LGCEnumerationCase.self, forKey: .data))
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
      case .functionParameter(let value):
        try container.encode("functionParameter", forKey: .type)
        try container.encode(value, forKey: .data)
      case .functionParameterDefaultValue(let value):
        try container.encode("functionParameterDefaultValue", forKey: .type)
        try container.encode(value, forKey: .data)
      case .typeAnnotation(let value):
        try container.encode("typeAnnotation", forKey: .type)
        try container.encode(value, forKey: .data)
      case .literal(let value):
        try container.encode("literal", forKey: .type)
        try container.encode(value, forKey: .data)
      case .topLevelParameters(let value):
        try container.encode("topLevelParameters", forKey: .type)
        try container.encode(value, forKey: .data)
      case .enumerationCase(let value):
        try container.encode("enumerationCase", forKey: .type)
        try container.encode(value, forKey: .data)
    }
  }
}

public indirect enum LGCFunctionParameter: Codable & Equatable {
  case parameter(id: UUID, externalName: Optional<String>, localName: LGCPattern, annotation: LGCTypeAnnotation, defaultValue: LGCFunctionParameterDefaultValue)
  case placeholder(id: UUID)

  // MARK: Codable

  public enum CodingKeys: CodingKey {
    case type
    case data
  }

  public enum DataCodingKeys: CodingKey {
    case id
    case externalName
    case localName
    case annotation
    case defaultValue
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
      case "parameter":
        self =
          .parameter(
            id: try data.decode(UUID.self, forKey: .id),
            externalName: try data.decode(Optional.self, forKey: .externalName),
            localName: try data.decode(LGCPattern.self, forKey: .localName),
            annotation: try data.decode(LGCTypeAnnotation.self, forKey: .annotation),
            defaultValue: try data.decode(LGCFunctionParameterDefaultValue.self, forKey: .defaultValue))
      case "placeholder":
        self = .placeholder(id: try data.decode(UUID.self, forKey: .id))
      default:
        fatalError("Failed to decode enum due to invalid case type.")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    var data = container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)

    switch self {
      case .parameter(let value):
        try container.encode("parameter", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.externalName, forKey: .externalName)
        try data.encode(value.localName, forKey: .localName)
        try data.encode(value.annotation, forKey: .annotation)
        try data.encode(value.defaultValue, forKey: .defaultValue)
      case .placeholder(let value):
        try container.encode("placeholder", forKey: .type)
        try data.encode(value, forKey: .id)
    }
  }
}

public indirect enum LGCFunctionParameterDefaultValue: Codable & Equatable {
  case none(id: UUID)
  case value(id: UUID, expression: LGCExpression)

  // MARK: Codable

  public enum CodingKeys: CodingKey {
    case type
    case data
  }

  public enum DataCodingKeys: CodingKey {
    case id
    case expression
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
      case "none":
        self = .none(id: try data.decode(UUID.self, forKey: .id))
      case "value":
        self =
          .value(
            id: try data.decode(UUID.self, forKey: .id),
            expression: try data.decode(LGCExpression.self, forKey: .expression))
      default:
        fatalError("Failed to decode enum due to invalid case type.")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    var data = container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)

    switch self {
      case .none(let value):
        try container.encode("none", forKey: .type)
        try data.encode(value, forKey: .id)
      case .value(let value):
        try container.encode("value", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.expression, forKey: .expression)
    }
  }
}

public indirect enum LGCTypeAnnotation: Codable & Equatable {
  case typeIdentifier(id: UUID, identifier: LGCIdentifier, genericArguments: LGCList<LGCTypeAnnotation>)
  case functionType(id: UUID, returnType: LGCTypeAnnotation, argumentTypes: LGCList<LGCTypeAnnotation>)
  case placeholder(id: UUID)

  // MARK: Codable

  public enum CodingKeys: CodingKey {
    case type
    case data
  }

  public enum DataCodingKeys: CodingKey {
    case id
    case identifier
    case genericArguments
    case returnType
    case argumentTypes
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
      case "typeIdentifier":
        self =
          .typeIdentifier(
            id: try data.decode(UUID.self, forKey: .id),
            identifier: try data.decode(LGCIdentifier.self, forKey: .identifier),
            genericArguments: try data.decode(LGCList.self, forKey: .genericArguments))
      case "functionType":
        self =
          .functionType(
            id: try data.decode(UUID.self, forKey: .id),
            returnType: try data.decode(LGCTypeAnnotation.self, forKey: .returnType),
            argumentTypes: try data.decode(LGCList.self, forKey: .argumentTypes))
      case "placeholder":
        self = .placeholder(id: try data.decode(UUID.self, forKey: .id))
      default:
        fatalError("Failed to decode enum due to invalid case type.")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    var data = container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)

    switch self {
      case .typeIdentifier(let value):
        try container.encode("typeIdentifier", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.identifier, forKey: .identifier)
        try data.encode(value.genericArguments, forKey: .genericArguments)
      case .functionType(let value):
        try container.encode("functionType", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.returnType, forKey: .returnType)
        try data.encode(value.argumentTypes, forKey: .argumentTypes)
      case .placeholder(let value):
        try container.encode("placeholder", forKey: .type)
        try data.encode(value, forKey: .id)
    }
  }
}

public indirect enum LGCLiteral: Codable & Equatable {
  case none(id: UUID)
  case boolean(id: UUID, value: Bool)
  case number(id: UUID, value: CGFloat)
  case string(id: UUID, value: String)
  case color(id: UUID, value: String)

  // MARK: Codable

  public enum CodingKeys: CodingKey {
    case type
    case data
  }

  public enum DataCodingKeys: CodingKey {
    case id
    case value
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
      case "none":
        self = .none(id: try data.decode(UUID.self, forKey: .id))
      case "boolean":
        self = .boolean(id: try data.decode(UUID.self, forKey: .id), value: try data.decode(Bool.self, forKey: .value))
      case "number":
        self =
          .number(id: try data.decode(UUID.self, forKey: .id), value: try data.decode(CGFloat.self, forKey: .value))
      case "string":
        self = .string(id: try data.decode(UUID.self, forKey: .id), value: try data.decode(String.self, forKey: .value))
      case "color":
        self = .color(id: try data.decode(UUID.self, forKey: .id), value: try data.decode(String.self, forKey: .value))
      default:
        fatalError("Failed to decode enum due to invalid case type.")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    var data = container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)

    switch self {
      case .none(let value):
        try container.encode("none", forKey: .type)
        try data.encode(value, forKey: .id)
      case .boolean(let value):
        try container.encode("boolean", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.value, forKey: .value)
      case .number(let value):
        try container.encode("number", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.value, forKey: .value)
      case .string(let value):
        try container.encode("string", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.value, forKey: .value)
      case .color(let value):
        try container.encode("color", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.value, forKey: .value)
    }
  }
}

public struct LGCTopLevelParameters: Codable & Equatable {
  public init(id: UUID, parameters: LGCList<LGCFunctionParameter>) {
    self.id = id
    self.parameters = parameters
  }

  public var id: UUID
  public var parameters: LGCList<LGCFunctionParameter>
}
