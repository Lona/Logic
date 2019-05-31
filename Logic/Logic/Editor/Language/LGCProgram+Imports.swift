//
//  LGCProgram+Imports.swift
//  Logic
//
//  Created by Devin Abbott on 5/30/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public extension LGCProgram {
    func expandImports() -> LGCProgram {
        return expandImports(existingImports: .init()).program
    }

    func expandImports(existingImports: Set<String>) -> (program: LGCProgram, imports: Set<String>) {
        var imports = existingImports
        var statements: [LGCStatement] = []

        self.block.forEach { statement in
            switch statement {
            case .declaration(id: _, content: .importDeclaration(id: _, name: let pattern)):
                let libraryName = pattern.name

                if imports.contains(libraryName) { return }

                guard let library = Library.load(name: libraryName) else { return }
                guard case .program(let libraryProgram) = library else { return }

                imports.insert(libraryName)

                let expanded = libraryProgram.expandImports(existingImports: imports)

                imports = expanded.imports
                statements.append(contentsOf: expanded.program.block)
            default:
                statements.append(statement)
            }
        }

        return (LGCProgram(id: UUID(), block: .init(statements)), imports)
    }
}
