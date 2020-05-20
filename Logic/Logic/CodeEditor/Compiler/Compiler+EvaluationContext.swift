//
//  Compiler+Evaluate.swift
//  Logic
//
//  Created by Devin Abbott on 5/30/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation
import Colors
import class SwiftGraph.UnweightedGraph

private extension Color {
    var rgbaString: String {
        let r = Int(rgb.red * 255)
        let g = Int(rgb.green * 255)
        let b = Int(rgb.blue * 255)
        let a = round(alpha * 100) / 100
        return "rgba(\(r),\(g),\(b),\(a))"
    }

    var cssString: String {
        return alpha < 1 ? rgbaString : hexString.uppercased()
    }

    init(cssString: String) {
        let cssColor = parseCSSColor(cssString) ?? CSSColor(0, 0, 0, 0)
        var colorValue = Color(redInt: cssColor.r, greenInt: cssColor.g, blueInt: cssColor.b)
        colorValue.alpha = Float(cssColor.a)
        self = colorValue
    }
}

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
        guard let _ = usingColorSpaceName(NSColorSpaceName.calibratedRGB) else {
            return "#FFFFFF"
        }
        return alphaComponent < 1 ? rgbaString : hexString
    }
}

extension Compiler {
    public struct EvaluationThunk {
        public init(label: String? = nil, dependencies: [UUID] = [], _ f: @escaping ([LogicValue]) -> LogicValue) {
            self.label = label
            self.dependencies = dependencies
            self.f = f
        }

        public var label: String?
        public var dependencies: [UUID]
        public var f: ([LogicValue]) -> LogicValue
    }

    public class EvaluationContext {

        public func copy() -> EvaluationContext {
            return EvaluationContext(values: values, thunks: thunks)
        }

        public init(values: [UUID: LogicValue] = [:], thunks: [UUID: EvaluationThunk] = [:]) {
            self.values = values
            self.thunks = thunks
        }

        private var values: [UUID: LogicValue]
        public var thunks: [UUID: EvaluationThunk]

        public var cycles: [[UUID]] {
            if let cycles = cachedCycles {
                return cycles
            }

            let cycles = detectCycles()
            cachedCycles = cycles
            return cycles
        }

        public var hasCycle: Bool {
            return !cycles.isEmpty
        }

        private var cachedCycles: [[UUID]]?

        private func detectCycles() -> [[UUID]] {
            let graph = UnweightedGraph<UUID>(vertices: Array(thunks.keys))

            // Adding edges to SwiftGraph is significantly faster when using indices than vertices directly,
            // so we first determine the index of each vertex
            var indexOfVertex: [UUID: Int] = [:]
            graph.vertices.enumerated().forEach { index, vertex in
                indexOfVertex[vertex] = index
            }

            thunks.forEach { (arg) in
                let (uuid, thunk) = arg
                thunk.dependencies.forEach { dependency in
                    guard let thunkIndex = indexOfVertex[uuid], let dependencyIndex = indexOfVertex[dependency] else {
//                        Swift.print("WARNING: Missing thunk for \(dependency) in cycle detection")
                        return
                    }

                    graph.addEdge(fromIndex: thunkIndex, toIndex: dependencyIndex, directed: true)
                }
            }

            // First, detect if any cycles exist O(n)
            if graph.isDAG {
                return []
            }

            // If cycles do exist, find them
            return graph.detectCycles()
        }

        public func add(uuid: UUID, _ thunk: EvaluationThunk) {
            thunks[uuid] = thunk
        }

        public func evaluate(uuid: UUID, logLevel: StandardConfiguration.LogLevel = .none) -> LogicValue? {
            if hasCycle && cycles.joined().contains(uuid) {
                return nil
            }

            if let value = values[uuid] {
                return value
            }

            if let thunk = thunks[uuid] {
                if logLevel == .verbose, let label = thunk.label {
                    Swift.print("Evaluate thunk: \(label) \(uuid) - [\(thunk.dependencies.map { $0.uuidString }.joined(separator: ", "))]")
                }

                let resolvedDependencies = thunk.dependencies.map { evaluate(uuid: $0, logLevel: logLevel) }

                if let index = resolvedDependencies.firstIndex(where: { $0 == nil }) {
                    if logLevel == .verbose, let label = thunk.label {
                        Swift.print("Evaluate thunk: \(label) - FAILED")

                        let unresolved = thunk.dependencies[index]
                        if let unresolvedThunk = thunks[unresolved] {
                            Swift.print("Unresolved thunk", unresolvedThunk.label ?? "")
                        } else {
                            Swift.print("Missing thunk", unresolved)
                        }
                    }

                    return nil
                } else {
                    if logLevel == .verbose, let label = thunk.label {
                        Swift.print("Evaluate thunk: \(label) - SUCCESS")
                    }
                }
                let result = thunk.f(resolvedDependencies.compactMap { $0 })
                values[uuid] = result
                return result
            }

            return nil
        }
    }

