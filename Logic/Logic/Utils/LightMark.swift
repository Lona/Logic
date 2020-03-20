// Swift version:
//
// Copyright (c) 2019 Devin Abbott
//
// Original JavaScript version: https://github.com/developit/snarkdown
//
// The MIT License (MIT)
//
// Copyright (c) 2017 Jason Miller
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation

// MARK: - Extensions

private extension String {
    var nsRange: NSRange { return NSRange(startIndex..<endIndex, in: self) }

    func replacingOccurrences(of target: NSRegularExpression, with replacement: String) -> String {
        return target.stringByReplacingMatches(in: self, options: [], range: nsRange, withTemplate: String(replacement))
    }
}

private extension String {
    func index(from: Int) -> Index { return index(startIndex, offsetBy: from) }

    func substring(from: Int) -> String { return String(self[index(from: from)..<endIndex]) }

    func substring(with range: Range<Int>) -> String {
        return String(self[index(from: range.lowerBound)..<index(from: range.upperBound)])
    }

    func substring(with range: NSRange) -> String {
        return String(self[Range(range, in: self)!])
    }
}

private extension NSTextCheckingResult {
    func matchExists(_ index: Int) -> Bool {
        return !(numberOfRanges < index || range(at: index).location == NSNotFound)
    }

    func match(_ index: Int, within string: String) -> String? {
        if !matchExists(index) { return nil }
        return string.substring(with: range(at: index))
    }
}

// MARK: - Regular Expressions

private enum Pattern {
    static let tokenizer = ###"((?:^|\n+)(?:\n---+|\* \*(?: \*)+)\n)|(?:^``` *(\w*)\n([\s\S]*?)\n```(?:\n|$))|((?:(?:^|\n+)(?:\t|  {2,}).+)+\n*)|((?:(?:^|\n)([IWE]?[>*+-]|\d+\.)\s+.*)+)|(?:\!\[([^\]]*?)\]\(([^\)]+?)\))|(\[)|(\](?:\(([^\)]+?)\))?)|(?:(?:^|\n+)([^\s].*)\n(\-{3,}|={3,})(?:\n+|$))|(?:(?:^|\n+)(#{1,6})\s*(.+)(?:\n+|$))|(?:`([^`].*?)`)|(  \n\n*|\n{2,}|__|\*\*|[_*]|~~)"###
}

