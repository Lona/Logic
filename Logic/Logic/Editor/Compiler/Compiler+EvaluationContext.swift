//
//  Compiler+Evaluate.swift
//  Logic
//
//  Created by Devin Abbott on 5/30/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

private extension NSColor {
    var hexString: String {
        guard let rgbColor = usingColorSpaceName(NSColorSpaceName.calibratedRGB) else {
            return "#FFFFFF"
        }
        let red = Int(round(rgbColor.redComponent * 0xFF))
        let green = Int(round(rgbColor.greenComponent * 0xFF))
        let blue = Int(round(rgbColor.blueComponent * 0xFF))
        let hexString = NSString(format: "#%02X%02X%02X", red, green, blue)
        return hexString as String
    }

    var rgbaString: String {
        guard let rgbColor = usingColorSpaceName(NSColorSpaceName.calibratedRGB) else {
            return "rgba(255,255,255,1)"
        }
        let red = Int(round(rgbColor.redComponent * 255))
        let green = Int(round(rgbColor.greenComponent * 255))
        let blue = Int(round(rgbColor.blueComponent * 255))
        let rgbaString = "rgba(\(red),\(green),\(blue),\(alphaComponent))"
        return rgbaString as String
    }

    var cssString: String {
        guard let rgbColor = usingColorSpaceName(NSColorSpaceName.calibratedRGB) else {
            return "#FFFFFF"
        }
        return alphaComponent < 1 ? rgbaString : hexString
    }
}

extension Compiler {
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
                        case .bool(let memory) = value.memory, memory == true,
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
            context.values[node.uuid] = .bool(value)
        case .literal(.number(id: _, value: let value)):
            context.values[node.uuid] = .number(value)
        case .literal(.string(id: _, value: let value)):
            context.values[node.uuid] = .string(value)
        case .literal(.color(id: _, value: let value)):
            let cssValue: LogicValue.Memory = .record(values: ["value": .string(value)])
            context.values[node.uuid] = LogicValue(.cssColor, cssValue)
        case .literal(.array(id: _, value: let expressions)):
            guard let type = unificationContext.nodes[node.uuid] else { break }
            let resolvedType = Unification.substitute(substitution, in: type)
            
            let values: [LogicValue] = expressions.compactMap { expression in context.values[expression.uuid] }

            if values.count == expressions.filter({ !$0.isPlaceholder }).count {
                context.values[node.uuid] = LogicValue(resolvedType, .array(values))
            }
        case .expression(.literalExpression(id: _, literal: let literal)):
            if let value = context.values[literal.uuid] {
                context.values[node.uuid] = value
            }
        case .expression(.identifierExpression(id: _, identifier: let identifier)):
//            Swift.print("ident", identifier.string)

            guard let patternId = scopeContext.identifierToPattern[identifier.uuid] else { break }

//            Swift.print("pattern id", patternId)

            guard let value = context.values[patternId] else { break }

//            Swift.print("value", value)

            context.values[identifier.uuid] = value
            context.values[node.uuid] = value
        case .expression(.memberExpression):
//            Swift.print("member")

            guard let patternId = scopeContext.identifierToPattern[node.uuid] else { break }

//            Swift.print("pattern id", patternId)

            guard let type = unificationContext.patternTypes[patternId] else { break }

//            Swift.print("type", type)

            guard let value = context.values[patternId] else { break }

//            Swift.print("value", value)

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

            if case .function(let f) = functionValue.memory {
                switch f {
                case .colorSaturate:
                    func saturate(color: LogicValue?, percent: LogicValue?) -> LogicValue {
                        let defaultColor = LogicValue.cssColor("black")
                        guard let colorString = color?.colorString else { return defaultColor }
                        guard case .number(let number)? = percent?.memory else { return defaultColor }

                        guard let nsColor = NSColor.parse(css: colorString) else { return defaultColor }

                        let newColor = NSColor(hue: nsColor.hueComponent, saturation: nsColor.saturationComponent * number, brightness: nsColor.brightnessComponent, alpha: nsColor.alphaComponent)

                        return LogicValue.cssColor(newColor.cssString)
                    }

//                    Swift.print(f, "Args", args)
                    context.values[node.uuid] = saturate(color: args[0], percent: args[1])
                case .stringConcat:
                    func concat(a: LogicValue?, b: LogicValue?) -> LogicValue {
                        guard case .string(let a)? = a?.memory else { return .unit }
                        guard case .string(let b)? = b?.memory else { return .unit }
                        return .init(.cons(name: "String"), .string(a + b))
                    }

//                    Swift.print(f, "Args", args)
                    context.values[node.uuid] = concat(a: args[0], b: args[1])
                case .enumInit(let patternName):

//                    Swift.print("init enum", returnType, patternName)

                    let filtered = args.compactMap { $0 }

                    if filtered.count != args.count { break }

                    context.values[node.uuid] = LogicValue(returnType, .enum(caseName: patternName, associatedValues: filtered))

                    break
                case .recordInit(let members):
                    let values: [(String, LogicValue?)] = zip(members, args).map { pair, arg in
                        return (pair.0, arg)
                    }

                    context.values[node.uuid] = LogicValue(returnType, .record(values: KeyValueList(values)))
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
                context.values[pattern.uuid] = LogicValue(type, .function(.stringConcat))
                break
            case ["CSSColor", "saturate"]:
                context.values[pattern.uuid] = LogicValue(type, .function(.colorSaturate))
                break
            default:
                break
            }
        case .declaration(.record(id: _, name: let functionName, genericParameters: _, declarations: let declarations)):
            guard let type = unificationContext.patternTypes[functionName.uuid] else { break }

            let resolvedType = Unification.substitute(substitution, in: type)

            var parameterTypes: KeyValueList<String, Unification.T> = [:]

            declarations.forEach { declaration in
                switch declaration {
                case .variable(id: _, name: let pattern, annotation: _, initializer: _):
                    guard let parameterType = unificationContext.patternTypes[pattern.uuid] else { break }

                    parameterTypes.set(parameterType, for: pattern.name)
                default:
                    break
                }
            }

            context.values[functionName.uuid] = LogicValue(resolvedType, .function(.recordInit(members: parameterTypes)))
        case .declaration(.enumeration(id: _, name: let functionName, genericParameters: _, cases: let enumCases)):
            guard let type = unificationContext.patternTypes[functionName.uuid] else { break }

            enumCases.forEach { enumCase in
                switch enumCase {
                case .placeholder:
                    break
                case .enumerationCase(_, name: let pattern, associatedValueTypes: _):
//                    guard let consType = unificationContext.patternTypes[pattern.uuid] else { break }

                    let resolvedConsType = Unification.substitute(substitution, in: type)

//                    Swift.print("enum case", pattern, resolvedConsType)

                    context.values[pattern.uuid] = LogicValue(resolvedConsType, .function(.enumInit(caseName: pattern.name)))
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
                 .record(_, let pattern, _, _),
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
