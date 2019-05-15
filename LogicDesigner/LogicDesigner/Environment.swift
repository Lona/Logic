//
//  Environment.swift
//  Logic
//
//  Created by Devin Abbott on 5/15/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation
import Logic

public enum Environment {
    public static func evaluate(_ node: LGCSyntaxNode, in context: Context) -> (LogicValue, Context) {
        switch node {
        case .program(let program):
            let newContext = program.block.reduce(context, { result, node in
                return evaluate(.statement(node), in: result).1
            })
            return (LogicValue.unit, newContext)
        case .identifier(let identifier):
            if let value = context.value(for: identifier.string) {
                return (value, context)
            }

            return (LogicValue.unit, context.with(error: .runtime("Undefined identifier \(identifier.string)", identifier.id)))
        case .statement(.declaration(id: _, content: let declaration)):
            return evaluate(.declaration(declaration), in: context)
        case .declaration(.variable(id: _, name: let name, annotation: _, initializer: let value)):
            if let value = value {
                let evaluatedInitializer = self.evaluate(.expression(value), in: context)
                let newContext = evaluatedInitializer.1.with(
                    name: name.name,
                    boundToValue: evaluatedInitializer.0
                )
                return (LogicValue.unit, newContext)
            }
        case .literal(.boolean(id: _, value: let literal)):
            return (LogicValue(type: Types.boolean, memory: [literal]), context)
        case .literal(.string(id: _, value: let literal)):
            return (LogicValue(type: Types.string, memory: [literal]), context)
        case .literal(.number(id: _, value: let literal)):
            return (LogicValue(type: Types.number, memory: [literal]), context)
        case .statement(.branch(id: _, condition: let condition, block: let block)):
            let evaluatedCondition = evaluate(.expression(condition), in: context).0

            if evaluatedCondition.type == Types.boolean, let memory = evaluatedCondition.memory as? [Bool] {
                if memory == [true] {
                    let resultingContext = block.reduce(context, { result, node in
                        return evaluate(.statement(node), in: result).1
                    })
                    return (LogicValue.unit, resultingContext)
                } else {
                    return (LogicValue.unit, context)
                }
            } else {
                Swift.print("Evaluating condition failed -- non-boolean type")
            }
        case .expression(.identifierExpression(id: _, identifier: let identifier)):
            return evaluate(.identifier(identifier), in: context)
        case .expression(.literalExpression(id: _, literal: let literal)):
            return evaluate(.literal(literal), in: context)
        case .expression(.functionCallExpression(id: _, expression: .identifierExpression(id: _, identifier: let functionName), arguments: let args)):
            for type in context.types where type.name == functionName.string {
                // TODO: Verify subtypes?
                let memory: [Any] = args.map { arg in evaluate(.expression(arg.expression), in: context) }.map { $0.0.memory }
                return (LogicValue(type: type, memory: memory), context)
            }
        default:
            break
        }

        return (LogicValue.unit, context)
    }
}

public extension Environment {
    enum Types {
        static let unit = TypeEntity.nativeType(.init(name: "Unit"))
        static let boolean = TypeEntity.nativeType(.init(name: "Boolean"))
        static let number = TypeEntity.nativeType(.init(name: "Number"))
        static let string = TypeEntity.nativeType(.init(name: "String"))

        static func list(_ element: TypeCaseParameterEntity) -> TypeEntity {
            return TypeEntity.genericType(
                .init(
                    name: "List",
                    cases: [
                        .normal("empty", []),
                        .normal("next", [.init(value: element)])
                    ]
                )
            )
        }

        static let genericList = {
            return list(.generic("Element"))
        }()
    }
}

public extension Environment {
    enum Values {
        static let `true` = LogicValue(type: Types.boolean, memory: [true])
        static let `false` = LogicValue(type: Types.boolean, memory: [false])
        static let emptyString = LogicValue(type: Types.string, memory: [""])
        static let zero = LogicValue(type: Types.number, memory: [0])
    }
}

public struct LogicValue {
    let type: TypeEntity
    let memory: [Any]

    static let unit = LogicValue(type: Environment.Types.unit, memory: [0])
}

extension Environment {
    public enum Error {
        case compiler(String, UUID)
        case runtime(String, UUID)
    }

    public struct Context {
        public var types: [TypeEntity]
        public var scopes: [[String: LogicValue]]
        public var errors: [Error]

        public static let standard = Context(
            types: [
                Types.unit,
                Types.boolean,
                Types.number,
                Types.string,
                Types.genericList
            ],
            scopes: [
                [
                    "none": LogicValue.unit
                ]
            ],
            errors: []
        )

        public func with(name: String, boundToValue value: LogicValue) -> Context {
            var copy = self
            copy.scopes[copy.scopes.count - 1][name] = value
            return copy
        }

        public func with(error: Error) -> Context {
            var copy = self
            copy.errors.append(error)
            return copy
        }

        public func value(for name: String) -> LogicValue? {
            for scope in scopes.reversed() {
                if let value = scope[name] {
                    return value
                }
            }

            return nil
        }
    }
}
