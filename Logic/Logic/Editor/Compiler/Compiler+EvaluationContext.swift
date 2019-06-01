//
//  Compiler+Evaluate.swift
//  Logic
//
//  Created by Devin Abbott on 5/30/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension Compiler {
    enum Function {
        case stringConcat
        case enumInit(enumType: Unification.T, constructorType: Unification.T, caseName: String)
        case recordInit(type: Unification.T, members: KeyValueList<String, Unification.T>)
    }

    public indirect enum Memory: CustomDebugStringConvertible {
        public var debugDescription: String {
            switch self {
            case .any(let value):
                return "\(value)"
            case .enumInstance(let caseName, let values):
                return ".\(caseName)(\(values.map { "\($0)" }.joined(separator: ", ")))"
            case .recordInstance(let values):
                return "\(values)"
            }
        }

        case any(Any)
        case enumInstance(caseName: String, associatedValues: [LogicValue])
        case recordInstance(values: KeyValueList<String, LogicValue?>)

        public var anyValue: Any? {
            switch self {
            case .any(let value):
                return value
            case .enumInstance, .recordInstance:
                return nil
            }
        }
    }

    public struct LogicValue: CustomDebugStringConvertible {
        public var debugDescription: String {
            return "\(memory)"
        }

        public let type: Unification.T
        public let memory: Memory

        public init(_ type: Unification.T, _ memory: Memory) {
            self.type = type
            self.memory = memory
        }

        static let unit = LogicValue(.cons(name: "Void"), .any(0))
    }

    public class EvaluationContext {
        public init(values: [UUID: LogicValue] = [:]) {
            self.values = values
        }

        public var values: [UUID: LogicValue]
    }

    public typealias EvaluationResult = Result<EvaluationContext, Error>

    public static func evaluate(
        _ node: LGCSyntaxNode,
        rootNode: LGCSyntaxNode,
        scopeContext: ScopeContext,
        unificationContext: UnificationContext,
        substitution: Unification.Substitution,
        context: EvaluationContext
        ) -> EvaluationResult {

//        Swift.print("Handle", node.nodeTypeDescription)

        func processChildren(result: Result<EvaluationContext, Error>) -> EvaluationResult {
            return node.subnodes.reduce(result, { result, child in
                switch result {
                case .failure:
                    return result
                case .success(let newContext):
                    return evaluate(
                        child,
                        rootNode: rootNode,
                        scopeContext: scopeContext,
                        unificationContext: unificationContext,
                        substitution: substitution,
                        context: newContext
                    )
                }
            })
        }

        var result: EvaluationResult

        // Pre
        switch node {
        case .statement(.branch(id: _, condition: let condition, block: _)):
            result = evaluate(
                condition.node,
                rootNode: rootNode,
                scopeContext: scopeContext,
                unificationContext: unificationContext,
                substitution: substitution,
                context: context
                ).flatMap { context -> EvaluationResult in
                    if let value = context.values[condition.uuid],
                        let memory = value.memory.anyValue as? Bool, memory == true,
                        value.type == .cons(name: "Boolean") {

                        return processChildren(result: .success(context))
                    } else {
                        return .success(context)
                    }
            }
        default:
            result = processChildren(result: .success(context))
        }

        guard case .success(let context) = result else { return result }

        // Post
        switch node {
        case .literal(.boolean(id: _, value: let value)):
            context.values[node.uuid] = LogicValue(.cons(name: "Boolean"), .any(value))
        case .literal(.number(id: _, value: let value)):
            context.values[node.uuid] = LogicValue(.cons(name: "Number"), .any(value))
        case .literal(.string(id: _, value: let value)):
            context.values[node.uuid] = LogicValue(.cons(name: "String"), .any(value))
        case .literal(.color(id: _, value: let value)):
            context.values[node.uuid] = LogicValue(.cons(name: "CSSColor"), .any(value))
        case .expression(.literalExpression(id: _, literal: let literal)):
            if let value = context.values[literal.uuid] {
                context.values[node.uuid] = value
            }
        case .expression(.identifierExpression(id: _, identifier: let identifier)):
            Swift.print("ident", identifier.string)

            guard let patternId = scopeContext.identifierToPattern[identifier.uuid] else { break }

            Swift.print("pattern id", patternId)

            guard let value = context.values[patternId] else { break }

            Swift.print("value", value)

            context.values[identifier.uuid] = value
            context.values[node.uuid] = value
        case .expression(.memberExpression):
            Swift.print("member")

            guard let patternId = scopeContext.identifierToPattern[node.uuid] else { break }

            Swift.print("pattern id", patternId)

            guard let type = unificationContext.patternTypes[patternId] else { break }

            Swift.print("type", type)

            guard let value = context.values[patternId] else { break }

            Swift.print("value", value)

            context.values[node.uuid] = value
        case .expression(.binaryExpression(left: let left, right: let right, op: let op, id: _)):
            Swift.print("binary expr", left, right, op)
        case .expression(.functionCallExpression(id: _, expression: let expression, arguments: let arguments)):

            // Determine type based on return value of constructor function
            guard let functionType = unificationContext.nodes[expression.uuid] else { break }
            let resolvedType = Unification.substitute(substitution, in: functionType)
            guard case .fun(_, let returnType) = resolvedType else { break }

            // The function value to call
            guard let functionValue = context.values[expression.uuid] else { break }

            let args = arguments.map { context.values[$0.expression.uuid] }

            if let f = functionValue.memory.anyValue as? Function {
                switch f {
                case .stringConcat:
                    func concat(a: LogicValue?, b: LogicValue?) -> LogicValue {
                        guard let a = a?.memory.anyValue as? String else { return .unit }
                        guard let b = b?.memory.anyValue as? String else { return .unit }
                        return .init(.cons(name: "String"), .any(a + b))
                    }

                    Swift.print(f, "Args", args)
                    context.values[node.uuid] = concat(a: args[0], b: args[1])
                case .enumInit(_, _, let patternName):

                    Swift.print("init enum", returnType, patternName)

                    let filtered = args.compactMap { $0 }

                    if filtered.count != args.count { break }

                    context.values[node.uuid] = LogicValue(returnType, .enumInstance(caseName: patternName, associatedValues: filtered))

                    break
                case .recordInit(_, let members):
                    let values: [(String, LogicValue?)] = zip(members, args).map { pair, arg in
                        return (pair.0, arg)
                    }

                    context.values[node.uuid] = LogicValue(returnType, .recordInstance(values: KeyValueList(values)))
                    break
                }
            }
        case .declaration(.variable(_, let pattern, _, let initializer)):
            guard let initializer = initializer else { return .success(context) }

            context.values[pattern.uuid] = context.values[initializer.uuid]
        case .declaration(.function(_, name: let pattern, returnType: _, genericParameters: _, parameters: _, block: _)):
            guard let type = unificationContext.patternTypes[pattern.uuid] else { break }

            let fullPath = rootNode.declarationPath(id: node.uuid)

            switch fullPath {
            case ["String", "concat"]:
                context.values[pattern.uuid] = Compiler.LogicValue(type, .any(Function.stringConcat))
                break
            default:
                break
            }
        case .declaration(.record(id: _, name: let functionName, declarations: let declarations)):
            guard let type = unificationContext.patternTypes[functionName.uuid] else { break }

            let resolvedType = Unification.substitute(substitution, in: type)

            var parameterTypes: KeyValueList<String, Unification.T> = [:]

            declarations.forEach { declaration in
                switch declaration {
                case .variable(id: _, name: let pattern, annotation: let annotation, initializer: _):
                    guard let parameterType = unificationContext.patternTypes[pattern.uuid] else { break }

                    parameterTypes.set(parameterType, for: pattern.name)
                default:
                    break
                }
            }

            context.values[functionName.uuid] = Compiler.LogicValue(type, .any(Function.recordInit(type: resolvedType, members: parameterTypes)))
        case .declaration(.enumeration(id: _, name: let functionName, genericParameters: _, cases: let enumCases)):
            guard let type = unificationContext.patternTypes[functionName.uuid] else { break }

            let resolvedType = Unification.substitute(substitution, in: type)

            enumCases.forEach { enumCase in
                switch enumCase {
                case .placeholder:
                    break
                case .enumerationCase(_, name: let pattern, associatedValueTypes: _):
                    guard let consType = unificationContext.patternTypes[pattern.uuid] else { break }

                    let resolvedConsType = Unification.substitute(substitution, in: type)

                    Swift.print("enum case", pattern, resolvedConsType)

                    context.values[pattern.uuid] = Compiler.LogicValue(consType, .any(Function.enumInit(enumType: resolvedType, constructorType: resolvedConsType, caseName: pattern.name)))
                }
            }
        default:
            break
        }

        return .success(context)
    }
}

extension LGCSyntaxNode {
//    public func ancestors(in rootNode: LGCSyntaxNode) -> [LGCSyntaxNode] {
//        return rootNode.pathTo(id: uuid)?.dropLast().reversed() ?? []
//    }
//
//    public func parent(in rootNode: LGCSyntaxNode) -> LGCSyntaxNode? {
//        return ancestors(in: rootNode).first
//    }

    public func declarationPath(id: UUID) -> [String] {
        guard let path = pathTo(id: id) else { return [] }

        let declarations: [LGCDeclaration] = path.compactMap { node in
            switch node {
            case .declaration(let declaration):
                return declaration
            default:
                return nil
            }
        }

        let patterns: [LGCPattern] = declarations.compactMap { declaration in
            switch declaration {
            case .enumeration(_, let pattern, _, _),
                 .namespace(_, let pattern, _),
                 .record(_, let pattern, _),
                 .variable(_, let pattern, _, _),
                 .function(_, let pattern, _, _, _, _):
                return pattern
            default:
                return nil
            }
        }

        return patterns.map { $0.name }
    }
}
