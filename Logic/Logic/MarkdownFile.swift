//
//  MarkdownFile.swift
//  Logic
//
//  Created by Devin Abbott on 9/23/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

// MARK: - MarkdownFile

public enum MarkdownFile {

    // MARK: Encoding markdown

    public static func makeMarkdownBlock(_ block: BlockEditor.Block) -> MDXBlockNode {
        switch block.content {
        case .text(let textValue, let sizeLevel):
            switch sizeLevel {
            case .h1, .h2, .h3, .h4, .h5, .h6:
                return .heading(.init(depth: sizeLevel.rawValue, children: textValue.markdownInlineBlock()))
            case .paragraph:
                return .paragraph(.init(children: textValue.markdownInlineBlock()))
            case .quote:
                return .blockquote(.init(children: textValue.markdownInlineBlock()))
            }
        case .page(title: let title, target: let target):
            return .page(.init(value: title, url: target))
        case .tokens(let rootNode):
            return .code(MDXCode(rootNode))
        case .divider:
            return .thematicBreak(.init())
        case .image(let url):
            return .image(.init(alt: "", url: url?.absoluteString ?? ""))
        }
    }

    public static func makeMarkdownRoot(_ blocks: [BlockEditor.Block]) -> MDXRoot {
        func isListStart(blocks: [BlockEditor.Block], block: BlockEditor.Block) -> Bool {
            guard let index = blocks.firstIndex(of: block) else { return false }

            let prefix = blocks.prefix(upTo: index)

            for previous in prefix.reversed() {
                if previous.listDepth.depth > block.listDepth.depth {
                    continue
                } else if previous.listDepth.depth == block.listDepth.depth {
                    switch (previous.listDepth, block.listDepth) {
                    // An indented block can't be the start of a new list
                    case (_, .indented):
                        return false
                    // A different kind of list is the start of a new list
                    case (.ordered, .unordered), (.unordered, .ordered):
                        return true
                    // The same kind of list must be in an existing list
                    case (.ordered, .ordered), (.unordered, .unordered):
                        return false
                    // A list following an indented block may be a new list
                    case (.indented, .unordered), (.indented, .ordered):
                        continue
                    }
                // Only lists should be allowed here, but we double check `isList` anyway
                } else if block.listDepth.isList {
                    return true
                }
            }

            return block.listDepth.isList
        }

        func getListItems(blocks: [BlockEditor.Block], block: BlockEditor.Block) -> [BlockEditor.Block] {
            guard let index = blocks.firstIndex(of: block) else { return [] }

            let suffix = blocks.suffix(from: index).dropFirst()

            var list: [BlockEditor.Block] = []

            for next in suffix {
                if next.listDepth.depth == block.listDepth.depth && next.listDepth.isList &&
                    !isListStart(blocks: blocks, block: next) {
                    list.append(next)
                } else if next.listDepth.depth == block.listDepth.depth && !next.listDepth.isList {
                    continue
                } else if next.listDepth.depth > block.listDepth.depth {
                    continue
                } else {
                    break
                }
            }

            return list
        }

        func getListItemChildren(blocks: [BlockEditor.Block], block: BlockEditor.Block) -> [BlockEditor.Block] {
            guard let index = blocks.firstIndex(of: block) else { return [] }

            let suffix = blocks.suffix(from: index).dropFirst()

            var list: [BlockEditor.Block] = []

            for next in suffix {
                if next.listDepth.depth == block.listDepth.depth && !next.listDepth.isList {
                    list.append(next)
                } else if next.listDepth.depth == block.listDepth.depth + 1 && isListStart(blocks: blocks, block: next) {
                    list.append(next)
                } else if next.listDepth.depth > block.listDepth.depth {
                    continue
                } else {
                    break
                }
            }

            return list
        }

        func makeListBlock(_ block: BlockEditor.Block) -> MDXBlockNode {
            if isListStart(blocks: blocks, block: block) {
                let ordered = block.listDepth.kind == "ordered"

                let firstNodeChildren = getListItemChildren(blocks: blocks, block: block)
                let firstNode: MDXListItemNode = .listItem(
                    children: [makeMarkdownBlock(block)] + firstNodeChildren.map(makeListBlock))

                let listItems: [MDXListItemNode] = [firstNode] + getListItems(blocks: blocks, block: block).map { item in
                    let children = getListItemChildren(blocks: blocks, block: item)
                    return MDXListItemNode.listItem(children: [makeMarkdownBlock(item)] + children.map(makeListBlock))
                }

                return .list(MDXList(ordered: ordered, children: listItems))
            } else {
                return makeMarkdownBlock(block)
            }
        }

        var topLevelBlocks: [MDXBlockNode] = []

        for block in blocks {
            if block.listDepth.depth == 0 {
                topLevelBlocks.append(makeMarkdownBlock(block))
            } else if block.listDepth.depth == 1 && isListStart(blocks: blocks, block: block) {
                topLevelBlocks.append(makeListBlock(block))
            }
        }

        return .init(children: topLevelBlocks)
    }

    public static func makeMarkdownData(_ blocks: [BlockEditor.Block]) -> Data? {
        let mdxRoot = makeMarkdownRoot(blocks)

        return makeMarkdownData(mdxRoot)
    }

