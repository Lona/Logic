//
//  InlineTextTrait.swift
//  Logic
//
//  Created by Devin Abbott on 9/11/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension NSAttributedString.Key {
    public static let bold = NSAttributedString.Key("bold")
    public static let italic = NSAttributedString.Key("italic")
    public static let code = NSAttributedString.Key("code")
}

public enum InlineTextTrait: Equatable, Hashable {
    case bold, italic, strikethrough, code, link(String)

    var openingDelimiter: String {
        switch self {
        case .bold: return "**"
        case .italic: return "_"
        case .strikethrough: return "~~"
        case .code: return "`"
        case .link: return "["
        }
    }

    var closingDelimiter: String {
        switch self {
        case .bold: return "**"
        case .italic: return "_"
        case .strikethrough: return "~~"
        case .code: return "`"
        case .link: return "]"
        }
    }
}

extension Array where Element == InlineTextTrait {
    public var isLink: Bool {
        return contains(where: {
            switch $0 {
            case .link:
                return true
            default:
                return false
            }
        })
    }

    public var linkText: String? {
        return compactMap({
            switch $0 {
            case .link(let string):
                return string
            default:
                return nil
            }
            }).first
    }

    public var isBold: Bool { return contains(.bold) }

    public var isItalic: Bool { return contains(.italic) }

    public var isCode: Bool { return contains(.code) }

    public init(attributes: [NSAttributedString.Key: Any]) {
        self.init()

        if let value = attributes[.bold] as? Bool, value == true {
            self.append(.bold)
        }

        if let value = attributes[.italic] as? Bool, value == true {
            self.append(.italic)
        }

        if let value = attributes[.code] as? Bool, value == true {
            self.append(.code)
        }

        if let strikethrough = attributes[.strikethroughStyle] as? Int, strikethrough != 0 {
            self.append(.strikethrough)
        }

        if let link = attributes[.link] as? NSURL {
            self.append(.link(link.absoluteString ?? ""))
        }
    }
}

extension NSMutableAttributedString {
    public func add(trait: InlineTextTrait, range: NSRange) {
        switch trait {
        case .bold:
            addAttribute(.bold, value: true, range: range)
        case .italic:
            addAttribute(.italic, value: true, range: range)
        case .strikethrough:
            addAttribute(.strikethroughStyle, value: 1, range: range)
        case .code:
            addAttribute(.code, value: true, range: range)
        case .link(let string):
            addAttribute(.link, value: NSURL(string: string) ?? NSURL(), range: range)
        }
    }

    public func remove(trait: InlineTextTrait, range: NSRange) {
        switch trait {
        case .bold:
            removeAttribute(.bold, range: range)
        case .italic:
            removeAttribute(.italic, range: range)
        case .strikethrough:
            removeAttribute(.strikethroughStyle, range: range)
        case .code:
            removeAttribute(.code, range: range)
        case .link:
            removeAttribute(.link, range: range)
        }
    }
}

extension NSAttributedString {
    public func addingAttribute(_ name: NSAttributedString.Key, value: Any) -> NSMutableAttributedString {
        return addingAttribute(name, value: value, range: NSRange(location: 0, length: self.length))
    }

    public func addingAttribute(_ name: NSAttributedString.Key, value: Any, range: NSRange) -> NSMutableAttributedString {
        let mutable = NSMutableAttributedString(attributedString: self)
        mutable.addAttribute(name, value: value, range: range)
        return mutable
    }

    public func removingAttribute(_ name: NSAttributedString.Key) -> NSMutableAttributedString {
        return removingAttribute(name, range: NSRange(location: 0, length: self.length))
    }

    public func removingAttribute(_ name: NSAttributedString.Key, range: NSRange) -> NSMutableAttributedString {
        let mutable = NSMutableAttributedString(attributedString: self)
        mutable.removeAttribute(name, range: range)
        return mutable
    }

    public func markdownString() -> String {
        let characterTraits: [[InlineTextTrait]] = (0..<self.length).map { index in
            return .init(attributes: self.attributes(at: index, effectiveRange: nil))
        }

        var result = ""

        var stack: [InlineTextTrait] = []

        for index in 0...self.length {
            let prevTraits: [InlineTextTrait] = index > 0 ? characterTraits[index - 1] : []
            let nextTraits: [InlineTextTrait] = index >= self.length ? [] : characterTraits[index]

            let addedTraits = nextTraits.difference(prevTraits)
            let removedTraits = prevTraits.difference(nextTraits)

            for trait in stack.reversed() {
                let traitIndex = stack.firstIndex(of: trait)!
                if removedTraits.contains(trait) {
                    let rest = stack[traitIndex + 1..<stack.count].filter({ !removedTraits.contains($0) })

                    result += rest.reversed().map { $0.closingDelimiter }.joined()
                    result += trait.closingDelimiter
                    result += rest.map { $0.openingDelimiter }.joined()

                    stack.remove(at: traitIndex)
                }
            }

            for trait in addedTraits {
                result += trait.openingDelimiter
                stack.append(trait)
            }

            if index < self.length {
                result += self.attributedSubstring(from: NSRange(location: index, length: 1)).string
            }
        }

        return result
    }

    public func markdownInlineBlock() -> [MDXInlineNode] {
        func buildInlineNode(traits: [InlineTextTrait], text: String) -> MDXInlineNode {
            if let linkText = traits.linkText {
                let contents = buildInlineNode(traits: traits.filter {
                    switch $0 {
                    case .link:
                        return false
                    default:
                        return true
                    }
                }, text: text)
                return .link(.init(children: [contents], url: linkText))
            } else if traits.contains(.italic) {
                return .emphasis(.init(children: [buildInlineNode(traits: traits.filter { $0 != .italic }, text: text)]))
            } else if traits.contains(.bold) {
                return .strong(.init(children: [buildInlineNode(traits: traits.filter { $0 != .bold }, text: text)]))
            } else if traits.contains(.code) {
                return .inlineCode(.init(value: text))
            } else {
                return .text(.init(value: text))
            }
        }

        var nodes: [MDXInlineNode] = []

        for index in 0..<self.length {
            let character = self.attributedSubstring(from: NSRange(location: index, length: 1)).string
            let traits: [InlineTextTrait] = .init(attributes: self.attributes(at: index, effectiveRange: nil))

            if character == "\n" {
                nodes.append(.break(.init()))
            } else {
                nodes.append(buildInlineNode(traits: traits, text: character))
            }
        }

        let result = MDXInlineNode.optimized(nodes: nodes)

        return result
    }
}
