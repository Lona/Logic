//
//  Language.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/17/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

enum Language {
    enum SyntaxType: String {
        case statement, declaration
    }

    static var statements = [
        "Loop",
        "Branch",
    ]

    static var declarations = [
        "Variable",
        "Function"
    ]

    static func title(of syntaxType: SyntaxType) -> String {
        return syntaxType.rawValue.uppercased()
    }

    static func options(restrictedTo syntaxType: SyntaxType) -> [String] {
        switch syntaxType {
        case .declaration:
            return declarations
        case .statement:
            return Array([statements, declarations].joined())
        }
    }
}
