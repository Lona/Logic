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

public typealias LogicEditorFormattedElement = Formatter<LogicEditorElement>.FormattedElement
