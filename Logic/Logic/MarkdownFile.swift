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
            }
        case .tokens(let rootNode):
            guard case .declaration(let declaration) = rootNode else {
                Swift.print("ENCODING: Tokens block uses incorrect top-level node")
                fatalError("FAILED TO ENCODE TOKENS")
            }
            let rootNode: LGCSyntaxNode = .topLevelDeclarations(.init(id: UUID(), declarations: .init([declaration])))

            return .code(.init(lang: "tokens", value: "", parsed: rootNode))
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

    public static func makeBlocks(_ markdownData: Data) -> [BlockEditor.Block]? {
        guard let jsonData = LogicFile.convert(markdownData, kind: .document, to: .json, from: .source),
            let mdxRoot = try? JSONDecoder().decode(MDXRoot.self, from: jsonData) else {
            Swift.print("Failed to convert Markdown file Data to AST")
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
                func sizeLevel(_ level: Int) -> TextBlockView.SizeLevel {
                    switch level {
                    case 1: return .h1
                    case 2: return .h2
                    case 3: return .h3
                    case 4: return .h4
                    case 5: return .h5
                    case 6: return .h6
                    default: fatalError("Invalid markdown header level")
                    }
                }

                let attributedString: NSAttributedString = value.children.map { $0.editableString }.joined()
                return BlockEditor.Block(.text(attributedString, sizeLevel(value.depth)))
            case .paragraph(let value):
                let attributedString: NSAttributedString = value.children.map { $0.editableString }.joined()
                return BlockEditor.Block(.text(attributedString, .paragraph))
            case .code(let value):
                guard let rootNode = value.parsed else {
                    Swift.print("Code block didn't contain parsed tokens", value)
                    return nil
                }

                guard case .topLevelDeclarations(let topLevelDeclarations) = rootNode else {
                    Swift.print("DECODING: Tokens block uses incorrect top-level node", value)
                    return nil
                }

                return BlockEditor.Block(.tokens(.declaration(topLevelDeclarations.declarations.first!)))
            }
        }
        return blocks
    }
}