private enum RegularExpression {
    static let tokenizer = try! NSRegularExpression(pattern: Pattern.tokenizer, options: [.anchorsMatchLines])
    static let referenceLink = try! NSRegularExpression(pattern: #"^\[(.+?)\]:\s*(.+)$"#, options: [.anchorsMatchLines])
    static let leadingAndTrailingNewlines = try! NSRegularExpression(pattern: #"^\n+|\n+$"#, options: [])
    static let leadingDigits = try! NSRegularExpression(pattern: #"^\d+"#, options: [.anchorsMatchLines])
    static let blockQuoteOrList = try! NSRegularExpression(pattern: #"^\s*[IWE]?[>*+.-]"#, options: [.anchorsMatchLines])
    static let listItem = try! NSRegularExpression(pattern: #"^(.*)(\n|$)"#, options: [.anchorsMatchLines])
    static let escaped = try! NSRegularExpression(pattern: #"/[^\\](\\\\)*\\$/"#, options: [])
}

// MARK: - LightMark

public enum LightMark {

    public enum HeadingLevel: Int {
        case level1 = 1, level2, level3, level4, level5, level6
    }

    public enum ListKind {
        case ordered, unordered
    }

    public enum TextStyle {
        case strong, emphasis, strikethrough

        fileprivate init(_ markup: String) {
            switch markup {
            case "": self = .emphasis
            case "_": self = .strong
            case "~": self = .strikethrough
            default: fatalError("Invalid formatting markup")
            }
        }
    }

    public enum QuoteKind {
        case none, info, warning, error

        fileprivate init(_ string: String) {
            switch string {
            case "I>": self = .info
            case "W>": self = .warning
            case "E>": self = .error
            default: self = .none
            }
        }
    }

    fileprivate enum InternalNode {
        case text(content: String)
        case styledText(style: TextStyle, content: [InternalNode])
        case block(language: String, content: String)
        case quote(kind: QuoteKind, content: [InternalNode])
        case list(kind: ListKind, content: [[InternalNode]])
        case image(source: String, description: String)
        case link(source: String, content: [InternalNode])
        case heading(level: HeadingLevel, content: [InternalNode])
        case code(content: String)
        case horizontalRule
        case lineBreak

        var isInline: Bool {
            switch self {
            case .text, .styledText, .image, .link, .code: return true
            default: return false
            }
        }
    }

    public enum InlineElement: Equatable {
        case text(content: String)
        case styledText(style: TextStyle, content: [InlineElement])
        case image(source: String, description: String)
        case link(source: String, content: [InlineElement])
        case code(content: String)
    }

    public enum BlockElement {
        case paragraph(content: [InlineElement])
        case block(language: String, content: String)
        case quote(kind: QuoteKind, content: [BlockElement])
        case list(kind: ListKind, content: [[BlockElement]])
        case heading(level: HeadingLevel, content: [InlineElement])
        case horizontalRule
        case lineBreak
    }

    // Outdent a string based on the first indented line's leading whitespace
    private static func outdent(_ str: String) -> String {
        let whitespace = str.prefix(while: { char in char == "\t" || char == " " })
        let replaced = try! NSRegularExpression(pattern: #"^\#(whitespace)"#, options: [.anchorsMatchLines])
            .stringByReplacingMatches(in: str, range: str.nsRange, withTemplate: "")
        return replaced
    }

    private static func extractLinks(_ md: String) -> [String: String] {
        var links: [String: String] = [:]

        RegularExpression.referenceLink.enumerateMatches(in: md, range: md.nsRange) { (match, _, ptr) in
            let name = String(md[Range(match!.range(at: 1), in: md)!])
            let url = String(md[Range(match!.range(at: 2), in: md)!])
            links[name] = url
        }

        return links
    }

    private static func inlineFormattingKey(_ token: String) -> String? {
        let characters = token.map { $0 == "*" ? "_" : $0 }
        let key = characters.count > 1 ? String(characters[1]) : ""
        switch key {
        case "", "_", "~", "\n", " ": return key
        default: return nil
        }
    }

    private static func parseMarkdown(_ md: String, _ links: inout [String: String]) -> [InternalNode] {
        links.merge(extractLinks(md), uniquingKeysWith: { a, b in b })

        let md = md
            .replacingOccurrences(of: RegularExpression.referenceLink, with: "")
            .replacingOccurrences(of: RegularExpression.leadingAndTrailingNewlines, with: "")

        var last: Int = 0
        var nodes: [InternalNode] = []
        var context: [String] = []
        func flush() { context = [] }

        RegularExpression.tokenizer.enumerateMatches(in: md, options: [], range: md.nsRange) { (result, flags, stop) in
            guard let result = result else { return }

            let prev = md.substring(with: last..<result.range.lowerBound)
            last = result.range.upperBound

            nodes.append(.text(content: prev))

            // Escaped
            if let _ = RegularExpression.escaped.firstMatch(in: prev, range: prev.nsRange) {
                nodes.append(.text(content: md.substring(with: result.range(at: 0))))
            } // Code/indent blocks
            else if result.matchExists(3) || result.matchExists(4) {
                let language = result.match(2, within: md) ?? ""
                let fencedText = result.match(3, within: md)
                let indentedText = result.match(4, within: md)

                let className = indentedText != nil ? "poetry" : language.lowercased()
                let content = outdent(
                    (fencedText ?? indentedText ?? "").replacingOccurrences(
                        of: RegularExpression.leadingAndTrailingNewlines,
                        with: ""
                    )
                )

                nodes.append(InternalNode.block(language: className, content: content))
            } // > Quotes, -* lists:
            else if let listType = result.match(6, within: md) {
                var content = result.match(5, within: md)!

                if listType.contains(".") {
                    content = content.replacingOccurrences(of: RegularExpression.leadingDigits, with: "")
                }

                let inner = outdent(
                    content.replacingOccurrences(of: RegularExpression.blockQuoteOrList, with: "")
                )

                if listType == ">" || listType == "I>" || listType == "W>" || listType == "E>" {
                    nodes.append(InternalNode.quote(kind: QuoteKind(listType), content: parseMarkdown(inner, &links)))
                } else {
                    var items: [String] = []

                    RegularExpression.listItem.enumerateMatches(in: inner, options: [], range: inner.nsRange, using: { result, _, _ in
                        guard let result = result else { return }
                        items.append(result.match(1, within: inner)!)
                    })

                    let node = InternalNode.list(
                        kind: listType.contains(".") ? .ordered : .unordered,
                        content: items.map { text in parseMarkdown(text, &links) }
                    )

                    nodes.append(node)
                }
            } // Images:
            else if let url = result.match(8, within: md) {
                let description = result.match(7, within: md) ?? ""
                nodes.append(InternalNode.image(source: url, description: description))
            } // Links:
            else if result.matchExists(10) {
                let inlineUrl = result.match(11, within: md)

                // links[prev.lowercased()] is reference to a link, e.g. [ref]
                guard let link = inlineUrl ?? links[prev.lowercased()] else {
//                    Swift.print("LightMark: Missing link for \(inlineUrl ?? prev.lowercased())")
                    nodes.append(.text(content: inlineUrl ?? prev.lowercased()))

                    flush()
                    return
                }

                let lastAnchor = nodes.lastIndex(where: { node in
                    switch node {
                    case .link(_, content: let content) where content.isEmpty: return true
                    default: return false
                    }
                })!

                let front = Array(nodes[nodes.startIndex..<lastAnchor])
                let rest = Array(nodes[lastAnchor + 1..<nodes.endIndex])
                nodes = front + [InternalNode.link(source: link, content: rest)]

                flush()
            } // Links: (add a placeholder with empty content to fill in later)
            else if result.matchExists(9) {
                nodes.append(.link(source: "", content: []))
            } // Headings:
            else if result.matchExists(12) || result.matchExists(14) {
                var level: Int
                if let hashtags = result.match(14, within: md) {
                    level = hashtags.count
                } else {
                    let divider = result.match(13, within: md)!
                    level = divider.starts(with: "=") ? 1 : 2
                }
                let content = result.match(12, within: md) ?? result.match(15, within: md)!
                let node = InternalNode.heading(level: HeadingLevel(rawValue: level)!, content: parseMarkdown(content, &links))
                nodes.append(node)
            } // `code`:
            else if let code = result.match(16, within: md) {
                nodes.append(InternalNode.code(content: code))
            } // Horizontal rules: ---, ***
            else if result.matchExists(1) {
                nodes.append(InternalNode.horizontalRule)
            } // Inline formatting: *em*, **strong** & friends:
            else if let formatting = result.match(17, within: md) {
                let key = inlineFormattingKey(formatting)

                switch key {
                case " ", "\n":
                    nodes.append(InternalNode.lineBreak)
                case "", "_", "~":
                    if context.last == formatting {
                        let prevNode = nodes.popLast()! // prev has already been pushed
                        nodes.append(InternalNode.styledText(style: TextStyle(key!), content: [prevNode]))
                        _ = context.popLast()
                    } else {
                        context.append(formatting)
                    }
                // Invalid formatting - append the formatting command (not sure if this ever gets hit)
                default:
                    nodes.append(.text(content: formatting))
                }
            } else {
                fatalError("Unhandled markdown syntax -- parser needs updating")
            }
        }

        nodes.append(.text(content: md.substring(from: last)))

        return nodes
    }

    private static func makeInlineElement(node: InternalNode) -> InlineElement? {
        switch node {
        case let .text(content: content):
            return .text(content: content)
        case let .styledText(style: style, content: content):
            return .styledText(style: style, content: content.compactMap(makeInlineElement))
        case let .image(source: source, description: description):
            return .image(source: source, description: description)
        case let .link(source: source, content: content):
            return .link(source: source, content: content.compactMap(makeInlineElement))
        case let .code(content: content):
            return .code(content: content)
        default:
            return nil
        }
    }

    private static func makeBlockElement(node: InternalNode) -> BlockElement? {
        switch node {
        case let .block(language: language, content: content):
            return .block(language: language, content: content)
        case let .quote(kind: kind, content: content):
            return .quote(kind: kind, content: makeBlockElements(nodes: content))
        case let .list(kind: kind, content: content):
            return .list(kind: kind, content: content.map { makeBlockElements(nodes: $0) })
        case let .heading(level: level, content: content):
            return .heading(level: level, content: content.compactMap(makeInlineElement))
        case .horizontalRule:
            return .horizontalRule
        case .lineBreak:
            return .lineBreak
        default:
            return nil
        }
    }

    private static func makeBlockElements(nodes: [InternalNode]) -> [BlockElement] {
        var blockElements: [BlockElement] = []

        nodes.forEach { node in
            if node.isInline {
                if let inlineElement = makeInlineElement(node: node) {
                    if case .some(.paragraph(let content)) = blockElements.last {
                        blockElements[blockElements.count - 1] = .paragraph(content: content + [inlineElement])
                    } else {
                        blockElements.append(.paragraph(content: [inlineElement]))
                    }
                }
            } else {
                blockElements.append(makeBlockElement(node: node)!)
            }
        }

        return blockElements
    }

    public static func parse(_ markdown: String) -> [BlockElement] {
        var links: [String: String] = [:]
        let internalNodes = parseMarkdown(markdown, &links)
            .filter({ node in
                if case .text("") = node { return false }
                return true
            })
        return makeBlockElements(nodes: internalNodes)
    }
}
