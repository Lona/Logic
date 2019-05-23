//
//  Environment.swift
//  Logic
//
//  Created by Devin Abbott on 5/15/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation
import Logic

extension NameGenerator {
    static let type = NameGenerator(prefix: "?")
    static let variable = NameGenerator(prefix: "variable")
}

enum CompilerError: Error {
    case undefinedType(Environment.CompilerContext, UUID)
    case typeMismatch(Environment.CompilerContext, [UUID])

    var context: Environment.CompilerContext {
        switch self {
        case .undefinedType(let context, _), .typeMismatch(let context, _):
            return context
        }
    }

    var nodeId: UUID {
        switch self {
        case .undefinedType(_, let id):
            return id
        case .typeMismatch(_, let ids):
            return ids.first!
        }
    }
}

enum LogicError: Error {
    case undefinedType(Environment.RuntimeContext, UUID)
    case undefinedIdentifier(Environment.RuntimeContext, UUID)
    case typeMismatch(Environment.RuntimeContext, [UUID])

    var context: Environment.RuntimeContext {
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

public enum UnificationError: Error {
    case problem
}

public enum Environment {
    public typealias UnificationResult = Result<UnificationContext, UnificationError>

    public class UnificationContext {
        var types: [TypeEntity] = TypeEntity.standardTypes
        var constraints: [(TypeEntity, TypeEntity)] = []
        var substitution: [String: String] = [:]
        var nodes: [UUID: TypeEntity] = [:]

        public init() {}

        private var typeNameGenerator = NameGenerator(prefix: "?")

        func makeGenericName() -> String {
            return typeNameGenerator.next()
        }

        func makeGenericType() -> TypeEntity {
            return .enumType(.init(name: makeGenericName()))
        }

        public func unify() -> Result<UnificationContext, UnificationError> {
            return .success(self)
        }
    }

    public static func makeConstraints(_ rootNode: LGCSyntaxNode) -> UnificationResult {
        let initialContext: UnificationContext = UnificationContext()

        return rootNode.reduce(initialResult: .success(initialContext)) { (result, node, config) in
            switch result {
            case .failure:
                config.stopTraversal = true
                return result
            case .success(let context):
                switch node {
                case .statement(.branch(id: _, condition: let condition, block: _)):
                    context.nodes[condition.uuid] = Types.boolean

                    return .success(context)
                case .declaration(.variable(id: _, name: let pattern, annotation: let annotation, initializer: let initializer)):
                    guard let initializer = initializer, let annotation = annotation else {
                        config.ignoreChildren = true
                        return result
                    }

                    if annotation.isPlaceholder {
                        config.ignoreChildren = true
                        return result
                    }

                    let typeVariable = context.makeGenericType()
                    let annotationTypeName = Environment.typeOf(annotation, in: context.types) ?? context.makeGenericType()

                    // TODO: We still need to know the variable name (either via the node or the original/new name),
                    // though maybe we do alpha substition outside of this function
                    context.constraints.append((typeVariable, annotationTypeName))
                    context.nodes[pattern.uuid] = typeVariable
                    context.nodes[initializer.uuid] = typeVariable

                    return .success(context)
                case .expression(.identifierExpression(id: _, identifier: let identifier)):
                    let typeVariable = context.makeGenericType()

                    context.nodes[node.uuid] = typeVariable
                    context.nodes[identifier.uuid] = typeVariable

                    return .success(context)
                case .expression(.literalExpression(id: _, literal: let literal)):
                    if let type = context.nodes[literal.uuid] {
                        context.nodes[node.uuid] = type
                    }

                    return .success(context)
                case .expression(.binaryExpression(left: _, right: _, op: let op, id: _)):
                    switch op {
                    case .isEqualTo, .isNotEqualTo, .isLessThan, .isGreaterThan, .isLessThanOrEqualTo, .isGreaterThanOrEqualTo:
                        context.nodes[node.uuid] = Types.boolean

                        return .success(context)
                    case .setEqualTo: // TODO
                        break
                    }
                case .literal(.boolean):
                    context.nodes[node.uuid] = Types.boolean

                    return .success(context)
                default:
                    break
                }

                return Result.success(context)
            }
        }
    }

    public static func compile(_ node: LGCSyntaxNode, in context: CompilerContext) throws -> CompilerContext {
        switch node {
        case .program(let program):
            return try program.block.reduce(context, { result, node in
                return try compile(.statement(node), in: result)
            })
//        case .identifier(let identifier):
//            if let type = context.type(for: identifier.string) {
//                return (value, context.with(annotation: value.memory.description, for: identifier.id))
//            }
//
//            throw LogicError.undefinedIdentifier(context, identifier.id)
        case .statement(.declaration(id: _, content: let declaration)):
            return try compile(.declaration(declaration), in: context)
        case .declaration(.variable(id: _, name: let name, annotation: let annotation, initializer: let initializer)):
            if let value = initializer {
                let newContext = try compile(.expression(value), in: context)

                guard let annotation = annotation else { fatalError("We require type annotations for now") }

                guard let evaluatedTypeAnnotation = typeOf(annotation, in: newContext.types) else {
                    throw CompilerError.undefinedType(newContext, annotation.uuid)
                }

                return newContext
                    .with(name: name.name, boundToType: evaluatedTypeAnnotation)
                    .with(nodeId: annotation.uuid, boundToType: evaluatedTypeAnnotation)
                    .with(nodeId: value.uuid, boundToType: evaluatedTypeAnnotation)
            }
        case .statement(.branch(id: _, condition: let condition, block: _)):
            let newContext = try compile(.expression(condition), in: context)

            if newContext.nodeType[condition.uuid] != Types.boolean {
                throw CompilerError.typeMismatch(newContext, [condition.uuid])
            }

            return newContext
        case .expression(.identifierExpression(id: _, identifier: let identifier)):
            if identifier.isPlaceholder {
                return context
            }

            let newContext = try compile(.identifier(identifier), in: context)

            guard let boundType = newContext.type(for: identifier.string) else {
                throw CompilerError.undefinedType(context, node.uuid)
            }

            return newContext.with(nodeId: node.uuid, boundToType: boundType)
        case .expression(.literalExpression(id: _, literal: let literal)):
            let newContext = try compile(.literal(literal), in: context)

            guard let boundType = newContext.nodeType[literal.uuid] else {
                throw CompilerError.undefinedType(context, node.uuid)
            }

            return newContext.with(nodeId: node.uuid, boundToType: boundType)
//        case .expression(.functionCallExpression(id: _, expression: .identifierExpression(id: _, identifier: let functionName), arguments: let args)):
//            for type in context.types where type.name == functionName.string {
//                // TODO: Verify subtypes?
//                let memory: [Any] = try args.map { arg in try evaluate(.expression(arg.expression), in: context) }.map { $0.0.memory }
//                return (LogicValue(type: type, memory: memory), context)
//            }
        case .literal(.boolean):
            return context.with(nodeId: node.uuid, boundToType: Types.boolean)
        case .literal(.string):
            return context.with(nodeId: node.uuid, boundToType: Types.string)
        case .literal(.number):
            return context.with(nodeId: node.uuid, boundToType: Types.number)
        default:
            break
        }

        return context
    }

    public static func unificationType(of annotation: LGCTypeAnnotation) -> Unification.T {
        switch annotation {
        case .typeIdentifier(id: _, identifier: let identifier, genericArguments: let arguments):
            if identifier.isPlaceholder { return .evar(NameGenerator.type.next()) }

            let parameters = arguments.map { self.unificationType(of: $0) }

            return .cons(name: identifier.string, parameters: parameters)
        default:
            fatalError("Not supported")
        }
    }

    public static func typeOf(_ annotation: LGCTypeAnnotation, in types: [TypeEntity]) -> TypeEntity? {
        switch annotation {
        case .typeIdentifier(id: _, identifier: let identifier, genericArguments: let arguments):

            // TODO: Placeholder annotations don't have a type... should we introduce a type variable?
            if identifier.isPlaceholder { return nil }

            if !arguments.isEmpty {
                fatalError("Handle generics")
            }

            if let type = types.first(where: { entity in entity.name == identifier.string }) {
                return type
            } else {
                return nil
            }
        default:
            break
        }

        return Types.unit
    }
    public static func evaluate(_ node: LGCSyntaxNode, in context: RuntimeContext) throws -> (LogicValue, RuntimeContext) {
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

                guard let evaluatedTypeAnnotation = typeOf(annotation, in: context.types) else {
                    throw LogicError.undefinedType(context, annotation.uuid)
                }

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

        static func list(_ element: TypeParameter) -> TypeEntity {
            return TypeEntity.enumType(
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

extension TypeEntity {
    public static let standardTypes: [TypeEntity] = [
        Environment.Types.unit,
        Environment.Types.boolean,
        Environment.Types.number,
        Environment.Types.string,
        Environment.Types.genericList
    ]
}

extension Environment {
    public struct CompilerContext {
        public var types: [TypeEntity]
        public var scopes: [[String: TypeEntity]]
        public var nodeType: [UUID: TypeEntity]

        public static let standard = CompilerContext(
            types: TypeEntity.standardTypes,
            scopes: [
                [
                    "none": Types.unit
                ]
            ],
            nodeType: [:]
        )

        public func type(for name: String) -> TypeEntity? {
            for scope in scopes.reversed() {
                if let type = scope[name] {
                    return type
                }
            }

            return nil
        }

        public func with(name: String, boundToType type: TypeEntity) -> CompilerContext {
            var copy = self
            copy.scopes[copy.scopes.count - 1][name] = type
            return copy
        }

        public func with(nodeId: UUID, boundToType type: TypeEntity) -> CompilerContext {
            var copy = self
            copy.nodeType[nodeId] = type
            return copy
        }
    }

    public struct RuntimeContext {
        public var types: [TypeEntity]
        public var scopes: [[String: LogicValue]]
        public var annotations: [UUID: String]

        public static let standard = RuntimeContext(
            types: TypeEntity.standardTypes,
            scopes: [
                [
                    "none": LogicValue.unit
                ]
            ],
            annotations: [:]
        )

        public func with(name: String, boundToValue value: LogicValue) -> RuntimeContext {
            var copy = self
            copy.scopes[copy.scopes.count - 1][name] = value
            return copy
        }

        public func with(annotation: String, for nodeId: UUID) -> RuntimeContext {
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
