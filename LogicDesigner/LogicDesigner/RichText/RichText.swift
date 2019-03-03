//
//  RichText.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 3/3/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

struct RichText {
    enum TextStyle {
        case none
        case bold
        case link
    }

    enum HeadingSize {
        case title
        case section
    }

    enum InlineElement {
        case text(TextStyle, () -> String)
    }

    enum BlockElement {
        case code(SwiftSyntaxNode)
        case heading(HeadingSize, () -> String)
        case paragraph([InlineElement])
    }

    var blocks: [BlockElement]
}
