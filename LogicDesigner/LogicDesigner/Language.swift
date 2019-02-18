//
//  Language.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/17/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

protocol TitledItem {
    var titleText: String { get }
}

extension RawRepresentable where RawValue == String {
    var titleText: String {
        return rawValue.prefix(1).uppercased() + rawValue.suffix(rawValue.count - 1)
    }
}

enum Language {
    enum DeclarationType: String, TitledItem {
        case variable
        case function

        static var all: [DeclarationType] {
            return [.variable, .function]
        }

        static let titleText = "Declarations".uppercased()
    }

    enum StatementType: String {
        case loop
        case branch

        static var all: [StatementType] {
            return [.loop, .branch]
        }

        static let titleText = "Statements".uppercased()
    }

    enum ExpressionType: String {
        case binary
        case prefix
        case postfix
        case literal
        case identifier

        static var all: [ExpressionType] {
            return [.binary, .prefix, .postfix, .literal, .identifier]
        }

        static let titleText = "Expressions".uppercased()
    }

    enum SyntaxType {
        case statement(StatementType), declaration
    }

//    static func title(of syntaxType: SyntaxType) -> String {
//        switch syntaxType {
//        case .declaration:
//            return "Declaration".uppercased()
//        case .statement:
//            return "Statement".uppercased()
//        }
//    }
//
//    static func options(restrictedTo syntaxType: SyntaxType) -> [String] {
//        switch syntaxType {
//        case .declaration:
//            let declarations = DeclarationType.all.map { $0.titleText }
//            return declarations
//        case .statement:
//            let statements = StatementType.all.map { $0.titleText }
//            return statements
//        }
//    }
}