    public static func makeMarkdownData(_ mdxRoot: MDXRoot) -> Data? {
        guard let convertedData = try? JSONEncoder().encode(mdxRoot) else {
            Swift.print("Failed to convert MDXRoot to Data")
            return nil
        }

        guard let markdownStringData = LogicFile.convert(convertedData, kind: .document, to: .source, from: .json, embeddedFormat: .source) else {
            Swift.print("Failed to convert MDX JSON to markdown string")
            return nil
        }

        return markdownStringData
    }

    // MARK: Decoding markdown

    public static func makeMDXRoot(_ markdownData: Data) -> MDXRoot? {
        guard let jsonData = LogicFile.convert(markdownData, kind: .document, to: .json, from: .source) else { return nil }

        do {
            let mdxRoot = try JSONDecoder().decode(MDXRoot.self, from: jsonData)
            return mdxRoot
        } catch let error {
            Swift.print("Failed to convert Markdown file Data to MDXRoot", error)
            return nil
        }
    }

    public static func makeBlocks(_ markdownData: Data) -> [BlockEditor.Block]? {
        guard let mdxRoot = makeMDXRoot(markdownData) else {
            Swift.print("Failed to convert Markdown file Data to BlockEditor blocks")
            return nil
        }

        return makeBlocks(mdxRoot)
    }

    public static func makeBlocks(_ mdxRoot: MDXRoot) -> [BlockEditor.Block] {
        if mdxRoot.children.count == 0 {
            return [
                EditableBlock.makeDefaultEmptyBlock()
            ]
        }

        func makeBlock(_ blockElement: MDXBlockNode, listDepth: EditableBlockListDepth) -> [BlockEditor.Block] {
            switch blockElement {
            case .page(let value):
                return [BlockEditor.Block(.page(title: value.value, target: value.url), listDepth)]
            case .thematicBreak:
                return [BlockEditor.Block(.divider, listDepth)]
            case .image(let image):
                return [BlockEditor.Block(.image(URL(string: image.url)), listDepth)]
            case .heading(let value):
                func sizeLevelForDepth(_ depth: Int) -> TextBlockView.SizeLevel {
                    switch depth {
                    case 1: return .h1
                    case 2: return .h2
                    case 3: return .h3
                    case 4: return .h4
                    case 5: return .h5
                    case 6: return .h6
                    default: fatalError("Invalid markdown header level")
                    }
                }

                let sizeLevel = sizeLevelForDepth(value.depth)
                let attributedString: NSAttributedString = value.children.map { $0.attributedString(for: sizeLevel) }.joined()
                return [BlockEditor.Block(.text(attributedString, sizeLevel), listDepth)]
            case .paragraph(let value):
                let attributedString: NSAttributedString = value.children.map { $0.attributedString(for: .paragraph) }.joined()
                return [BlockEditor.Block(.text(attributedString, .paragraph), listDepth)]
            case .blockquote(let value):
                let attributedString: NSAttributedString = value.children.map { $0.attributedString(for: .quote) }.joined()
                return [BlockEditor.Block(.text(attributedString, .quote), listDepth)]
            case .code(let value):
                return [BlockEditor.Block(.tokens(.declaration(value.declarations()!.first!)), listDepth)]
            case .list(let value):
                let blocks: [[[BlockEditor.Block]]] = value.children.enumerated().map { offset, listItem in
                    switch listItem {
                    case .listItem(children: let listItemChildren):
                        return listItemChildren.enumerated().map { childOffset, listItemBlock -> [BlockEditor.Block] in
                            let newListDepth: EditableBlockListDepth = childOffset > 0
                                ? .indented(depth: listDepth.depth + 1)
                                : value.ordered
                                ? .ordered(depth: listDepth.depth + 1, index: offset + 1)
                                : .unordered(depth: listDepth.depth + 1)
                            return makeBlock(listItemBlock, listDepth: newListDepth)
                        }
                    }
                }

                return Array(blocks.joined().joined())
            }
        }

        let blocks: [[BlockEditor.Block]] = mdxRoot.children.compactMap { blockElement in makeBlock(blockElement, listDepth: .none) }

        let result = Array(blocks.joined())

        return result
    }
}

extension MDXRoot {
    public func program() -> LGCProgram {
        let declarations: [[LGCDeclaration]] = children.compactMap { blockNode in
            switch blockNode {
            case .code(let value) where value.lang == "tokens":
                return value.declarations()
            default:
                return nil
            }
        }

        return LGCProgram(declarations: Array(declarations.joined()))
    }
}

extension MDXCode {
    public init(_ rootNode: LGCSyntaxNode) {
        switch rootNode {
        case .declaration(let value):
            let rootNode: LGCSyntaxNode = .topLevelDeclarations(.init(id: UUID(), declarations: .init([value])))
            self = .init(lang: "tokens", value: "", parsed: rootNode)
        default:
            Swift.print("MDXCode created with incorrect top-level tokens node")
            fatalError("FAILED TO ENCODE TOKENS")
        }
    }

    public func declarations() -> [LGCDeclaration]? {
        guard let rootNode = parsed else {
            Swift.print("MDXCode block didn't contain parsed tokens", value)
            return nil
        }

        switch rootNode {
        case .declaration(let value):
            return [value]
        case .topLevelDeclarations(let value):
            return value.declarations.map { $0 }
        default:
            Swift.print("MDXCode block uses incorrect top-level node (should be Declaration or TopLevelDeclarations)", value)
            return nil
        }
    }
}
