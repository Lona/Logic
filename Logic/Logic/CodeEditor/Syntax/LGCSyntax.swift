import Foundation

public protocol Equivalentable {
  func isEquivalentTo(_ node: Self) -> Bool
}

extension Optional: Equivalentable where Wrapped: Equivalentable {
  public func isEquivalentTo(_ node: Self) -> Bool {
    switch (self, node) {
    case (.none, .none):
        return true
    case (.some(let a), .some(let b)):
      return a.isEquivalentTo(b)
    default:
      return false
    }
  }
}

public struct LGCComment: Codable & Equatable & Equivalentable {
  public init(id: UUID, string: String) {
    self.id = id
    self.string = string
  }

  public var id: UUID
  public var string: String

  public func isEquivalentTo(_ node: LGCComment) -> Bool {
    return self.string == node.string
  }
}


public indirect enum LGCEnumerationCase: Codable & Equatable & Equivalentable {
  case placeholder(id: UUID)
  case enumerationCase(id: UUID, name: LGCPattern, associatedValueTypes: LGCList<LGCTypeAnnotation>, comment: Optional<LGCComment>)

  // MARK: Codable

  public enum CodingKeys: CodingKey {
    case type
    case data
  }

  public enum DataCodingKeys: CodingKey {
    case id
    case name
    case associatedValueTypes
    case comment
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
            associatedValueTypes: try data.decode(LGCList.self, forKey: .associatedValueTypes),
            comment: try data.decodeIfPresent(LGCComment.self, forKey: .comment))
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
        try data.encodeIfPresent(value.comment, forKey: .comment)
    }
  }


  public func isEquivalentTo(_ node: LGCEnumerationCase) -> Bool {
    switch (self, node) {
      case (.placeholder, .placeholder):
        return true
      case (.enumerationCase(let a), .enumerationCase(let b)):
        return a.name.isEquivalentTo(b.name) && a.associatedValueTypes.isEquivalentTo(b.associatedValueTypes) && a.comment.isEquivalentTo(b.comment)
      default:
        return false
    }
  }
}

extension LGCEnumerationCase: SyntaxNodePlaceholdable {
  public var isPlaceholder: Bool {
    switch self {
    case .placeholder:
      return true
    default:
      return false
    }
  }

  public static func makePlaceholder() -> LGCEnumerationCase {
    return .placeholder(id: UUID())
  }
}


public indirect enum LGCFunctionCallArgument: Codable & Equatable & Equivalentable {
  case argument(id: UUID, label: Optional<String>, expression: LGCExpression)
  case placeholder(id: UUID)

  // MARK: Codable

  public enum CodingKeys: CodingKey {
    case type
    case data
  }

  public enum DataCodingKeys: CodingKey {
    case id
    case label
    case expression
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
      case "argument":
        self =
          .argument(
            id: try data.decode(UUID.self, forKey: .id),
            label: try data.decodeIfPresent(String.self, forKey: .label),
            expression: try data.decode(LGCExpression.self, forKey: .expression))
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
      case .argument(let value):
        try container.encode("argument", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encodeIfPresent(value.label, forKey: .label)
        try data.encode(value.expression, forKey: .expression)
      case .placeholder(let value):
        try container.encode("placeholder", forKey: .type)
        try data.encode(value, forKey: .id)
    }
  }

  public func isEquivalentTo(_ node: LGCFunctionCallArgument) -> Bool {
    switch (self, node) {
      case (.placeholder, .placeholder):
        return true
      case (.argument(let a), .argument(let b)):
        return a.expression.isEquivalentTo(b.expression) && (a.label ?? "") == (b.label ?? "")
      default:
        return false
    }
  }
}

extension LGCFunctionCallArgument: SyntaxNodePlaceholdable {
  public var isPlaceholder: Bool {
    switch self {
    case .placeholder:
      return true
    default:
      return false
    }
  }

  public static func makePlaceholder() -> LGCFunctionCallArgument {
    return .placeholder(id: UUID())
  }
}


