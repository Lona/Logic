//
//  EditableBlock.swift
//  Logic
//
//  Created by Devin Abbott on 9/27/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

// MARK: - EditableBlock

// EditableBlocks are initialized and deallocated frequently.
// Any data that needs to persist across re-renders should live on the EditableBlockView,
// which is cached based on the block's id.
public class EditableBlock: Equatable {
    public let id: UUID
    public let content: EditableBlockContent
    public let listDepth: EditableBlockListDepth

    public init(id: UUID, content: EditableBlockContent, listDepth: EditableBlockListDepth) {
        self.id = id
        self.content = content
        self.listDepth = listDepth
    }

    public convenience init(_ content: EditableBlockContent, _ listDepth: EditableBlockListDepth) {
        self.init(id: UUID(), content: content, listDepth: listDepth)
    }

    public var indented: EditableBlock {
        return .init(id: UUID(), content: content, listDepth: listDepth.indented)
    }

    public var outdented: EditableBlock {
        return .init(id: UUID(), content: content, listDepth: listDepth.outdented)
    }

    public static func == (lhs: EditableBlock, rhs: EditableBlock) -> Bool {
        return lhs.id == rhs.id && lhs.content == rhs.content
    }

//    deinit {
//        EditableBlock.viewCache.removeValue(forKey: id)
//    }

    public static func makeDefaultEmptyBlock() -> EditableBlock {
        return .init(.text(.init(), .paragraph), .none)
    }

    public var lineButtonAlignmentHeight: CGFloat {
        return content.lineButtonAlignmentHeight
    }

    public var lastSelectionRange: NSRange {
        switch content {
        case .tokens, .divider, .image, .page:
            return .empty
        case .text(let text, _):
            return .init(location: text.length, length: 0)
        }
    }

    public var isEmpty: Bool {
        switch content {
        case .tokens, .page:
            return false
        case .text(let text, _):
            let string = text.string
            return string.isEmpty || string == "/"
        case .divider:
            return true
        case .image(let url):
            return url == nil
        }
    }

    public var supportsInlineFocus: Bool {
        switch content {
        case .text:
            return true
        case .tokens, .divider, .image, .page:
            return false
        }
    }

    public var supportsMergingText: Bool {
        switch content {
        case .text:
            return true
        case .tokens, .divider, .image, .page:
            return false
        }
    }

    public var supportsDirectDragging: Bool {
        switch content {
        case .text, .tokens, .divider, .page:
            return false
        case .image:
            return true
        }
    }

    static func margin(_ a: EditableBlock, _ b: EditableBlock) -> CGFloat {
        switch (a.content, b.content) {
        case (.text(_, .h1), .text(_, .h2)),
             (.text(_, .h1), .text(_, .h3)):
            return 24
        case (.text(_, .h2), .text(_, .h3)):
            return 16
        case (.text(_, .h1), .text(_, .paragraph)),
             (.text(_, .h2), .text(_, .paragraph)),
             (.text(_, .h3), .text(_, .paragraph)):
            return 4
        case (.text(_, .paragraph), .text(_, .h1)),
             (.text(_, .quote), .text(_, .h1)),
             (.tokens(_), .text(_, .h1)),
             (.page(_), .text(_, .h1)):
            return 32
        case (.text(_, .paragraph), .text(_, .h2)),
             (.text(_, .quote), .text(_, .h2)),
             (.page(_), .text(_, .h2)),
             (.tokens(_), .text(_, .h2)),
             (.tokens(_), .text(_, .h3)),
             (.tokens(_), .text(_, .paragraph)):
            return 20
        case (.text(_, .paragraph), .text(_, .h3)),
             (.text(_, .quote), .text(_, .h3)),
             (.page(_), .text(_, .h3)):
            return 8
        case (.text(_, .paragraph), .text(_, .paragraph)),
             (.text(_, .quote), .text(_, .paragraph)),
             (.text(_, .paragraph), .text(_, .quote)),
             (.text(_, .quote), .text(_, .quote)):
            return 8
        default:
            return 0
        }
    }
}

extension EditableBlock: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch content {
        case .page(let value):
            return "page:\(value.title):\(value.target)"
        case .text(let textValue, let sizeLevel):
            return "text:\(sizeLevel):\(textValue.string)"
        case .tokens(let syntaxNode):
            return "tokens:\(syntaxNode.nodeTypeDescription)"
        case .divider:
            return "divider"
        case .image(let url):
            return "image:\(String(describing: url))"
        }
    }
}

public enum EditableBlockContent: Equatable {
    case text(NSAttributedString, TextBlockView.SizeLevel)
    case tokens(LGCSyntaxNode)
    case divider
    case image(URL?)
    case page(title: String, target: String)

