//
//  RichText.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 3/3/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public struct RichText {
    public enum TextStyle {
        case none
        case bold
        case link
    }

    public enum HeadingSize {
        case title
        case section
    }

    public enum InlineElement {
        case text(TextStyle, () -> String)
    }

    public enum BlockElement {
        case custom(NSView)
        case heading(HeadingSize, () -> String)
        case paragraph([InlineElement])
    }

    public var blocks: [BlockElement]

    public init(blocks: [BlockElement]) {
        self.blocks = blocks
    }
}
