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

    public static func makeMarkdownString(_ block: BlockEditor.Block) -> String {
        switch block.content {
        case .text(let textValue, let sizeLevel):
            if let prefix = sizeLevel.prefix {
                return prefix + " " + textValue.markdownString() + "\n"
            } else {
                return textValue.markdownString() + "\n"
            }
        case .tokens(let rootNode):
            guard case .declaration(let declaration) = rootNode else {
                Swift.print("ENCODING: Tokens block uses incorrect top-level node")
                return "FAILED TO ENCODE TOKENS"
            }
            let rootNode: LGCSyntaxNode = .topLevelDeclarations(.init(id: UUID(), declarations: .init([declaration])))

            let encoder = JSONEncoder()
            guard let data = try? encoder.encode(rootNode) else { return "FAILED TO SERIALIZE TOKENS" }
            guard let xml = LogicFile.convert(data, kind: .logic, to: .xml) else { return "FAILED TO CONVERT TOKENS TO XML" }
            let code = String(data: xml, encoding: .utf8)!

            return "```tokens\n\(code)\n```"
        case .divider:
            return "---"
        case .image(let url):
            return "![](\(url?.absoluteString ?? ""))"
        }
    }

    public static func makeMarkdownString(_ blocks: [BlockEditor.Block]) -> String {
        return blocks.map { makeMarkdownString($0) }.joined(separator: "\n")
    }

    public static func makeMarkdownData(_ blocks: [BlockEditor.Block]) -> Data? {
        guard let convertedData = makeMarkdownString(blocks).data(using: .utf8) else {
            Swift.print("Failed to convert Markdown file String to Data")
            return nil
        }

        return convertedData
    }

    // MARK: Decoding markdown

    public static func makeBlocks(_ markdownData: Data) -> [BlockEditor.Block]? {
        guard let jsonData = LogicFile.convert(markdownData, kind: .document, to: .json, from: .mdx),
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
//            case .lineBreak:
//                return nil
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
            default:
                return nil
            }
        }
        return blocks
    }
}
