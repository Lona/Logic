//
//  SwiftNativeTypes.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/18/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public typealias SwiftIdentifier = String
public typealias SwiftUUID = String

protocol LogicTextEditable {
    var textElements: [LogicEditorText] { get }
}

extension SwiftStatement: LogicTextEditable {
    var textElements: [LogicEditorText] {
        switch self {
        case .loop(let loop):
            return [
                LogicEditorText.dropdown("For", NSColor.black),
                LogicEditorText.dropdown(loop.pattern, Colors.editableText),
                LogicEditorText.unstyled("in"),
                LogicEditorText.dropdown(loop.expression, Colors.editableText),
            ]
        default:
            return []
        }
    }
}