public indirect enum LGCFunctionParameter: Codable & Equatable & Equivalentable {
  case parameter(id: UUID, localName: LGCPattern, annotation: LGCTypeAnnotation, defaultValue: LGCFunctionParameterDefaultValue, comment: Optional<LGCComment>)
  case placeholder(id: UUID)

  // MARK: Codable

  public enum CodingKeys: CodingKey {
    case type
    case data
  }

  public enum DataCodingKeys: CodingKey {
    case id
    case localName
    case annotation
    case defaultValue
    case comment
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
            localName: try data.decode(LGCPattern.self, forKey: .localName),
            annotation: try data.decode(LGCTypeAnnotation.self, forKey: .annotation),
            defaultValue: try data.decode(LGCFunctionParameterDefaultValue.self, forKey: .defaultValue),
            comment: try data.decodeIfPresent(LGCComment.self, forKey: .comment))
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
        try data.encode(value.localName, forKey: .localName)
        try data.encode(value.annotation, forKey: .annotation)
        try data.encode(value.defaultValue, forKey: .defaultValue)
        try data.encodeIfPresent(value.comment, forKey: .comment)
      case .placeholder(let value):
        try container.encode("placeholder", forKey: .type)
        try data.encode(value, forKey: .id)
    }
  }

  public func isEquivalentTo(_ node: LGCFunctionParameter) -> Bool {
    switch (self, node) {
      case (.placeholder, .placeholder):
        return true
      case (.parameter(let a), .parameter(let b)):
        return a.localName.isEquivalentTo(b.localName) && a.annotation.isEquivalentTo(b.annotation) && a.defaultValue.isEquivalentTo(b.defaultValue) && a.comment.isEquivalentTo(b.comment)
      default:
        return false
    }
  }
}

extension LGCFunctionParameter: SyntaxNodePlaceholdable {
  public var isPlaceholder: Bool {
    switch self {
    case .placeholder:
      return true
    default:
      return false
    }
  }

  public static func makePlaceholder() -> LGCFunctionParameter {
    return .placeholder(id: UUID())
  }
}


public indirect enum LGCFunctionParameterDefaultValue: Codable & Equatable & Equivalentable {
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

  public func isEquivalentTo(_ node: LGCFunctionParameterDefaultValue) -> Bool {
    switch (self, node) {
      case (.none, .none):
        return true
      case (.value(let a), .value(let b)):
        return a.expression.isEquivalentTo(b.expression)
      default:
        return false
    }
  }
}


public indirect enum LGCGenericParameter: Codable & Equatable & Equivalentable {
  case parameter(id: UUID, name: LGCPattern)
  case placeholder(id: UUID)

  // MARK: Codable

  public enum CodingKeys: CodingKey {
    case type
    case data
  }

  public enum DataCodingKeys: CodingKey {
    case id
    case name
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
      case "parameter":
        self =
          .parameter(id: try data.decode(UUID.self, forKey: .id), name: try data.decode(LGCPattern.self, forKey: .name))
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
        try data.encode(value.name, forKey: .name)
      case .placeholder(let value):
        try container.encode("placeholder", forKey: .type)
        try data.encode(value, forKey: .id)
    }
  }

  public func isEquivalentTo(_ node: LGCGenericParameter) -> Bool {
    switch (self, node) {
      case (.placeholder, .placeholder):
        return true
      case (.parameter(let a), .parameter(let b)):
        return a.name.isEquivalentTo(b.name)
      default:
        return false
    }
  }
}

extension LGCGenericParameter: SyntaxNodePlaceholdable {
  public var isPlaceholder: Bool {
    switch self {
    case .placeholder:
      return true
    default:
      return false
    }
  }

  public static func makePlaceholder() -> LGCGenericParameter {
    return .placeholder(id: UUID())
  }
}


public struct LGCIdentifier: Codable & Equatable & Equivalentable {
  public init(id: UUID, string: String, isPlaceholder: Bool) {
    self.id = id
    self.string = string
    self.isPlaceholder = isPlaceholder
  }

  public var id: UUID
  public var string: String
  public var isPlaceholder: Bool