    public typealias EvaluationResult = Result<EvaluationContext, Error>

    private static func defaultValue(forTypeBuiltInType type: Unification.T) -> LogicValue? {
        switch type {
        case .cons(name: let name, parameters: _):
            switch name {
            case "Boolean":
                return .init(type, .bool(false))
            case "Number":
                return .init(type, .number(0))
            case "String":
                return .init(type, .string(""))
            case "Color": // TODO: This could get picked up from our Color record definition
                return .color("black")
            case "Array":
                return .init(type, .array([]))
            default:
                return nil
            }
        case .evar, .gen, .fun:
            return nil
        }
    }

    public static func compile(
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
                    return compile(
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
            result = compile(
                condition.node,
                rootNode: rootNode,
                scopeContext: scopeContext,
                unificationContext: unificationContext,
                substitution: substitution,
                context: context
                ).flatMap({ context -> EvaluationResult in
                    if let value = context.evaluate(uuid: condition.uuid),
                        case .bool(let memory) = value.memory, memory == true,
                        value.type == .bool {

                        return processChildren(result: .success(context))
                    } else {
                        return .success(context)
                    }
                })
        default:
            result = processChildren(result: .success(context))
        }

        guard case .success(let context) = result else { return result }

        // Post
        switch node {
        case .literal(.boolean(id: _, value: let value)):
            context.add(uuid: node.uuid, EvaluationThunk(label: "Boolean Literal", { _ in LogicValue.bool(value) }))
        case .literal(.number(id: _, value: let value)):
            context.add(uuid: node.uuid, EvaluationThunk(label: "Number Literal", { _ in LogicValue.number(value) }))
        case .literal(.string(id: _, value: let value)):
            context.add(uuid: node.uuid, EvaluationThunk(label: "String Literal", { _ in LogicValue.string(value) }))
        case .literal(.color(id: _, value: let value)):
            context.add(uuid: node.uuid, EvaluationThunk(label: "Color Literal", { _ in LogicValue.color(value) }))
        case .literal(.array(id: _, value: let expressions)):
            guard let type = unificationContext.nodes[node.uuid] else {
                Swift.print("Failed to unify type of array")
                break
            }

            let resolvedType = Unification.substitute(substitution, in: type)

            let dependencies = expressions.filter { !$0.isPlaceholder }.map { $0.uuid }

            context.add(uuid: node.uuid, EvaluationThunk(label: "Array Literal", dependencies: dependencies, { values in
                return LogicValue(resolvedType, .array(values))
            }))
        case .expression(.literalExpression(id: _, literal: let literal)):
            context.add(uuid: node.uuid, EvaluationThunk(label: "Literal expression", dependencies: [literal.uuid], { values in
                return values[0]
            }))
        case .expression(.identifierExpression(id: _, identifier: let identifier)):
            guard let patternId = scopeContext.identifierToPattern[identifier.uuid] else {
//                Swift.print("Failed to find pattern for identifier expression")
                break
            }

            context.add(uuid: identifier.uuid, EvaluationThunk(label: "Identifier \(identifier.string)", dependencies: [patternId], { values in
                return values[0]
            }))
            context.add(uuid: node.uuid, EvaluationThunk(label: "Identifier expression \(identifier.string)", dependencies: [patternId], { values in
                return values[0]
            }))
        case .expression(.memberExpression):
            guard let patternId = scopeContext.identifierToPattern[node.uuid] else {
                Swift.print("Failed to find pattern for member expression")
                break
            }

            context.add(uuid: node.uuid, EvaluationThunk(label: "Member expression",  dependencies: [patternId], { values in
                return values[0]
            }))
        case .expression(.functionCallExpression(id: _, expression: let expression, arguments: let arguments)):

            // Determine type based on return value of constructor function
            guard let functionType = unificationContext.nodes[expression.uuid] else {
                Swift.print("Unknown type of functionCallExpression")
                break
            }

            let resolvedType = Unification.substitute(substitution, in: functionType)

            guard case .fun(_, let returnType) = resolvedType else {
                Swift.print("Invalid functionCallExpression type (only functions are valid)")
                break
            }

            let dependencies = [expression.uuid] + arguments.compactMap({
                switch $0 {
                case .argument(_, _, .identifierExpression(_, let identifier)) where identifier.isPlaceholder:
                    return nil
                case .argument(_, _, let expression):
                    return expression.uuid
                case .placeholder:
                    return nil
                }
            })

            context.add(uuid: node.uuid, EvaluationThunk(label: "functionCallExpression", dependencies: dependencies, { values in
                let functionValue = values[0]
                let args = Array(values.dropFirst())

                if case .function(let f) = functionValue.memory {
                    switch f {
                    case .value(let value):
                        return value
                    case .inline(let function):
                        return function(args)
                    case .colorFromHSL:
                        func makeColor(componentValues: [LogicValue]) -> LogicValue {
                            let numbers: [CGFloat] = componentValues.map { componentValue in
                                guard case .number(let number) = componentValue.memory else { return 0 }
                                return number
                            }

                            let newSwiftColor = Color(hue: Float(numbers[0]), saturation: Float(numbers[1]), luminosity: Float(numbers[2]))

                            return LogicValue.color(newSwiftColor.cssString)
                        }

                        if args.count >= 3 {
                            return makeColor(componentValues: args)
                        } else {
                            break
                        }
                    case .colorSetHue:
                        func setHue(colorValue: LogicValue?, numberValue: LogicValue?) -> LogicValue {
                            let defaultColor = LogicValue.color("black")
                            guard let colorString = colorValue?.colorString else { return defaultColor }
                            guard case .number(let number)? = numberValue?.memory else { return defaultColor }

                            let originalSwiftColor = Color(cssString: colorString)
                            let components = originalSwiftColor.hsl
                            let newSwiftColor = Color(hue: Float(number), saturation: components.saturation, luminosity: components.luminosity)

                            return LogicValue.color(newSwiftColor.cssString)
                        }

                        if args.count >= 2 {
                            return setHue(colorValue: args[0], numberValue: args[1])
                        } else {
                            break
                        }
                    case .colorSetSaturation:
                        func setSaturation(colorValue: LogicValue?, numberValue: LogicValue?) -> LogicValue {
                            let defaultColor = LogicValue.color("black")
                            guard let colorString = colorValue?.colorString else { return defaultColor }
                            guard case .number(let number)? = numberValue?.memory else { return defaultColor }

                            let originalSwiftColor = Color(cssString: colorString)
                            let components = originalSwiftColor.hsl
                            let newSwiftColor = Color(hue: components.hue, saturation: Float(number), luminosity: components.luminosity)

                            return LogicValue.color(newSwiftColor.cssString)
                        }

                        if args.count >= 2 {
                            return setSaturation(colorValue: args[0], numberValue: args[1])
                        } else {
                            break
                        }
                    case .colorSetLightness:
                        func setLuminosity(colorValue: LogicValue?, numberValue: LogicValue?) -> LogicValue {
                            let defaultColor = LogicValue.color("black")
                            guard let colorString = colorValue?.colorString else { return defaultColor }
                            guard case .number(let number)? = numberValue?.memory else { return defaultColor }

                            let originalSwiftColor = Color(cssString: colorString)
                            let components = originalSwiftColor.hsl
                            let newSwiftColor = Color(hue: components.hue, saturation: components.saturation, luminosity: Float(number))

                            return LogicValue.color(newSwiftColor.cssString)
                        }

                        if args.count >= 2 {
                            return setLuminosity(colorValue: args[0], numberValue: args[1])
                        } else {
                            break
                        }
                    case .colorSaturate:
                        func saturate(colorValue: LogicValue?, numberValue: LogicValue?) -> LogicValue {
                            let defaultColor = LogicValue.color("black")
                            guard let colorString = colorValue?.colorString else { return defaultColor }
                            guard case .number(let number)? = numberValue?.memory else { return defaultColor }

                            guard let nsColor = NSColor.parse(css: colorString) else { return defaultColor }

                            let newColor = NSColor(hue: nsColor.hueComponent, saturation: nsColor.saturationComponent * number, brightness: nsColor.brightnessComponent, alpha: nsColor.alphaComponent)

                            return LogicValue.color(newColor.cssString)
                        }

                        if args.count >= 2 {
                            return saturate(colorValue: args[0], numberValue: args[1])
                        } else {
                            break
                        }
                    case .stringConcat:
                        func concat(a: LogicValue?, b: LogicValue?) -> LogicValue {
                            guard case .string(let a)? = a?.memory else { return .unit }
                            guard case .string(let b)? = b?.memory else { return .unit }
                            return .init(.string, .string(a + b))
                        }

                        //                    Swift.print(f, "Args", args)
                        return concat(a: args[0], b: args[1])
                    case .enumInit(let patternName):

                        //                    Swift.print("init enum", returnType, patternName)

                        let filtered = args.compactMap { $0 }

                        if filtered.count != args.count { break }

                        return LogicValue(returnType, .enum(caseName: patternName, associatedValues: filtered))
                    case .recordInit(let members):
                        let values: [(String, LogicValue?)] = members.reduce([]) { (result, item) in
                            let argument = arguments.first(where: { argument in
                                switch argument {
                                case .argument(_, label: .some(item.0), _):
                                    return true
                                case .argument, .placeholder:
                                    return false
                                }
                            })
                            let argumentValue: LogicValue? = argument.flatMap({ argument in
                                switch argument {
                                case .argument(_, _, .identifierExpression(_, let identifier)) where identifier.isPlaceholder:
                                    // In the case of a placeholder identifier, continue running the function as if no argument is passed
                                    return nil
                                case .argument(_, _, let expression):
                                    guard let dependencyIndex = dependencies.firstIndex(of: expression.uuid) else { return nil }
                                    return values[dependencyIndex]
                                case .placeholder:
                                    return nil
                                }
                            })
                            switch argumentValue {
                            case .some:
                                return result + [(item.0, argumentValue)]
                            case .none:
                                return result + [(item.0, item.1.1)]
                            }
                        }

                        return LogicValue(returnType, .record(values: Dictionary(uniqueKeysWithValues: values)))
                    case .arrayAt:
                        func arrayAt(arrayValue: LogicValue?, numberValue: LogicValue?) -> LogicValue {
                            guard let array = arrayValue?.array else { return .unit }
                            guard case .number(let float)? = numberValue?.memory else { return .unit }
                            let number = Int(float)
                            if number < 0 || number > array.count - 1 { return .unit }
                            return array[number]
                        }

                        if args.count >= 2 {
                            let result = arrayAt(arrayValue: args[0], numberValue: args[1])
                            Swift.print("Access array at \(args[1]): \(result)")
                            return result
                        } else {
                            break
                        }
                    case .numberRange:
                        func numberRange(from startValue: LogicValue?, to endValue: LogicValue?, strideValue: LogicValue?) -> LogicValue {
                            guard case .number(let start)? = startValue?.memory,
                                case .number(let end)? = endValue?.memory
                                else { return .unit }

                            var step: CGFloat
                            if case .number(let value)? = strideValue?.memory {
                                step = value
                            } else {
                                step = 1
                            }

                            let range = stride(from: start, to: end, by: step).map { LogicValue.number($0) }
                            return LogicValue(.array(.number), .array(range))
                        }

                        if args.count >= 2 {
                            let result = numberRange(from: args[0], to: args[1], strideValue: args.count > 2 ? args[2] : nil)
                            Swift.print("Access array at \(args[1]): \(result)")
                            return result
                        } else {
                            break
                        }
                    case .impl(let declarationID):
                        let currentScopeContext = scopeContext.copy()

                        guard let functionDeclarationNode = rootNode.find(id: declarationID) else { return .unit }
                        guard case .declaration(.function(let functionData)) = functionDeclarationNode else { return .unit }

                        let functionEvaluationContext = context.copy()

                        currentScopeContext.addToScope(pattern: functionData.name)
                        currentScopeContext.pushScope()

                        functionData.parameters.filter({ !$0.isPlaceholder }).enumerated().forEach { index, parameter in
                            switch parameter {
                            case .placeholder:
                                break
                            case .parameter(id: _, localName: let pattern, annotation: _, defaultValue: let defaultValue, _):
                                currentScopeContext.addToScope(pattern: pattern)

                                let expressionId: UUID? = arguments.reduce(nil, { acc, arg in
                                    if acc != nil { return acc }

                                    switch arg {
                                    case .argument(id: _, label: .some(pattern.name), expression: let expression):
                                        return expression.uuid
                                    default:
                                        return nil
                                    }
                                })

                                if let expressionId = expressionId {
                                    functionEvaluationContext.add(uuid: pattern.uuid, EvaluationThunk(label: "Function argument passed for \(pattern.name)", dependencies: [expressionId], { values in
                                        return values[0]
                                    }))
                                } else if case .value(id: _, expression: let expression) = defaultValue {
                                    functionEvaluationContext.add(uuid: pattern.uuid, EvaluationThunk(label: "Function argument default value for \(pattern.name)", dependencies: [expression.uuid], { values in
                                        return values[0]
                                    }))
                                } else {
                                    func addThunk(value: LogicValue) {
                                        functionEvaluationContext.add(uuid: pattern.uuid, EvaluationThunk(label: "Function argument default value for type of \(pattern.name)", dependencies: [], { _ in
                                            return value
                                        }))
                                    }

                                    guard let parameterType = unificationContext.patternTypes[pattern.uuid] else {
                                        addThunk(value: .unit)
                                        return
                                    }

                                    let resolvedType = Unification.substitute(substitution, in: parameterType)

                                    if let value = self.defaultValue(forTypeBuiltInType: resolvedType) {
                                        addThunk(value: value)
                                        return
                                    }

                                    switch resolvedType {
                                    case .cons(name: let typeName, parameters: _):
                                        guard let typeDeclarationID = scopeContext.namespace.types[[typeName]] else { break }
                                        guard case let .declaration(declaration) = rootNode.contents.parentOf(target: typeDeclarationID, includeTopLevel: false) else { break }
                                        let declaredVariables = declaration.declaredRecordVariables
                                        let initializers = declaredVariables.map { $0.2 }
                                        functionEvaluationContext.add(uuid: pattern.uuid, EvaluationThunk(label: "Function argument default value for type of \(pattern.name) (recordInit)", dependencies: initializers.map { $0.uuid }, { values in
                                            let members = Array(zip(declaredVariables.map { ($0.0.name) }, values))
                                            return LogicValue(resolvedType, .record(values: Dictionary(uniqueKeysWithValues: members)))
                                        }))
                                        return
                                    default:
                                        break
                                    }

                                    addThunk(value: .unit)
                                    return
                                }
                            }
                        }

                        func processFunctionBody(result: Result<EvaluationContext, Error>) -> EvaluationResult {
                            return functionDeclarationNode.subnodes.reduce(result, { result, child in
                                switch result {
                                case .failure:
                                    return result
                                case .success(let newContext):
                                    return compile(
                                        child,
                                        rootNode: rootNode,
                                        scopeContext: currentScopeContext,
                                        unificationContext: unificationContext,
                                        substitution: substitution,
                                        context: newContext
                                    )
                                }
                            })
                        }

                        let functionResult = processFunctionBody(result: .success(functionEvaluationContext))

                        switch functionResult {
                        case .success(let subcontext):
                            // Find the return statement within the function body
                            // TODO: Keep track of or figure out which return statement actually executed
                            if let returnValue: LogicValue = functionDeclarationNode.reduce(initialResult: nil, f: { (acc, currentNode, config) in
                                switch currentNode {
                                case .statement(.returnStatement(id: _, expression: let expression)):
                                    config.stopTraversal = true
                                    return subcontext.evaluate(uuid: expression.uuid)
                                default:
                                    return nil
                                }
                            }) {
                                return returnValue
                            }
                        case .failure(let error):
                            Swift.print("Error: Failed to evaluate custom function implementation. \(error)")
                            return .unit
                        }
                    }
                }

                return .unit
            }))
        case .declaration(.variable(_, let pattern, _, let initializer, _)):
            guard let initializer = initializer else { return .success(context) }

            context.add(uuid: pattern.uuid, EvaluationThunk(label: "Variable initializer for \(pattern.name)", dependencies: [initializer.uuid], { values in
                return values[0]
            }))
        case .declaration(.function(_, name: let pattern, returnType: _, genericParameters: _, parameters: _, block: _, _)):
            guard let type = unificationContext.patternTypes[pattern.uuid] else { break }

            let fullPath = rootNode.declarationPath(id: node.uuid)

            context.add(uuid: pattern.uuid, EvaluationThunk(label: "Function declaration for \(pattern.name)", { values in
                let f = LogicValue.Function(qualifiedName: fullPath) ?? LogicValue.Function(declarationID: node.uuid)
                return LogicValue(type, .function(f))
            }))
        case .declaration(.record(id: _, name: let functionName, genericParameters: _, declarations: let declarations, _)):
            guard let type = unificationContext.patternTypes[functionName.uuid] else {
                Swift.print("Unknown type of record \(functionName.name)")
                break
            }

            let resolvedType = Unification.substitute(substitution, in: type)

            var dependencies: [UUID] = []

            declarations.forEach { declaration in
                switch declaration {
                case .variable(id: _, name: _, annotation: _, initializer: .some(let initializer), _):
                    dependencies.append(initializer.uuid)
                default:
                    break
                }
            }

            declarations.forEach { declaration in
                switch declaration {
                case .variable(id: _, name: let pattern, annotation: _, initializer: _, _):
                    guard let parameterType = unificationContext.patternTypes[pattern.uuid] else { break }

                    // Synthesize member getter
                    context.add(uuid: pattern.uuid, EvaluationThunk(label: "Getter for \(functionName.name).\(pattern.name)", dependencies: [], { values in
                        let f = LogicValue.Function.init(inline: { arguments in
                            if case .record(let members) = arguments.first?.memory,
                                case let member?? = members[pattern.name] {
                                return member
                            }
                            return .unit
                        })
                        return LogicValue(parameterType, .function(f))
                    }))
                default:
                    break
                }
            }

            context.add(uuid: functionName.uuid, EvaluationThunk(label: "Record initializer for \(functionName.name)", dependencies: dependencies, { values in
                var parameterTypes: [String: (Unification.T, LogicValue?)] = [:]

                var index: Int = 0

                declarations.forEach { declaration in
                    switch declaration {
                    case .variable(id: _, name: let pattern, annotation: _, initializer: let initializer, _):
                        guard let parameterType = unificationContext.patternTypes[pattern.uuid] else { break }

                        // Determine member type from the synthesized getter
                        // TODO: Should we still expose the original variable's type, rather than grabbing the return value of this function?
                        switch parameterType {
                        case .fun(arguments: _, returnType: let returnType):
                            var initialValue: LogicValue?
                            if initializer != nil {
                                initialValue = values[index]
                                index += 1
                            }

                            parameterTypes[pattern.name] = (returnType, initialValue)
                        default:
                            Swift.print("ERROR: Invalid record initializer type")
                        }
                    default:
                        break
                    }
                }

                return LogicValue(resolvedType, .function(.recordInit(members: parameterTypes)))
            }))
        case .declaration(.enumeration(id: _, name: let functionName, genericParameters: _, cases: let enumCases, _)):
            guard let type = unificationContext.patternTypes[functionName.uuid] else { break }

            enumCases.forEach { enumCase in
                switch enumCase {
                case .placeholder:
                    break
                case .enumerationCase(_, name: let pattern, associatedValueTypes: _, _):
                    let resolvedConsType = Unification.substitute(substitution, in: type)

                    context.add(uuid: pattern.uuid, EvaluationThunk(label: "Enum case declaration for \(pattern.name)", { values in
                        return LogicValue(resolvedConsType, .function(.enumInit(caseName: pattern.name)))
                    }))
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

        let patterns: [LGCIdentifierPattern] = declarations.compactMap { declaration in
            switch declaration {
            case .enumeration(_, let pattern, _, _, _),
                 .namespace(_, let pattern, _),
                 .record(_, let pattern, _, _, _),
                 .variable(_, let pattern, _, _, _),
                 .function(_, let pattern, _, _, _, _, _):
                return pattern
            default:
                return nil
            }
        }

        return patterns.map { $0.name }
    }
}

extension LGCDeclaration {
    public var declaredRecordVariables: [(LGCIdentifierPattern, LGCTypeAnnotation, LGCExpression)] {
        switch self {
        case .record(id: _, name: _, genericParameters: _, declarations: let declarations, _):
            return declarations.compactMap { declaration in
                switch declaration {
                case .variable(id: _, name: let name, annotation: .some(let annotation), initializer: .some(let initializer), _):
                    return (name, annotation, initializer)
                default:
                    return nil
                }
            }
        default:
            return []
        }
    }
}
