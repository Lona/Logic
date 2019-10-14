//
//  MDXSyntax+MDXInlineNode.swift
//  Logic
//
//  Created by Devin Abbott on 10/5/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension MDXInlineNode {

    // MARK: Initializers

    public static func strong() -> MDXInlineNode {
        return .strong(.init(children: []))
    }

    public static func emphasis() -> MDXInlineNode {
        return .strong(.init(children: []))
    }

    public static func inlineCode() -> MDXInlineNode {
        return .inlineCode(.init(value: ""))
    }

    public static func text() -> MDXInlineNode {
        return .text(.init(value: ""))
    }

    // MARK: Mutators

    public func node(atPath path: [Int]) -> MDXInlineNode {
        if path.count == 0 { return self }

        let index = path[0]
        let rest = Array(path.dropFirst())

        switch self {
        case .emphasis(let value):
            return value.children[index].node(atPath: rest)
        case .strong(let value):
            return value.children[index].node(atPath: rest)
        case .link(let value):
            return value.children[index].node(atPath: rest)
        case .text, .inlineCode, .break:
            fatalError("Invalid path")
        }
    }

    public func replacing(nodeAtPath path: [Int], with node: MDXInlineNode) -> MDXInlineNode {
        if path.count == 0 { return node }

        let index = path[0]
        let rest = Array(path.dropFirst())

        switch self {
        case .emphasis(let value):
            let children = value.children.replacing(elementAt: index, with: value.children[index].replacing(nodeAtPath: rest, with: node))
            return .emphasis(.init(children: children))
        case .strong(let value):
            let children = value.children.replacing(elementAt: index, with: value.children[index].replacing(nodeAtPath: rest, with: node))
            return .strong(.init(children: children))
        case .link(let value):
            let children = value.children.replacing(elementAt: index, with: value.children[index].replacing(nodeAtPath: rest, with: node))
            return .link(.init(children: children, url: value.url))
        case .text, .inlineCode, .break:
            fatalError("Invalid replacement path")
        }
    }

    public func inserting(node: MDXInlineNode, atPath path: [Int]) -> MDXInlineNode {
        guard let _ = path.last else { fatalError("Invalid insertion path") }

        let parentNode = self.node(atPath: path.dropLast())

        let newParentNode = parentNode.with(children: parentNode.children!.inserting(node, at: path[path.count - 1]))

        return self.replacing(nodeAtPath: path, with: newParentNode)
    }

    // MARK: Accessors

    public func with(children: [MDXInlineNode]) -> MDXInlineNode {
        switch self {
        case .emphasis:
            return .emphasis(.init(children: children))
        case .strong:
            return .strong(.init(children: children))
        case .link(let value):
            return .link(.init(children: children, url: value.url))
        case .text, .inlineCode, .break:
            fatalError("Cannot set children for \(self)")
        }
    }

    public func with(value: String) -> MDXInlineNode {
        switch self {
        case .inlineCode:
            return .inlineCode(.init(value: value))
        case .text:
            return .text(.init(value: value))
        case .emphasis, .strong, .link, .break:
            fatalError("Cannot set value for \(self)")
        }
    }

    public var children: [MDXInlineNode]? {
        switch self {
        case .emphasis(let value):
            return value.children
        case .strong(let value):
            return value.children
        case .link(let value):
            return value.children
        case .text, .inlineCode, .break:
            return nil
        }
    }

    public var value: String? {
        switch self {
        case .inlineCode(let value):
            return value.value
        case .text(let value):
            return value.value
        case .strong, .emphasis, .link, .break:
            return nil
        }
    }

    public var isEmpty: Bool {
        switch self {
        case .inlineCode(let value):
            return value.value.isEmpty
        case .text(let value):
            return value.value.isEmpty
        case .emphasis(let value):
            return value.children.isEmpty
        case .strong(let value):
            return value.children.isEmpty
        case .link(let value):
            return value.children.isEmpty
        case .break:
            return false
        }
    }

    // MARK: Traversal

    public static func map(_ node: MDXInlineNode, f: (MDXInlineNode) -> MDXInlineNode) -> MDXInlineNode {
        if let children = node.children {
            return f(node.with(children: map(children, f: f)))
        } else {
            return f(node)
        }
    }

    public static func map(_ nodes: [MDXInlineNode], f: (MDXInlineNode) -> MDXInlineNode) -> [MDXInlineNode] {
        return nodes.map({ node in map(node, f: f) })
    }

    // MARK: Optimize

    public static func optimized(nodes: [MDXInlineNode]) -> [MDXInlineNode] {
        func optimizedInner(nodes: [MDXInlineNode]) -> [MDXInlineNode] {
            return MDXInlineNode.mergeAdjacent(
                nodes: nodes.filter({ !$0.isEmpty })
            ).map({ (node) -> MDXInlineNode in
                if let children = node.children {
                    return node.with(children: optimizedInner(nodes: children))
                } else {
                    return node
                }
            })
        }

        let optimizedNodes = optimizedInner(nodes: nodes)

        // Optimize until there are no changes
        if nodes == optimizedNodes {
            return optimizedNodes
        } else {
            return optimized(nodes: optimizedNodes)
        }
    }

    public static func mergeAdjacent(nodes: [MDXInlineNode]) -> [MDXInlineNode] {
        var nodes = nodes
        var result: [MDXInlineNode] = []

        while nodes.count >= 2 {
            if let merged = MDXInlineNode.merge(nodes[0], nodes[1]) {
                nodes.removeFirst()
                nodes = nodes.replacing(elementAt: 0, with: merged)
            } else {
                result.append(nodes.removeFirst())
            }
        }

        result.append(contentsOf: nodes)

        return result
    }

    public static func merge(_ nodeA: MDXInlineNode, _ nodeB: MDXInlineNode) -> MDXInlineNode? {
        switch (nodeA, nodeB) {
        case (.text(let a), .text(let b)):
            return .text(.init(value: a.value + b.value))
        case (.inlineCode(let a), .inlineCode(let b)):
            return .inlineCode(.init(value: a.value + b.value))
        case (.emphasis(let a), .emphasis(let b)):
            return .emphasis(.init(children: a.children + b.children))
        case (.strong(let a), .strong(let b)):
            return .strong(.init(children: a.children + b.children))
        case (.link(let a), .link(let b)) where a.url == b.url:
            return .link(.init(children: a.children + b.children, url: a.url))
        case (.break, .break):
            return .break(.init())
        default:
            return nil
        }
    }
}