  public func isEquivalentTo(_ node: LGCIdentifier) -> Bool {
    return self.string == node.string && self.isPlaceholder == node.isPlaceholder
  }
}


public indirect enum LGCList<T: Equatable & Codable & Equivalentable>: Codable & Equatable & Equivalentable {
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

  public func isEquivalentTo(_ node: LGCList<T>) -> Bool {
    switch (self, node) {
      case (.empty, .empty):
        return true
      case (.next(let a, let restA), .next(let b, let restB)):
        return a.isEquivalentTo(b) && restA.isEquivalentTo(restB)
      default:
        return false
    }
  }
}

extension LGCList where T: SyntaxNodePlaceholdable {
  public func isEquivalentTo(_ node: Optional<LGCList<T>>) -> Bool {
    guard let node = node else { return false }
    switch (self, node) {
      case (.empty, .empty):
        return true
      case (.empty,  .next(let b, let restB)):
        return b.isPlaceholder && self.isEquivalentTo(restB)
      case (.next(let a, let restA), .empty):
        return a.isPlaceholder && node.isEquivalentTo(restA)
      case (.next(let a, let restA), .next(let b, let restB)):
        return a.isEquivalentTo(b) && restA.isEquivalentTo(restB)
    }
  }
}


public struct LGCPattern: Codable & Equatable & Equivalentable {
  public init(id: UUID, name: String) {
    self.id = id
    self.name = name
  }

  public var id: UUID
  public var name: String

  public func isEquivalentTo(_ node: LGCPattern) -> Bool {
    return self.name == node.name
  }
}


public protocol SyntaxNodePlaceholdable {
  var isPlaceholder: Bool { get }
  static func makePlaceholder() -> Self
}


public struct LGCProgram: Codable & Equatable & Equivalentable {
  public init(id: UUID, block: LGCList<LGCStatement>) {
    self.id = id
    self.block = block
  }

  public var id: UUID
  public var block: LGCList<LGCStatement>

  public func isEquivalentTo(_ node: LGCProgram) -> Bool {
    return self.block.isEquivalentTo(node.block)
  }
}

public struct LGCTopLevelDeclarations: Codable & Equatable & Equivalentable {
  public init(id: UUID, declarations: LGCList<LGCDeclaration>) {
    self.id = id
    self.declarations = declarations
  }

  public var id: UUID
  public var declarations: LGCList<LGCDeclaration>

  public func isEquivalentTo(_ node: LGCTopLevelDeclarations) -> Bool {
    return self.declarations.isEquivalentTo(node.declarations)
  }
}

public struct LGCTopLevelParameters: Codable & Equatable & Equivalentable {
  public init(id: UUID, parameters: LGCList<LGCFunctionParameter>) {
    self.id = id
    self.parameters = parameters
  }

  public var id: UUID
  public var parameters: LGCList<LGCFunctionParameter>

  public func isEquivalentTo(_ node: LGCTopLevelParameters) -> Bool {
    return self.parameters.isEquivalentTo(node.parameters)
  }
}


