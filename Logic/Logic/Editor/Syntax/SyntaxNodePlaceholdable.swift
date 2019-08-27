//
//  SyntaxNodePlaceholderList.swift
//  Logic
//
//  Created by Devin Abbott on 4/5/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public protocol SyntaxNodePlaceholdable {
    var isPlaceholder: Bool { get }
    static func makePlaceholder() -> Self
}

extension LGCList where T: SyntaxNodeProtocol, T: SyntaxNodePlaceholdable {
    func replace(id: UUID, with syntaxNode: LGCSyntaxNode, preservingEndingPlaceholder: Bool) -> LGCList {
        let result = self.map { $0.replace(id: id, with: syntaxNode) }

        if preservingEndingPlaceholder {
            return LGCList(result).normalizedPlaceholders
        }

        return LGCList(result)
    }

    var normalizedPlaceholders: LGCList {
        var result = self.map { $0 }.filter { !$0.isPlaceholder }

        let placeholder = T.self.makePlaceholder()
        result.append(placeholder)

        return LGCList(result)
    }
}

extension LGCStatement: SyntaxNodePlaceholdable {
    public var isPlaceholder: Bool {
        switch self {
        case .placeholder:
            return true
        default:
            return false
        }
    }

    public static func makePlaceholder() -> LGCStatement {
        return .placeholder(id: UUID())
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

extension LGCTypeName: SyntaxNodePlaceholdable {
    public var isPlaceholder: Bool {
        switch self {
        case .placeholder:
            return true
        default:
            return false
        }
    }

    public static func makePlaceholder() -> LGCTypeName {
        return .placeholder(id: UUID())
    }
}
