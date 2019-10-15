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
        case .tokens(let rootNode):
            return .code(MDXCode(rootNode))
        case .divider:
            return .thematicBreak(.init())
        case .image(let url):
            return .image(.init(alt: "", url: url?.absoluteString ?? ""))
        }
    }

    public static func makeMarkdownRoot(_ blocks: [BlockEditor.Block]) -> MDXRoot {
        return .init(children: blocks.map { makeMarkdownBlock($0) })
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

        guard let markdownStringData = LogicFile.convert(convertedData, kind: .document, to: .source, from: .json) else {
            Swift.print("Failed to convert MDX JSON to markdown string")
            return nil
        }

        return markdownStringData
    }

    // MARK: Decoding markdown

    public static func makeMDXRoot(_ markdownData: Data) -> MDXRoot? {
        guard let jsonData = LogicFile.convert(markdownData, kind: .document, to: .json, from: .source),
            let mdxRoot = try? JSONDecoder().decode(MDXRoot.self, from: jsonData) else {
            Swift.print("Failed to convert Markdown file Data to MDXRoot")
            return nil
        }

        return mdxRoot
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

        let blocks: [BlockEditor.Block] = mdxRoot.children.compactMap { blockElement in
            switch blockElement {
            case .thematicBreak:
                return BlockEditor.Block(.divider)
            case .image(let image):
                return BlockEditor.Block(.image(URL(string: image.url)))
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
                return BlockEditor.Block(.text(attributedString, sizeLevel))
            case .paragraph(let value):
                let attributedString: NSAttributedString = value.children.map { $0.attributedString(for: .paragraph) }.joined()
                return BlockEditor.Block(.text(attributedString, .paragraph))
            case .blockquote(let value):
                let attributedString: NSAttributedString = value.children.map { $0.attributedString(for: .quote) }.joined()
                return BlockEditor.Block(.text(attributedString, .quote))
            case .code(let value):
                return BlockEditor.Block(.tokens(.declaration(value.declarations()!.first!)))
            }
        }
        return blocks
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