public indirect enum LGCDeclaration: Codable & Equatable & Equivalentable {
  case enumeration(id: UUID, name: LGCPattern, genericParameters: LGCList<LGCGenericParameter>, cases: LGCList<LGCEnumerationCase>, comment: Optional<LGCComment>)
  case function(id: UUID, name: LGCPattern, returnType: LGCTypeAnnotation, genericParameters: LGCList<LGCGenericParameter>, parameters: LGCList<LGCFunctionParameter>, block: LGCList<LGCStatement>, comment: Optional<LGCComment>)
  case importDeclaration(id: UUID, name: LGCPattern)
  case namespace(id: UUID, name: LGCPattern, declarations: LGCList<LGCDeclaration>)
  case record(id: UUID, name: LGCPattern, genericParameters: LGCList<LGCGenericParameter>, declarations: LGCList<LGCDeclaration>, comment: Optional<LGCComment>)
  case variable(id: UUID, name: LGCPattern, annotation: Optional<LGCTypeAnnotation>, initializer: Optional<LGCExpression>, comment: Optional<LGCComment>)
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
    case comment
    case returnType
    case genericParameters
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
            annotation: try data.decodeIfPresent(LGCTypeAnnotation.self, forKey: .annotation),
            initializer: try data.decodeIfPresent(LGCExpression.self, forKey: .initializer),
            comment: try data.decodeIfPresent(LGCComment.self, forKey: .comment))
      case "function":
        self =
          .function(
            id: try data.decode(UUID.self, forKey: .id),
            name: try data.decode(LGCPattern.self, forKey: .name),
            returnType: try data.decode(LGCTypeAnnotation.self, forKey: .returnType),
            genericParameters: try data.decode(LGCList.self, forKey: .genericParameters),
            parameters: try data.decode(LGCList.self, forKey: .parameters),
            block: try data.decode(LGCList.self, forKey: .block),
            comment: try data.decodeIfPresent(LGCComment.self, forKey: .comment))
      case "enumeration":
        self =
          .enumeration(
            id: try data.decode(UUID.self, forKey: .id),
            name: try data.decode(LGCPattern.self, forKey: .name),
            genericParameters: try data.decode(LGCList.self, forKey: .genericParameters),
            cases: try data.decode(LGCList.self, forKey: .cases),
            comment: try data.decodeIfPresent(LGCComment.self, forKey: .comment))
      case "namespace":
        self =
          .namespace(
            id: try data.decode(UUID.self, forKey: .id),
            name: try data.decode(LGCPattern.self, forKey: .name),
            declarations: try data.decode(LGCList.self, forKey: .declarations))
      case "placeholder":
        self = .placeholder(id: try data.decode(UUID.self, forKey: .id))
      case "record":
        self =
          .record(
            id: try data.decode(UUID.self, forKey: .id),
            name: try data.decode(LGCPattern.self, forKey: .name),
            genericParameters: try data.decode(LGCList.self, forKey: .genericParameters),
            declarations: try data.decode(LGCList.self, forKey: .declarations),
            comment: try data.decodeIfPresent(LGCComment.self, forKey: .comment))
      case "importDeclaration":
        self =
          .importDeclaration(
            id: try data.decode(UUID.self, forKey: .id),
            name: try data.decode(LGCPattern.self, forKey: .name))
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
        try data.encodeIfPresent(value.annotation, forKey: .annotation)
        try data.encodeIfPresent(value.initializer, forKey: .initializer)
        try data.encodeIfPresent(value.comment, forKey: .comment)
      case .function(let value):
        try container.encode("function", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.name, forKey: .name)
        try data.encode(value.returnType, forKey: .returnType)
        try data.encode(value.genericParameters, forKey: .genericParameters)
        try data.encode(value.parameters, forKey: .parameters)
        try data.encode(value.block, forKey: .block)
        try data.encodeIfPresent(value.comment, forKey: .comment)
      case .enumeration(let value):
        try container.encode("enumeration", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.name, forKey: .name)
        try data.encode(value.genericParameters, forKey: .genericParameters)
        try data.encode(value.cases, forKey: .cases)
        try data.encodeIfPresent(value.comment, forKey: .comment)
      case .namespace(let value):
        try container.encode("namespace", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.name, forKey: .name)
        try data.encode(value.declarations, forKey: .declarations)
      case .placeholder(let value):
        try container.encode("placeholder", forKey: .type)
        try data.encode(value, forKey: .id)
      case .record(let value):
        try container.encode("record", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.name, forKey: .name)
        try data.encode(value.genericParameters, forKey: .genericParameters)
        try data.encode(value.declarations, forKey: .declarations)
        try data.encodeIfPresent(value.comment, forKey: .comment)
      case .importDeclaration(let value):
        try container.encode("importDeclaration", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.name, forKey: .name)
    }
  }

  public func isEquivalentTo(_ node: LGCDeclaration) -> Bool {
    switch (self, node) {
      case (.placeholder, .placeholder):
        return true
      case (.variable(let a), .variable(let b)):
        return a.name.isEquivalentTo(b.name) && a.annotation.isEquivalentTo(b.annotation) && a.initializer.isEquivalentTo(b.initializer) && a.comment.isEquivalentTo(b.comment)
      case (.function(let a), .function(let b)):
        return a.name.isEquivalentTo(b.name) && a.returnType.isEquivalentTo(b.returnType) && a.genericParameters.isEquivalentTo(b.genericParameters) && a.parameters.isEquivalentTo(b.parameters) && a.block.isEquivalentTo(b.block) && a.comment.isEquivalentTo(b.comment)
      case (.enumeration(let a), .enumeration(let b)):
        return a.name.isEquivalentTo(b.name) && a.genericParameters.isEquivalentTo(b.genericParameters) && a.cases.isEquivalentTo(b.cases) && a.comment.isEquivalentTo(b.comment)
      case (.namespace(let a), .namespace(let b)):
        return a.name.isEquivalentTo(b.name) && a.declarations.isEquivalentTo(b.declarations)
      case (.record(let a), .record(let b)):
        return a.name.isEquivalentTo(b.name) && a.genericParameters.isEquivalentTo(b.genericParameters) && a.declarations.isEquivalentTo(b.declarations) && a.comment.isEquivalentTo(b.comment)
      case (.importDeclaration(let a), .importDeclaration(let b)):
        return a.name.isEquivalentTo(b.name)
      default:
        return false
    }
  }
}

