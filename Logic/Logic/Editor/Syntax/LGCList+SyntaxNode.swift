//
//  LGCList+SyntaxNode.swift
//  Logic
//
//  Created by Devin Abbott on 3/17/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

// Generic version
extension LGCList where T: SyntaxNodeProtocol {
    func find(id: UUID) -> LGCSyntaxNode? {
        return self.reduce(nil, { result, item in
            return result ?? item.find(id: id)
        })
    }

    func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCList {
        // Reverse list so we can easily prepend to the front
        let result = self.map { $0.replace(id: id, with: syntaxNode) }.reversed()

        var resultIterator = result.makeIterator()
        var output = LGCList<T>.empty

        while let current = resultIterator.next() {
            output = .next(current, output)
        }

        return output
    }

    public func pathTo(id: UUID) -> [LGCSyntaxNode]? {
        let found: [LGCSyntaxNode]? = self.reduce(nil, { result, node in
            if result != nil { return result }
            return node.pathTo(id: id)
        })

        return found
    }
}

// Preserve placeholders
extension LGCList where T == LGCStatement {
    func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCList {
        // Reverse list so we can easily prepend to the front
        let result = self.map { statement in statement.replace(id: id, with: syntaxNode) }.reversed()

        var resultIterator = result.makeIterator()
        var output = LGCList<T>.empty

        if let first = result.first, case .placeholderStatement = first {

        } else {
            output = .next(.placeholderStatement(id: UUID()), output)
        }

        while let current = resultIterator.next() {
            output = .next(current, output)
        }

        return output
    }
}

extension LGCList where T == LGCFunctionParameter {
    func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCList {
        // Reverse list so we can easily prepend to the front
        let result = self.map { statement in statement.replace(id: id, with: syntaxNode) }.reversed()

        var resultIterator = result.makeIterator()
        var output = LGCList<T>.empty

        if let first = result.first, case .placeholder = first {

        } else {
            output = .next(.placeholder(id: UUID()), output)
        }

        while let current = resultIterator.next() {
            output = .next(current, output)
        }

        return output
    }
}

// FunctionCallArguments aren't part of LGCSyntaxNode (yet)
extension LGCList where T == LGCFunctionCallArgument {
    func find(id: UUID) -> LGCSyntaxNode? {
        return self.reduce(nil, { result, item in
            return result ?? item.find(id: id)
        })
    }

    func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCList {
        // Reverse list so we can easily prepend to the front
        let result = self.map { statement in statement.replace(id: id, with: syntaxNode) }.reversed()

        var resultIterator = result.makeIterator()
        var output = LGCList<T>.empty

        while let current = resultIterator.next() {
            output = .next(current, output)
        }

        return output
    }
}
