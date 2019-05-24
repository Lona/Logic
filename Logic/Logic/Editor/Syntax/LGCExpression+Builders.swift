//
//  LGCExpression+Builders.swift
//  Logic
//
//  Created by Devin Abbott on 5/24/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public extension LGCExpression {
    static func makeMemberExpression(names: [String]) -> LGCExpression {
        let identifiers = names.map { LGCIdentifier(id: UUID(), string: $0) }

        return makeMemberExpression(identifiers: identifiers)
    }

    static func makeMemberExpression(identifiers: [LGCIdentifier]) -> LGCExpression {
        guard let first = identifiers.first else {
            fatalError("Cannot form empty memberExpression")
        }

        let base = LGCExpression.identifierExpression(id: UUID(), identifier: first)

        return identifiers.dropFirst().reduce(base, { (result, identifier) -> LGCExpression in
            return LGCExpression.memberExpression(
                id: UUID(),
                expression: result,
                memberName: identifier
            )
        })
    }
}