extension LGCDeclaration: SyntaxNodePlaceholdable {
  public var isPlaceholder: Bool {
    switch self {
    case .placeholder:
      return true
    default:
      return false
    }
  }

  public static func makePlaceholder() -> LGCDeclaration {
    return .placeholder(id: UUID())
  }
}


public indirect enum LGCExpression: Codable & Equatable & Equivalentable {
  case assignmentExpression(left: LGCExpression, right: LGCExpression, id: UUID)
  case functionCallExpression(id: UUID, expression: LGCExpression, arguments: LGCList<LGCFunctionCallArgument>)
  case identifierExpression(id: UUID, identifier: LGCIdentifier)
  case literalExpression(id: UUID, literal: LGCLiteral)
  case memberExpression(id: UUID, expression: LGCExpression, memberName: LGCIdentifier)
  case placeholder(id: UUID)

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
      case "assignmentExpression":
        self =
          .assignmentExpression(
            left: try data.decode(LGCExpression.self, forKey: .left),
            right: try data.decode(LGCExpression.self, forKey: .right),
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
      case .assignmentExpression(let value):
        try container.encode("assignmentExpression", forKey: .type)
        try data.encode(value.left, forKey: .left)
        try data.encode(value.right, forKey: .right)
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
      case .placeholder(let value):
        try container.encode("placeholder", forKey: .type)
        try data.encode(value, forKey: .id)
    }
  }

  public func isEquivalentTo(_ node: LGCExpression) -> Bool {
    switch (self, node) {
      case (.placeholder, .placeholder):
        return true
      case (.assignmentExpression(let a), .assignmentExpression(let b)):
        return a.left.isEquivalentTo(b.left) && a.right.isEquivalentTo(b.right)
      case (.identifierExpression(let a), .identifierExpression(let b)):
        return a.identifier.isEquivalentTo(b.identifier)
      case (.functionCallExpression(let a), .functionCallExpression(let b)):
        return a.expression.isEquivalentTo(b.expression) && a.arguments.isEquivalentTo(b.arguments)
      case (.literalExpression(let a), .literalExpression(let b)):
        return a.literal.isEquivalentTo(b.literal)
      case (.memberExpression(let a), .memberExpression(let b)):
        return a.expression.isEquivalentTo(b.expression) && a.memberName.isEquivalentTo(b.memberName)
      default:
        return false
    }
  }
}

extension LGCExpression: SyntaxNodePlaceholdable {
  public var isPlaceholder: Bool {
    switch self {
    case .placeholder:
      return true
    default:
      return false
    }
  }

  public static func makePlaceholder() -> LGCExpression {
    return .placeholder(id: UUID())
  }
}


