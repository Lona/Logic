//
//  InlineTextTrait.swift
//  Logic
//
//  Created by Devin Abbott on 9/11/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public enum InlineTextTrait: Equatable {
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

    static var monospacedFontFamily: String = "Menlo"
}

extension Array where Element == InlineTextTrait {
    public var isBold: Bool { return contains(.bold) }

    public var isItalic: Bool { return contains(.italic) }

    public init(attributes: [NSAttributedString.Key: Any]) {
        self.init()

        if let font = attributes[.font] as? NSFont {
            if NSFontManager.shared.traits(of: font).contains(.boldFontMask) {
                self.append(.bold)
            }
            if NSFontManager.shared.traits(of: font).contains(.italicFontMask) {
                self.append(.italic)
            }
            if font.familyName == InlineTextTrait.monospacedFontFamily {
                self.append(.code)
            }
        }

        if let strikethrough = attributes[.strikethroughStyle] as? Int, strikethrough != 0 {
            self.append(.strikethrough)
        }
    }
}

extension NSMutableAttributedString {
    public func add(trait: InlineTextTrait, range: NSRange) {
        guard let font = self.fontAttributes(in: range)[.font] as? NSFont else { return }

        switch trait {
        case .bold:
            let newFont = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
            addAttribute(.font, value: newFont, range: range)
        case .italic:
            let newFont = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
            addAttribute(.font, value: newFont, range: range)
        case .strikethrough:
            addAttribute(.strikethroughStyle, value: 1, range: range)
        case .code:
            let newFont = NSFontManager.shared.convert(font, toFamily: InlineTextTrait.monospacedFontFamily)
            addAttribute(.font, value: newFont, range: range)
            addAttribute(.backgroundColor, value: Colors.commentBackground, range: range)
        default:
            break
        }
    }

    public func remove(trait: InlineTextTrait, range: NSRange) {
        guard let font = self.fontAttributes(in: range)[.font] as? NSFont else { return }

        switch trait {
        case .bold:
            let newFont = NSFontManager.shared.convert(font, toNotHaveTrait: .boldFontMask)
            addAttribute(.font, value: newFont, range: range)
        case .italic:
            let newFont = NSFontManager.shared.convert(font, toNotHaveTrait: .italicFontMask)
            addAttribute(.font, value: newFont, range: range)
        case .strikethrough:
            removeAttribute(.strikethroughStyle, range: range)
        case .code:
            let newFont = NSFontManager.shared.convert(font, toFamily: NSFont.systemFont(ofSize: NSFont.systemFontSize).familyName!)
            addAttribute(.font, value: newFont, range: range)
            removeAttribute(.backgroundColor, range: range)
        default:
            break
        }
    }
}

extension NSAttributedString {
//    public func att

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
}