    var lineButtonAlignmentHeight: CGFloat {
        switch self {
        case .text(_, let sizeLevel):
            return sizeLevel.fontSize * TextBlockView.lineHeightMultiple
        case .page:
            return 30
        case .tokens, .image:
            return 18
        case .divider:
            return 21
        }
    }
}

public enum EditableBlockListDepth: Equatable {
    case indented(depth: Int)
    case unordered(depth: Int)
    case ordered(depth: Int, index: Int)

    public var kind: String {
        switch self {
        case .indented: return "indented"
        case .unordered: return "unordered"
        case .ordered: return "ordered"
        }
    }

    public var isList: Bool {
        switch self {
        case .indented: return false
        case .unordered, .ordered: return true
        }
    }

    public static var indentWidth: CGFloat = 20

    public static var none: EditableBlockListDepth = .indented(depth: 0)

    public static var `default`: EditableBlockListDepth = .none

    public func with(depth: Int) -> EditableBlockListDepth {
        if depth == 0 { return .indented(depth: 0) }

        switch self {
        case .indented(_): return .indented(depth: depth)
        case .unordered(_): return .unordered(depth: depth)
        case .ordered(_, index: let index): return .ordered(depth: depth, index: index)
        }
    }

    public var depth: Int {
        switch self {
        case .indented(depth: let depth): return depth
        case .unordered(depth: let depth): return depth
        case .ordered(depth: let depth, index: _): return depth
        }
    }

    public var indented: EditableBlockListDepth {
        switch self {
        case .indented(depth: let depth):
            return .indented(depth: depth + 1)
        case .unordered(depth: let depth):
            return .unordered(depth: depth + 1)
        case .ordered(depth: let depth, index: let index):
            return .ordered(depth: depth + 1, index: index)
        }
    }

    public var outdented: EditableBlockListDepth {
        switch self {
        case .indented(depth: let depth):
            return depth > 1 ? .indented(depth: depth - 1) : .none
        case .unordered(depth: let depth):
            return depth > 1 ? .unordered(depth: depth - 1) : .none
        case .ordered(depth: let depth, index: let index):
            return depth > 1 ? .ordered(depth: depth - 1, index: index) : .none
        }
    }

    public var margin: CGFloat {
        return CGFloat(depth) * EditableBlockListDepth.indentWidth
    }
}

// MARK: - Sequence

extension Array where Element == EditableBlock {
    public var topLevelDeclarations: LGCTopLevelDeclarations {
        let nodes: [LGCSyntaxNode] = self.compactMap {
            switch $0.content {
            case .tokens(let rootNode):
                return rootNode
            default:
                return nil
            }
        }

        let declarations: [LGCDeclaration] = nodes.compactMap {
            switch $0 {
            case .declaration(let declaration):
                return declaration
            default:
                return nil
            }
        }

        return LGCTopLevelDeclarations(id: UUID(), declarations: .init(declarations))
    }

    public func normalizeLists() -> [EditableBlock] {
        let normalizedBlocks = self.enumerated().map { (offset, block) -> BlockEditor.Block in
            var block = block

            let previousListDepth = offset > 0 ? self[offset - 1].listDepth : .none

            var updatedListDepth = block.listDepth

            if previousListDepth.depth < block.listDepth.depth {
                switch block.listDepth {
                case .indented:
                    updatedListDepth = .indented(depth: previousListDepth.depth)
                case .unordered:
                    updatedListDepth = .unordered(depth: previousListDepth.depth + 1)
                case .ordered:
                    updatedListDepth = .ordered(depth: previousListDepth.depth + 1, index: 1)
                }
            } else {
                switch block.listDepth {
                case .indented, .unordered:
                    break
                case .ordered(let depth, _):
                    var index: Int = 1
                    loop: for previousBlock in self[0..<offset].reversed() {
                        if previousBlock.listDepth.depth < depth { break }
                        if previousBlock.listDepth.depth == depth {
                            switch previousBlock.listDepth {
                            case .indented:
                                continue loop
                            case .unordered:
                                break loop
                            case .ordered(_, index: let previousIndex):
                                index = previousIndex + 1
                                break loop
                            }
                        }
                    }
                    updatedListDepth = .ordered(depth: depth, index: index)
                }
            }

            if updatedListDepth != block.listDepth {
                block = EditableBlock(id: block.id, content: block.content, listDepth: updatedListDepth)
            }

            return block
        }

        // Repeat until stable
        return self.map { $0.listDepth } != normalizedBlocks.map { $0.listDepth }
            ? normalizedBlocks.normalizeLists()
            : normalizedBlocks
    }
}