public indirect enum LGCLiteral: Codable & Equatable & Equivalentable {
  case none(id: UUID)
  case boolean(id: UUID, value: Bool)
  case number(id: UUID, value: CGFloat)
  case string(id: UUID, value: String)
  case color(id: UUID, value: String)
  case array(id: UUID, value: LGCList<LGCExpression>)

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
      case "array":
        self = .array(id: try data.decode(UUID.self, forKey: .id), value: try data.decode(LGCList.self, forKey: .value))
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
      case .array(let value):
        try container.encode("array", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.value, forKey: .value)
    }
  }

  public func isEquivalentTo(_ node: LGCLiteral) -> Bool {
    switch (self, node) {
      case (.none, .none):
        return true
      case (.boolean(let a), .boolean(let b)):
        return a.value == b.value
      case (.number(let a), .number(let b)):
        return a.value == b.value
      case (.string(let a), .string(let b)):
        return a.value == b.value
      case (.color(let a), .color(let b)):
        return a.value == b.value
      case (.array(let a), .array(let b)):
        return a.value.isEquivalentTo(b.value)
      default:
        return false
    }
  }
}


public indirect enum LGCStatement: Codable & Equatable & Equivalentable {
  case branch(id: UUID, condition: LGCExpression, block: LGCList<LGCStatement>)
  case declaration(id: UUID, content: LGCDeclaration)
  case expressionStatement(id: UUID, expression: LGCExpression)
  case loop(pattern: LGCPattern, expression: LGCExpression, block: LGCList<LGCStatement>, id: UUID)
  case returnStatement(id: UUID, expression: LGCExpression)
  case placeholder(id: UUID)

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
      case "return":
        self =
          .returnStatement(
            id: try data.decode(UUID.self, forKey: .id),
            expression: try data.decode(LGCExpression.self, forKey: .expression))
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
      case .returnStatement(let value):
        try container.encode("return", forKey: .type)
        try data.encode(value.id, forKey: .id)
        try data.encode(value.expression, forKey: .expression)
      case .placeholder(let value):
        try container.encode("placeholder", forKey: .type)
        try data.encode(value, forKey: .id)
    }
  }

  public func isEquivalentTo(_ node: LGCStatement) -> Bool {
    switch (self, node) {
      case (.placeholder, .placeholder):
        return true
      case (.loop(let a), .loop(let b)):
        return a.pattern.isEquivalentTo(b.pattern) && a.expression.isEquivalentTo(b.expression) && a.block.isEquivalentTo(b.block)
      case (.branch(let a), .branch(let b)):
        return a.condition.isEquivalentTo(b.condition) && a.block.isEquivalentTo(b.block)
      case (.declaration(let a), .declaration(let b)):
        return a.content.isEquivalentTo(b.content)
      case (.expressionStatement(let a), .expressionStatement(let b)):
        return a.expression.isEquivalentTo(b.expression)
      case (.returnStatement(let a), .returnStatement(let b)):
        return a.expression.isEquivalentTo(b.expression)
      default:
        return false
    }
  }
}

extension LGCStatement: SyntaxNodePlaceholdable {
  public var isPlaceholder: Bool {
    switch self {
    case .placeholder:
      return true
    case .declaration(let value):
      return value.content.isPlaceholder
    case .expressionStatement(let value):
      return value.expression.isPlaceholder
    default:
      return false
    }
  }

  public static func makePlaceholder() -> LGCStatement {
    return .placeholder(id: UUID())
  }
}


public indirect enum LGCTypeAnnotation: Codable & Equatable & Equivalentable {
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

  public func isEquivalentTo(_ node: LGCTypeAnnotation) -> Bool {
    switch (self, node) {
      case (.placeholder, .placeholder):
        return true
      case (.typeIdentifier(let a), .typeIdentifier(let b)):
        return a.identifier.isEquivalentTo(b.identifier) && a.genericArguments.isEquivalentTo(b.genericArguments)
      case (.functionType(let a), .functionType(let b)):
        return a.returnType.isEquivalentTo(b.returnType) && a.argumentTypes.isEquivalentTo(b.argumentTypes)
      default:
        return false
    }
  }
}

