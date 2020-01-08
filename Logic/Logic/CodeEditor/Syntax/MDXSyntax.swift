import AppKit

public struct MDXText: Codable & Equatable {
  public init(value: String) {
    self.value = value
  }

  public var value: String
}

public struct MDXImage: Codable & Equatable {
  public init(alt: Optional<String>, url: String) {
    self.alt = alt
    self.url = url
  }

  public var alt: Optional<String>
  public var url: String
}

public struct MDXStrong: Codable & Equatable {
  public init(children: Array<MDXInlineNode>) {
    self.children = children
  }

  public var children: Array<MDXInlineNode>
}

public struct MDXEmphasis: Codable & Equatable {
  public init(children: Array<MDXInlineNode>) {
    self.children = children
  }

  public var children: Array<MDXInlineNode>
}

public struct MDXInlineCode: Codable & Equatable {
  public init(value: String) {
    self.value = value
  }

  public var value: String
}

public struct MDXBreak: Codable & Equatable {
  public init() {}
}

public struct MDXLink: Codable & Equatable {
  public init(children: Array<MDXInlineNode>, url: String) {
    self.children = children
    self.url = url
  }

  public var children: Array<MDXInlineNode>
  public var url: String
}

public struct MDXParagraph: Codable & Equatable {
  public init(children: Array<MDXInlineNode>) {
    self.children = children
  }

  public var children: Array<MDXInlineNode>
}

public struct MDXHeading: Codable & Equatable {
  public init(depth: Int, children: Array<MDXInlineNode>) {
    self.depth = depth
    self.children = children
  }

  public var depth: Int
  public var children: Array<MDXInlineNode>
}

public struct MDXBlockquote: Codable & Equatable {
  public init(children: Array<MDXInlineNode>) {
    self.children = children
  }

  public var children: Array<MDXInlineNode>
}

public struct MDXCode: Codable & Equatable {
  public init(lang: Optional<String>, value: String, parsed: Optional<LGCSyntaxNode>) {
    self.lang = lang
    self.value = value
    self.parsed = parsed
  }

  public var lang: Optional<String>
  public var value: String
  public var parsed: Optional<LGCSyntaxNode>
}

public struct MDXThematicBreak: Codable & Equatable {
  public init() {}
}

public struct MDXList: Codable & Equatable {
  public init(ordered: Bool, children: Array<MDXListItemNode>) {
    self.ordered = ordered
    self.children = children
  }

  public var ordered: Bool
  public var children: Array<MDXListItemNode>
}

public indirect enum MDXListItemNode: Codable & Equatable {
  case listItem(children: Array<MDXBlockNode>)

  // MARK: Codable

  public enum CodingKeys: CodingKey {
    case type
    case data
  }

  public enum DataCodingKeys: CodingKey {
    case children
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
      case "listItem":
        self = .listItem(children: try data.decode(Array.self, forKey: .children))
      default:
        fatalError("Failed to decode enum due to invalid case type.")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    var data = container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: CodingKeys.data)

    switch self {
      case .listItem(let value):
        try container.encode("listItem", forKey: .type)
        try data.encode(value, forKey: .children)
    }
  }
}

public struct MDXPage: Codable & Equatable {
  public init(value: String, url: String) {
    self.value = value
    self.url = url
  }

  public var value: String
  public var url: String
}

public struct MDXRoot: Codable & Equatable {
  public init(children: Array<MDXBlockNode>) {
    self.children = children
  }

  public var children: Array<MDXBlockNode>
}

public indirect enum MDXBlockNode: Codable & Equatable {
  case image(MDXImage)
  case paragraph(MDXParagraph)
  case heading(MDXHeading)
  case code(MDXCode)
  case thematicBreak(MDXThematicBreak)
  case blockquote(MDXBlockquote)
  case list(MDXList)
  case page(MDXPage)

  // MARK: Codable

  public enum CodingKeys: CodingKey {
    case type
    case data
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
      case "image":
        self = .image(try container.decode(MDXImage.self, forKey: .data))
      case "paragraph":
        self = .paragraph(try container.decode(MDXParagraph.self, forKey: .data))
      case "heading":
        self = .heading(try container.decode(MDXHeading.self, forKey: .data))
      case "code":
        self = .code(try container.decode(MDXCode.self, forKey: .data))
      case "thematicBreak":
        self = .thematicBreak(try container.decode(MDXThematicBreak.self, forKey: .data))
      case "blockquote":
        self = .blockquote(try container.decode(MDXBlockquote.self, forKey: .data))
      case "list":
        self = .list(try container.decode(MDXList.self, forKey: .data))
      case "page":
        self = .page(try container.decode(MDXPage.self, forKey: .data))
      default:
        fatalError("Failed to decode enum due to invalid case type.")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
      case .image(let value):
        try container.encode("image", forKey: .type)
        try container.encode(value, forKey: .data)
      case .paragraph(let value):
        try container.encode("paragraph", forKey: .type)
        try container.encode(value, forKey: .data)
      case .heading(let value):
        try container.encode("heading", forKey: .type)
        try container.encode(value, forKey: .data)
      case .code(let value):
        try container.encode("code", forKey: .type)
        try container.encode(value, forKey: .data)
      case .thematicBreak(let value):
        try container.encode("thematicBreak", forKey: .type)
        try container.encode(value, forKey: .data)
      case .blockquote(let value):
        try container.encode("blockquote", forKey: .type)
        try container.encode(value, forKey: .data)
      case .list(let value):
        try container.encode("list", forKey: .type)
        try container.encode(value, forKey: .data)
      case .page(let value):
        try container.encode("page", forKey: .type)
        try container.encode(value, forKey: .data)
    }
  }
}

public indirect enum MDXInlineNode: Codable & Equatable {
  case text(MDXText)
  case strong(MDXStrong)
  case emphasis(MDXEmphasis)
  case inlineCode(MDXInlineCode)
  case link(MDXLink)
  case `break`(MDXBreak)

  // MARK: Codable

  public enum CodingKeys: CodingKey {
    case type
    case data
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
      case "text":
        self = .text(try container.decode(MDXText.self, forKey: .data))
      case "strong":
        self = .strong(try container.decode(MDXStrong.self, forKey: .data))
      case "emphasis":
        self = .emphasis(try container.decode(MDXEmphasis.self, forKey: .data))
      case "inlineCode":
        self = .inlineCode(try container.decode(MDXInlineCode.self, forKey: .data))
      case "link":
        self = .link(try container.decode(MDXLink.self, forKey: .data))
      case "break":
        self = .break(try container.decode(MDXBreak.self, forKey: .data))
      default:
        fatalError("Failed to decode enum due to invalid case type.")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
      case .text(let value):
        try container.encode("text", forKey: .type)
        try container.encode(value, forKey: .data)
      case .strong(let value):
        try container.encode("strong", forKey: .type)
        try container.encode(value, forKey: .data)
      case .emphasis(let value):
        try container.encode("emphasis", forKey: .type)
        try container.encode(value, forKey: .data)
      case .inlineCode(let value):
        try container.encode("inlineCode", forKey: .type)
        try container.encode(value, forKey: .data)
      case .link(let value):
        try container.encode("link", forKey: .type)
        try container.encode(value, forKey: .data)
      case .`break`(let value):
        try container.encode("break", forKey: .type)
        try container.encode(value, forKey: .data)
    }
  }
}
