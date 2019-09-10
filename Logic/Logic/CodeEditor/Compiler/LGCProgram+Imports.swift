//
//  LGCProgram+Imports.swift
//  Logic
//
//  Created by Devin Abbott on 5/30/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public extension LGCProgram {
    func expandImports(importLoader: Library.Loader) -> LGCProgram {
        return expandImports(existingImports: .init(), importLoader: importLoader).program
    }

    func expandImports(
        existingImports: Set<String>,
        importLoader: Library.Loader
        ) -> (program: LGCProgram, imports: Set<String>) {
        var imports = existingImports
        var statements: [LGCStatement] = []

        self.block.forEach { statement in
            switch statement {
            case .declaration(id: _, content: .importDeclaration(id: _, name: let pattern)):
                // Keep the import statement in the resulting code so we can search for its node in suggestions
                statements.append(statement)

                let libraryName = pattern.name

                if imports.contains(libraryName) { return }

                guard let library = importLoader(libraryName) else {
                    Swift.print("Failed to import `\(libraryName)`")
                    return
                }

                guard let libraryProgram = LGCProgram.make(from: library) else {
                    Swift.print("Cannot import non-program file `\(libraryName)`")
                    return
                }

                imports.insert(libraryName)

                let expanded = libraryProgram.expandImports(existingImports: imports, importLoader: importLoader)

                imports = expanded.imports

                statements.append(contentsOf: expanded.program.block)
            default:
                statements.append(statement)
            }
        }

        return (LGCProgram(id: UUID(), block: .init(statements)), imports)
    }
}
