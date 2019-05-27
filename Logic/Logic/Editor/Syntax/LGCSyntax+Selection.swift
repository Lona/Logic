//
//  LGCSyntax+Selection.swift
//  Logic
//
//  Created by Devin Abbott on 5/24/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public extension LGCSyntaxNode {
    func redirectSelection(_ nodeId: UUID) -> UUID? {
        guard let path = self.pathTo(id: nodeId), let last = path.last else { return nil }

        switch last {
        case .expression(.memberExpression), .expression(.identifierExpression):
            if let parent = path.dropLast().last {
                switch parent {
                case .expression(.functionCallExpression):
                    return parent.uuid
                default:
                    break
                }
            }
        default:
            break
        }

        return last.uuid
    }
}