extension LGCTypeAnnotation: SyntaxNodePlaceholdable {
  public var isPlaceholder: Bool {
    switch self {
    case .placeholder:
      return true
    default:
      return false
    }
  }

  public static func makePlaceholder() -> LGCTypeAnnotation {
    return .placeholder(id: UUID())
  }
}


public indirect enum LGCSyntaxNode: Codable & Equatable & Equivalentable {
  case statement(LGCStatement)
  case declaration(LGCDeclaration)
  case identifier(LGCIdentifier)
  case expression(LGCExpression)
  case pattern(LGCPattern)
  case program(LGCProgram)
  case functionParameter(LGCFunctionParameter)
  case functionParameterDefaultValue(LGCFunctionParameterDefaultValue)
  case typeAnnotation(LGCTypeAnnotation)
  case literal(LGCLiteral)
  case topLevelParameters(LGCTopLevelParameters)
  case enumerationCase(LGCEnumerationCase)
  case genericParameter(LGCGenericParameter)
  case topLevelDeclarations(LGCTopLevelDeclarations)
  case comment(LGCComment)
  case functionCallArgument(LGCFunctionCallArgument)

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
      case "genericParameter":
        self = .genericParameter(try container.decode(LGCGenericParameter.self, forKey: .data))
      case "topLevelDeclarations":
        self = .topLevelDeclarations(try container.decode(LGCTopLevelDeclarations.self, forKey: .data))
      case "comment":
        self = .comment(try container.decode(LGCComment.self, forKey: .data))
      case "functionCallArgument":
        self = .functionCallArgument(try container.decode(LGCFunctionCallArgument.self, forKey: .data))
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
      case .genericParameter(let value):
        try container.encode("genericParameter", forKey: .type)
        try container.encode(value, forKey: .data)
      case .topLevelDeclarations(let value):
        try container.encode("topLevelDeclarations", forKey: .type)
        try container.encode(value, forKey: .data)
      case .comment(let value):
        try container.encode("comment", forKey: .type)
        try container.encode(value, forKey: .data)
      case .functionCallArgument(let value):
        try container.encode("functionCallArgument", forKey: .type)
        try container.encode(value, forKey: .data)
    }
  }

  public func isEquivalentTo(_ node: LGCSyntaxNode) -> Bool {
    switch (self, node) {
      case (.statement(let a), .statement(let b)):
        return a.isEquivalentTo(b)
      case (.declaration(let a), .declaration(let b)):
        return a.isEquivalentTo(b)
      case (.identifier(let a), .identifier(let b)):
        return a.isEquivalentTo(b)
      case (.expression(let a), .expression(let b)):
        return a.isEquivalentTo(b)
      case (.pattern(let a), .pattern(let b)):
        return a.isEquivalentTo(b)
      case (.program(let a), .program(let b)):
        return a.isEquivalentTo(b)
      case (.functionParameter(let a), .functionParameter(let b)):
        return a.isEquivalentTo(b)
      case (.functionParameterDefaultValue(let a), .functionParameterDefaultValue(let b)):
        return a.isEquivalentTo(b)
      case (.typeAnnotation(let a), .typeAnnotation(let b)):
        return a.isEquivalentTo(b)
      case (.literal(let a), .literal(let b)):
        return a.isEquivalentTo(b)
      case (.topLevelParameters(let a), .topLevelParameters(let b)):
        return a.isEquivalentTo(b)
      case (.enumerationCase(let a), .enumerationCase(let b)):
        return a.isEquivalentTo(b)
      case (.genericParameter(let a), .genericParameter(let b)):
        return a.isEquivalentTo(b)
      case (.topLevelDeclarations(let a), .topLevelDeclarations(let b)):
        return a.isEquivalentTo(b)
      case (.comment(let a), .comment(let b)):
        return a.isEquivalentTo(b)
      case (.functionCallArgument(let a), .functionCallArgument(let b)):
        return a.isEquivalentTo(b)
      default:
        return false
    }
  }
}
