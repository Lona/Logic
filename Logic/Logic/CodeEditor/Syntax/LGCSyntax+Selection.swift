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

        func redirect(current: LGCSyntaxNode, remaining: [LGCSyntaxNode]) -> UUID {
            switch current {
            case .identifier:
                if let parent = remaining.last {
                    switch parent {
                    case .expression(.identifierExpression):
                        return redirect(current: parent, remaining: remaining.dropLast())
                    case .typeAnnotation(.typeIdentifier(_, identifier: let identifier, _)):
                        if identifier.uuid == current.uuid {
                            return redirect(current: parent, remaining: remaining.dropLast())
                        }
                    default:
                        break
                    }
                }
            case .expression(.memberExpression), .expression(.identifierExpression):
                if let parent = remaining.last {
                    switch parent {
                    case .expression(.functionCallExpression(let value)):
                        if value.arguments.contains(where: { arg in
                            switch arg {
                            case .argument(_, _, expression: let expression):
                                return current.uuid == expression.uuid
                            case .placeholder:
                                return false
                            }
                        }) {
                            break
                        }

                        return redirect(current: parent, remaining: remaining.dropLast())
                    default:
                        break
                    }
                }
            default:
                break
            }

            return current.uuid
        }

        return redirect(current: last, remaining: path.dropLast())
    }
}
