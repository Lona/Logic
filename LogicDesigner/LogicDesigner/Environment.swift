//
//  Environment.swift
//  Logic
//
//  Created by Devin Abbott on 5/15/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation
import Logic

enum LogicError: Error {
    case undefinedType(Environment.Context, UUID)
    case undefinedIdentifier(Environment.Context, UUID)
    case typeMismatch(Environment.Context, [UUID])

    var context: Environment.Context {
        switch self {
        case .undefinedType(let context, _), .undefinedIdentifier(let context, _):
            return context
        case .typeMismatch(let context, _):
            return context
        }
    }

    var nodeId: UUID {
        switch self {
        case .undefinedType(_, let id), .undefinedIdentifier(_, let id):
            return id
        case .typeMismatch(_, let ids):
            return ids.first!
        }
    }
}

public enum Environment {
    public static func evaluateType(_ node: LGCSyntaxNode, in context: Context) throws -> (TypeEntity, Context) {
        switch node {
        case .typeAnnotation(.typeIdentifier(id: _, identifier: let identifier, genericArguments: let arguments)):
            if !arguments.isEmpty {
                fatalError("Handle generics")
            }

            if let type = context.types.first(where: { entity in entity.name == identifier.string }) {
                return (type, context)
            } else {
                throw LogicError.undefinedType(context, node.uuid)
            }
        default:
            break
        }

        return (Types.unit, context)
    }
    public static func evaluate(_ node: LGCSyntaxNode, in context: Context) throws -> (LogicValue, Context) {
        switch node {
        case .program(let program):
            let newContext = try program.block.reduce(context, { result, node in
                return try evaluate(.statement(node), in: result).1
            })
            return (LogicValue.unit, newContext)
        case .identifier(let identifier):
            if let value = context.value(for: identifier.string) {
                return (value, context.with(annotation: value.memory.description, for: identifier.id))
            }

            throw LogicError.undefinedIdentifier(context, identifier.id)
        case .statement(.declaration(id: _, content: let declaration)):
            return try evaluate(.declaration(declaration), in: context)
        case .declaration(.variable(id: _, name: let name, annotation: let annotation, initializer: let initializer)):
            if let value = initializer {
                let evaluatedInitializer = try self.evaluate(.expression(value), in: context)

                guard let annotation = annotation else { fatalError("We require type annotations for now") }

                let evaluatedTypeAnnotation = try evaluateType(.typeAnnotation(annotation), in: context).0
                if evaluatedInitializer.0.type != evaluatedTypeAnnotation {
                    throw LogicError.typeMismatch(context, [node.uuid])
                }

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
            let evaluatedCondition = try evaluate(.expression(condition), in: context)

            if evaluatedCondition.0.type == Types.boolean, let memory = evaluatedCondition.0.memory as? [Bool] {
                if memory == [true] {
                    let resultingContext = try block.reduce(evaluatedCondition.1, { result, node in
                        return try evaluate(.statement(node), in: result).1
                    })
                    return (LogicValue.unit, resultingContext)
                } else {
                    return (LogicValue.unit, evaluatedCondition.1)
                }
            } else {
                throw LogicError.typeMismatch(evaluatedCondition.1, [condition.uuid])
            }
        case .expression(.identifierExpression(id: _, identifier: let identifier)):
            return try evaluate(.identifier(identifier), in: context)
        case .expression(.literalExpression(id: _, literal: let literal)):
            return try evaluate(.literal(literal), in: context)
        case .expression(.functionCallExpression(id: _, expression: .identifierExpression(id: _, identifier: let functionName), arguments: let args)):
            for type in context.types where type.name == functionName.string {
                // TODO: Verify subtypes?
                let memory: [Any] = try args.map { arg in try evaluate(.expression(arg.expression), in: context) }.map { $0.0.memory }
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
        public var annotations: [UUID: String]

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
            annotations: [:]
        )

        public func with(name: String, boundToValue value: LogicValue) -> Context {
            var copy = self
            copy.scopes[copy.scopes.count - 1][name] = value
            return copy
        }

        public func with(annotation: String, for nodeId: UUID) -> Context {
            var copy = self
            copy.annotations[nodeId] = annotation
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
