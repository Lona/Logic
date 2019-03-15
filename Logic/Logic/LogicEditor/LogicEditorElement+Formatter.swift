//
//  LogicEditor+Formatter.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

extension LogicEditorElement: FormattableElement {
    public var width: CGFloat {
        return measured(selected: false, offset: .zero).backgroundRect.width
    }
}

extension Formatter.Command where Element == LogicEditorElement {
    var focusableElements: [LogicEditorElement] {
        return elements.filter { $0.syntaxNodeID != nil }
    }
}

public typealias LogicEditorFormatCommand = Formatter<LogicEditorElement>.Command
