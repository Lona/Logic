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
        guard let contents = String(data: markdownData, encoding: .utf8) else {
            Swift.print("Failed to convert Markdown file Data to String")
            return nil
        }

        return makeBlocks(contents)
    }

    public static func makeBlocks(_ markdownString: String) -> [BlockEditor.Block] {
        let parsed = LightMark.parse(markdownString)

        if parsed.count == 0 {
            return [
                EditableBlock.makeDefaultEmptyBlock()
            ]
        }

        let blocks: [BlockEditor.Block] = parsed.compactMap { blockElement in
            switch blockElement {
            case .lineBreak:
                return nil
            case .heading(level: let level, content: let inlineElements):
                func sizeLevel() -> InlineBlockEditor.SizeLevel {
                    switch level {
                    case .level1: return .h1
                    case .level2: return .h2
                    case .level3: return .h3
                    case .level4: return .h4
                    case .level5: return .h5
                    case .level6: return .h6
                    }
                }

                let value: NSAttributedString = inlineElements.map { $0.editableString }.joined()
                return BlockEditor.Block(.text(value, sizeLevel()))
            case .paragraph(content: let inlineElements):
                let value: NSAttributedString = inlineElements.map { $0.editableString }.joined()
                return BlockEditor.Block(.text(value, .paragraph))
            case .block(language: "tokens", content: let code):
                guard let data = code.data(using: .utf8) else { fatalError("Invalid utf8 data in markdown code block") }

                guard let rootNode = LGCSyntaxNode(data: data) else {
                    Swift.print("Failed to create code block from", code)
                    return nil
                }

                guard case .topLevelDeclarations(let topLevelDeclarations) = rootNode else {
                    Swift.print("DECODING: Tokens block uses incorrect top-level node", code)
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
