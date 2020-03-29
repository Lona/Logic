//
//  LGCSyntax+Namespace.swift
//  Logic
//
//  Created by Devin Abbott on 3/29/20.
//  Copyright © 2020 BitDisco, Inc. All rights reserved.
//

import Foundation

extension LGCSyntaxNode: NamespaceVisitable {
    public func visit(_ visitor: Compiler.NamespaceVisitor) throws {
        if let contents = contents as? NamespaceVisitable {
            try contents.visit(visitor)
        }
    }
}

extension LGCDeclaration: NamespaceVisitable {
    public func visit(_ visitor: Compiler.NamespaceVisitor) throws {
        visitor.traversalConfig.needsRevisitAfterTraversingChildren = true

        switch (visitor.traversalConfig.isRevisit, self) {
        case (true, .variable(id: _, name: let pattern, annotation: _, initializer: _, _)):
            try visitor.declareValue(name: pattern.name, value: pattern.id)
        case (true, .function(id: _, name: let functionName, returnType: _, genericParameters: _, parameters: _, block: _, _)):
            try visitor.declareValue(name: functionName.name, value: functionName.id)
        case (false, .record(id: _, name: let pattern, genericParameters: _, declarations: _, _)):
            try visitor.declareType(name: pattern.name, type: pattern.id)

            // We push to the namespace path and traverse into children.
            // Variable declarations will be added to the namespace - we will then turn these into
            // getter functions for each member variable.
            visitor.pushPathComponent(name: pattern.name)
        case (true, .record(id: _, name: let pattern, genericParameters: _, declarations: _, _)):
            visitor.popPathComponent()

            // Built-ins should be constructed using literals
            if Compiler.builtInTypeConstructorNames.contains(pattern.name) { return }

            // Create constructor function
            try visitor.declareValue(name: pattern.name, value: pattern.id)
        case (true, .enumeration(id: _, name: let pattern, genericParameters: _, cases: let cases, _)):
            try visitor.declareType(name: pattern.name, type: pattern.id)

            visitor.pushPathComponent(name: pattern.name)

            // Add initializers for each case into the namespace
            try cases.forEach { enumCase in
                switch enumCase {
                case .placeholder:
                    break
                case .enumerationCase(id: _, name: let caseName, associatedValueTypes: _, _):
                    try visitor.declareValue(name: caseName.name, value: caseName.id)
                }
            }

            visitor.popPathComponent()
        case (false, .namespace(id: _, name: let pattern, declarations: _)):
            visitor.pushPathComponent(name: pattern.name)
        case (true, .namespace(id: _, name: _, declarations: _)):
            visitor.popPathComponent()
        default:
            break
        }
    }
}
