//
//  MDXInlineNode+EditableString.swift
//  Logic
//
//  Created by Devin Abbott on 10/14/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

extension MDXInlineNode {
    public func attributedString(for sizeLevel: TextBlockView.SizeLevel) -> NSAttributedString {
        func inner(_ node: MDXInlineNode) -> NSAttributedString {
            switch node {
            case .break:
                return NSAttributedString(string: "\n")
            case .text(let value):
                return NSAttributedString(string: value.value)
            case .emphasis(let value):
                let values: [NSAttributedString] = value.children.map { inner($0) }
                let joined = values.joined()

                if joined.length == 0 { return joined }

                let mutable = NSMutableAttributedString(attributedString: joined)
                let range: NSRange = .init(location: 0, length: mutable.length)

                mutable.add(trait: .italic, range: range)

                return mutable
            case .strong(let value):
                let values: [NSAttributedString] = value.children.map { inner($0) }
                let joined = values.joined()

                if joined.length == 0 { return joined }

                let mutable = NSMutableAttributedString(attributedString: joined)
                let range: NSRange = .init(location: 0, length: mutable.length)

                mutable.add(trait: .bold, range: range)

                return mutable
            case .link(let value):
                let values: [NSAttributedString] = value.children.map { inner($0) }
                let joined = values.joined()

                if joined.length == 0 { return joined }

                let mutable = NSMutableAttributedString(attributedString: joined)
                let range: NSRange = .init(location: 0, length: mutable.length)

                mutable.add(trait: .link(value.url), range: range)

                return mutable
            case .inlineCode(let value):
                let mutable = NSMutableAttributedString(string: value.value)

                mutable.add(trait: .code, range: .init(location: 0, length: mutable.length))

                return mutable
            }
        }

        return sizeLevel.apply(to: inner(self))
    }
}
