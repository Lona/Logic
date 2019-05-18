//
//  Unify.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 5/17/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation
import Logic

public extension GenericType {
    fileprivate var isTypeVariable: Bool {
        return name.starts(with: "?")
    }
}

public extension NativeType {
    fileprivate var isTypeVariable: Bool {
        return name.starts(with: "?")
    }
}


public extension TypeEntity {
    typealias Substitution = KeyValueList<TypeEntity, TypeEntity>
    typealias Constraint = (head: TypeEntity, tail: TypeEntity)

    enum UnificationError: Error {
        case nameMismatch(TypeEntity, TypeEntity)
        case genericArgumentsCountMismatch(TypeEntity, TypeEntity)
        case problem
    }

    static func update(constraints: [Constraint], using substitution: Substitution) -> [Constraint] {
        return constraints.map { constraint in
            var updated = constraint

            if let updatedHead = substitution[constraint.head] {
                updated.head = updatedHead
            }

            if let updatedTail = substitution[constraint.tail] {
                updated.tail = updatedTail
            }

            return updated
        }
    }

    static func unify(constraints: [Constraint], substitution: Substitution = Substitution()) -> Result<Substitution, UnificationError> {
        var substitution = substitution
        var constraints = constraints

        while let constraint = constraints.popLast() {
            Swift.print("constraint", constraint)

            if constraint.head.name == constraint.tail.name {
                continue
            }

            switch (constraint.head, constraint.tail) {
            case (.genericType(let head), let tail):
                if head.isTypeVariable {
                    substitution = substitution.with(tail, for: constraint.head)
                }
            case (let head, .genericType(let tail)):
                if tail.isTypeVariable {
                    substitution = substitution.with(head, for: constraint.tail)
                }
            case (.nativeType(let head), .nativeType(let tail)):
                if head.name == tail.name {
                    continue
                } else {
                    if head.isTypeVariable {
                        substitution = substitution.with(constraint.tail, for: constraint.head)
                    } else if tail.isTypeVariable {
                        substitution = substitution.with(constraint.head, for: constraint.tail)
                    } else {
                        return .failure(.nameMismatch(constraint.head, constraint.tail))
                    }
                }
            default:
                break
            }
        }

        return .success(substitution)
    }
}

//            case (TypeEntity.genericType(let a), TypeEntity.genericType(let b)):
//                if a.name == b.name {
//                    if a.isTypeVariable {
//                        substitution = substitution.with(constraint.head, for: constraint.tail)
//                    } else if b.isTypeVariable {
//                        substitution = substitution.with(constraint.tail, for: constraint.head)
//                    }
//
//                    // TODO compare cases
//                    continue
//                } else {
//
//                }
//
//                if a.name != b.name && !a.isTypeVariable && !b.isTypeVariable {
//                    return .failure(.nameMismatch(a, b))
//                }

//if a.name == b.name {
//    if a.cases.count != b.cases.count {
//        return .failure(.genericArgumentsCountMismatch(a, b))
//    } else {
//        zip(a.cases, b.cases).forEach { zipped in
//            constraints.append((head: ))
//        }
//    }
//} else {
//
//}
//
//if a.name != b.name && !a.isTypeVariable && !b.isTypeVariable {
//    return .failure(.nameMismatch(a, b))
//}
