//
//  LogicElementEditor+Formatter.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

extension LogicElement: FormattableElement {
    public var width: CGFloat {
        return measured(selected: false, offset: .zero).backgroundRect.width
    }
}

extension FormatterCommand where Element == LogicElement {
    var focusableElements: [LogicElement] {
        return elements.filter { $0.syntaxNodeID != nil }
    }
}

public typealias LogicEditorFormatCommand = FormatterCommand<LogicElement>
