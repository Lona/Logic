//
//  LightMark+String.swift
//  Logic
//
//  Created by Devin Abbott on 9/12/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

private var textStyle = TextStyle(size: 18)
private var boldTextStyle = TextStyle(weight: .bold, size: 18)
private var codeTextStyle = TextStyle(family: "Menlo", size: 18)

extension LightMark.InlineElement {
    public var string: String {
        switch self {
        case .text(content: let value):
            return value
        case .styledText(style: let style, content: let content):
            switch style {
            case .emphasis:
                return "_\(content.map { $0.string }.joined())_"
            case .strong:
                return "**\(content.map { $0.string }.joined())**"
            case .strikethrough:
                return "~\(content.map { $0.string }.joined())~"
            }
        case .image(let source, let description):
            fatalError("Not supported")
        case .link(let source, let content):
            fatalError("Not supported")
        case .code(let value):
            return "`\(value)`"
        }
    }

    public var editableString: NSAttributedString {
        switch self {
        case .text(content: let value):
            return textStyle.apply(to: value)
        case .styledText(style: let style, content: let content):
            let values: [NSAttributedString] = content.map { $0.editableString }
            let joined = values.joined()

            if joined.length == 0 { return joined }

            let mutable = NSMutableAttributedString(attributedString: joined)
            let range: NSRange = .init(location: 0, length: mutable.length)

            switch style {
            case .emphasis:
                mutable.add(trait: .italic, range: range)
            case .strong:
                mutable.add(trait: .bold, range: range)
            case .strikethrough:
                mutable.addAttribute(.strikethroughStyle, value: 1, range: range)
            }

            return mutable
        case .image(let source, let description):
//            fatalError("Not supported")
            return NSAttributedString(string: "")
        case .link(let source, let content):
            fatalError("Not supported")
        case .code(let value):
            let mutable = NSMutableAttributedString(string: value, attributes: codeTextStyle.attributeDictionary)

            mutable.add(trait: .code, range: .init(location: 0, length: mutable.length))

            return mutable
        }
    }
}

