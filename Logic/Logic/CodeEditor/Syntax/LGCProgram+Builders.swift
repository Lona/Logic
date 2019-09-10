//
//  LGCProgram+Builders.swift
//  Logic
//
//  Created by Devin Abbott on 5/29/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public extension LGCProgram {
    static func join(programs: [LGCProgram]) -> LGCProgram {
        let blocks = Array(programs.map { program in program.block.map { $0 } }.joined())

        return LGCProgram(id: UUID(), block: .init(blocks))
    }

    init(declarations: [LGCDeclaration]) {
        let statements = declarations.map { LGCStatement.declaration(id: UUID(), content: $0) }
        self = .init(id: UUID(), block: .init(statements))
    }

    static func make(from syntaxNode: LGCSyntaxNode) -> LGCProgram? {
        switch syntaxNode {
        case .program(let value):
            return value
        case .statement(let value):
            return .init(id: UUID(), block: .init([value]))
        case .declaration(let value):
            return .init(declarations: [value])
        case .topLevelDeclarations(let value):
            return LGCProgram(declarations: value.declarations.map { $0 })
        default:
            return nil
        }
    }
}
