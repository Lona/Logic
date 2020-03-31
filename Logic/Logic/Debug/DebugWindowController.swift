//
//  DebugWindow.swift
//  Logic
//
//  Created by Devin Abbott on 3/20/20.
//  Copyright © 2020 BitDisco, Inc. All rights reserved.
//

import AppKit

public class DebugWindowController: NSWindowController {
    enum Entry {
        case header(title: String)
        case `import`(name: String)
        case nameBinding(name: String, id: UUID)
        case typeBinding(name: String, id: UUID, type: Unification.T)
        case unification(constraint: Unification.Constraint, description: String, ids: [UUID])
        case substitution(Unification.Substitution)
        case node(description: String, id: UUID)
        case evaluationThunk(id: UUID, thunk: Compiler.EvaluationThunk)
    }

    public init() {
        let window = SuggestionWindow()

        super.init(window: window)

        setUpWindow()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public var getLibraryURL: (String) -> URL? = Library.url

    public var getLibraryContents: (String) -> LGCSyntaxNode? = Library.load

    public var rootNode: LGCSyntaxNode = .program(.join(programs: []))

    public var scopeContext: Compiler.ScopeContext = .init()

    public var unificationContext: Compiler.UnificationContext = .init()

    public var substitution: Unification.Substitution = .init()

    public var evaluationContext: Compiler.EvaluationContext = .init()

    // MARK: Private

    private var selectedIndex: Int? = nil {
        didSet {
            if selectedIndex != oldValue {
                suggestionWindow.selectedIndex = selectedIndex
                update()
            }
        }
    }

    private var suggestionText = "" {
        didSet {
            if suggestionText != oldValue {
                suggestionWindow.suggestionText = suggestionText
                updateEntries()
            }
        }
    }

    private var entries: [Entry] = [] {
        didSet {
            update()
        }
    }

    private func setUpWindow() {
        suggestionWindow.style.suggestionListWidth = 260

        suggestionWindow.placeholderText = "Filter"
        suggestionWindow.isMovableByWindowBackground = true
        suggestionWindow.shouldHideWithoutCheckingParentWindow = true
        suggestionWindow.showsSearchBar = true
        suggestionWindow.isReleasedWhenClosed = false

        suggestionWindow.onPressEscapeKey = { [unowned self] in self.suggestionWindow.orderOut(nil) }
        suggestionWindow.onRequestHide = { [unowned self] in self.suggestionWindow.orderOut(nil) }

        suggestionWindow.onChangeSuggestionText = { value in
            // This updates entries
            self.suggestionText = value

            // Update index after updating entries
            self.selectedIndex = self.suggestionWindow.suggestionItems.firstIndex(where: { $0.isSelectable })
        }

        suggestionWindow.onSelectIndex = { [unowned self] index in
            self.selectedIndex = index
        }
    }

    private func updateEntries() {
        let query = suggestionText.lowercased()

        func filterEntries(_ entries: [Entry]) -> [Entry] {
            entries.filter { entry in
                if suggestionText.isEmpty { return true }

                switch entry {
                case .import(name: let name):
                    return name.lowercased().contains(query)
                case .header:
                    return true
                case .typeBinding(name: let name, id: let uuid, type: let type):
                    return name.lowercased().contains(query) ||
                        uuid.uuidString.lowercased().contains(query) ||
                        type.debugDescription.lowercased().contains(query)
                case .nameBinding(name: let name, id: let uuid):
                    return name.lowercased().contains(query) || uuid.uuidString.lowercased().contains(query)
                case .unification(constraint: let constraint, let description, let uuids):
                    return "constraint".contains(query) ||
                        constraint.debugDescription.lowercased().contains(query) ||
                        description.lowercased().contains(query) ||
                        uuids.contains(where: { id in id.uuidString.lowercased().contains(query) })
                case .substitution(let substitution):
                    return "substitution".contains(query) || substitution.debugDescription.lowercased().contains(query)
                case .node(description: let description, id: let uuid):
                    return uuid.uuidString.lowercased().contains(query) || description.lowercased().contains(query)
                case .evaluationThunk(id: let uuid, thunk: let thunk):
                    return "evaluation".contains(query) ||
                        uuid.uuidString.lowercased().contains(query) ||
                        thunk.label?.lowercased().contains(query) == true
                }
            }
        }

        var entries: [Entry] = []

        let imports = rootNode.reduce(initialResult: Set<String>()) { (result, node, config) -> Set<String> in
            switch node {
            case .declaration(.importDeclaration(_, name: let name)):
                return result.union([name.name])
            default:
                return result
            }
        }

        let importEntries: [Entry] = filterEntries(
            imports.map { name in .import(name: name) }
        )

        if !importEntries.isEmpty {
            entries.append(.header(title: "IMPORTS"))
            entries.append(contentsOf: importEntries)
        }

        let nameBindingEntries: [Entry] = filterEntries(
            self.scopeContext.namespace.values
                .sorted(by: { a, b in
                    a.key.joined(separator: ".").lowercased() < b.key.joined(separator: ".").lowercased()
                })
                .map({ names, uuid in
                    return .nameBinding(name: names.joined(separator: "."), id: uuid)
                })
        )

        if !nameBindingEntries.isEmpty {
            entries.append(.header(title: "NAME BINDINGS (NAMESPACE)"))
            entries.append(contentsOf: nameBindingEntries)
        }

        let typeBindingEntries: [Entry] = filterEntries(
            self.unificationContext.nodes.map { (uuid, type) -> (String, UUID, Unification.T) in
                switch rootNode.find(id: uuid) {
                case .pattern(let pattern):
                    return (pattern.name, uuid, type)
                case .some(let node):
                    return ("@" + node.nodeTypeDescription, uuid, type)
                case .none:
                    return ("?", uuid, type)
                }
            }.map({ name, id, type in Entry.typeBinding(name: name, id: id, type: type) })
        )

        if !typeBindingEntries.isEmpty {
            entries.append(.header(title: "TYPE BINDINGS (UNIFICATION)"))
            entries.append(contentsOf: typeBindingEntries)
        }

        let constraintEntries: [Entry] = filterEntries(
            self.unificationContext.constraints.enumerated().map { index, constraint in
                let info = self.unificationContext.constraintDebugInfo[index]
                return Entry.unification(constraint: constraint, description: info.0, ids: info.1)
            }
        )

        if !constraintEntries.isEmpty {
            entries.append(.header(title: "CONSTRAINTS (UNIFICATION)"))
            entries.append(contentsOf: constraintEntries)
        }

        let substitutionEntries: [Entry] = filterEntries([
            .substitution(substitution)
        ])

        if !substitutionEntries.isEmpty {
            entries.append(.header(title: "SUBSTITUTION (UNIFICATION)"))
            entries.append(contentsOf: substitutionEntries)
        }

        let evaluationEntries: [Entry] = filterEntries(
            self.evaluationContext.thunks.map { id, thunk in
                return Entry.evaluationThunk(id: id, thunk: thunk)
            }
        )

        if !evaluationEntries.isEmpty {
            entries.append(.header(title: "EVALUATION THUNKS"))
            entries.append(contentsOf: evaluationEntries)
        }

        let nodeEntries: [Entry] = filterEntries(
            rootNode.reduce(initialResult: [], f: { result, node, conf in result + [node] })
                .map({ Entry.node(description: $0.nodeTypeDescription, id: $0.uuid) })
        )

        if !nodeEntries.isEmpty {
            entries.append(.header(title: "LOGIC AST NODES"))
            entries.append(contentsOf: nodeEntries)
        }

        self.entries = entries
    }

    private func update() {
        suggestionWindow.suggestionItems = entries.map { entry in
            switch entry {
            case .header(title: let title):
                return .sectionHeader(title)
            case .import(name: let name):
                return .row(name, nil, false, "Library", nil)
            case .nameBinding(name: let name, id: let uuid):
                return .row(name, nil, false, uuid.shortString, nil)
            case .typeBinding(name: let name, id: _, type: let type):
                return .row(name, nil, false, type.badge, nil)
            case .unification(constraint: let constraint, _, _):
                return .row(constraint.debugDescription, nil, false, nil, nil)
            case .substitution:
                return .row("Substitution", nil, false, nil, nil)
            case .node(description: let description, id: let uuid):
                return .row(description, nil, false, uuid.shortString, nil)
            case .evaluationThunk(id: _, thunk: let thunk):
                return .row(thunk.label ?? "Thunk", nil, false, nil, nil)
            }
        }

        func nodeDescription(uuid: UUID) -> String {
            let nodeString: String

            if let node = rootNode.find(id: uuid) {
                nodeString = """
                ## \(node.nodeTypeDescription) Node (\(node.uuid))
                ```
                \(node)
                ```
                """
            } else {
                nodeString = ""
            }

            let typeString: String

            if let type = unificationContext.nodes[uuid] {
                typeString = """
                ## Type
                ```
                \(type.debugDescription)
                ```
                """
            } else {
                typeString = ""
            }

            let valueString: String

            if let value = evaluationContext.evaluate(uuid: uuid) {
                valueString = """
                ## Value
                ```
                \(value.debugDescription)
                ```
                """
            } else {
                // TODO: Report errors
                valueString = ""
            }

            let nodePathString: String

            if let path = rootNode.pathTo(id: uuid, includeTopLevel: true) {
                nodePathString = """
                ## Ancestors
                \(path.reversed().map({ "### \($0.nodeTypeDescription) (\($0.uuid))\n```\n\($0)\n```" }).joined(separator: "\n"))
                """
            } else {
                nodePathString = ""
            }

            return [nodeString, typeString, valueString, nodePathString].filter { !$0.isEmpty }.joined(separator: "\n")
        }

        if let selectedIndex = selectedIndex, entries.count > selectedIndex {
            switch entries[selectedIndex] {
            case .import(name: let name):
                let libraryPath = getLibraryURL(name)?.path

                let contents: String

                if let library = getLibraryContents(name),
                    let libraryData = try? JSONEncoder().encode(library),
                    let librarySourceData = LogicFile.convert(libraryData, kind: .logic, to: .source),
                    let librarySourceString = String(data: librarySourceData, encoding: .utf8) {
                    contents = librarySourceString
                } else {
                    contents = ""
                }

                let mdxString = """
                # \(name)

                ### Loaded from
                \(libraryPath ?? "")

                ### Contents
                ```swift
                \(contents)
                ```
                """

                suggestionWindow.detailView = LightMark.makeScrollView(
                    markdown: mdxString,
                    renderingOptions: .init(formattingOptions: .visual)
                )
            case .nameBinding(name: let name, id: let uuid):
                let mdxString = """
                # \(name)
                \(nodeDescription(uuid: uuid))
                """

                suggestionWindow.detailView = LightMark.makeScrollView(
                    markdown: mdxString,
                    renderingOptions: .init(formattingOptions: .visual)
                )
            case .typeBinding(let name, let uuid, _):
                let mdxString = """
                # \(name)
                \(nodeDescription(uuid: uuid))
                """

                suggestionWindow.detailView = LightMark.makeScrollView(
                    markdown: mdxString,
                    renderingOptions: .init(formattingOptions: .visual)
                )
            case .unification(let constraint, let description, let ids):
                let nodes = ids.compactMap({ rootNode.find(id: $0) })

                let mdxString = """
                # Unification Constraint

                **Constraint:** \(constraint)

                **Description:** \(description)

                **Nodes:** \(ids)

                \(nodes.map { "```\n\($0)\n```" }.joined(separator: "\n"))
                """

                suggestionWindow.detailView = LightMark.makeScrollView(
                    markdown: mdxString,
                    renderingOptions: .init(formattingOptions: .visual)
                )
            case .substitution(let substitution):
                let description = substitution.pairs.map { a, b in
                    return "```\n\(a) == \(b)\n```"
                }.joined(separator: "\n")

                let mdxString = """
                # Substitution

                **Description:**
                \(description)
                """

                suggestionWindow.detailView = LightMark.makeScrollView(
                    markdown: mdxString,
                    renderingOptions: .init(formattingOptions: .visual)
                )
            case .node(description: _, id: let uuid):
                let mdxString: String

                if let _ = rootNode.find(id: uuid) {
                    mdxString = """
                    # Node
                    \(nodeDescription(uuid: uuid))
                    """
                } else {
                    mdxString = "Node \(uuid) not found in `rootNode`"
                }

                suggestionWindow.detailView = LightMark.makeScrollView(
                    markdown: mdxString,
                    renderingOptions: .init(formattingOptions: .visual)
                )
            case .evaluationThunk(id: let uuid, thunk: let thunk):

                func formatThunk(id uuid: UUID) -> String {
                    let value = evaluationContext.evaluate(uuid: uuid)?.debugDescription ?? "Failed to evaluate"
                    let label = evaluationContext.thunks[uuid]?.label ?? "?"
                    return "`\(uuid)`: \(label) - \(value)"
                }

                let formattedDirectDependencies = thunk.dependencies.map(formatThunk).joined(separator: "\n")

                var remainingDependencies: [UUID] = thunk.dependencies
                var allDependencies: [UUID] = []

                while let next = remainingDependencies.popLast() {
                    allDependencies.append(next)

                    if let nextThunk = evaluationContext.thunks[next] {
                        remainingDependencies.append(contentsOf: nextThunk.dependencies)
                    }
                }

                let formattedDependencies = allDependencies.map(formatThunk).joined(separator: "\n")

                let mdxString = """
                # \(thunk.label ?? "Thunk")

                ### Value
                \(evaluationContext.evaluate(uuid: uuid)?.debugDescription ?? "Failed to evaluate")

                ### Direct Dependencies

                \(formattedDirectDependencies)

                ### All Dependencies

                \(formattedDependencies)

                \(nodeDescription(uuid: uuid))
                """

                suggestionWindow.detailView = LightMark.makeScrollView(
                    markdown: mdxString,
                    renderingOptions: .init(formattingOptions: .visual)
                )
            case .header:
                suggestionWindow.detailView = nil
            }
        } else {
            suggestionWindow.detailView = nil
        }
    }

    private var suggestionWindow: SuggestionWindow { return window as! SuggestionWindow }

    // MARK: Overrides

    public override func showWindow(_ sender: Any?) {
        super.showWindow(nil)

        suggestionText = ""
        updateEntries()

        selectedIndex = suggestionWindow.suggestionItems.firstIndex(where: { $0.isSelectable })
        update()

        suggestionWindow.setContentSize(.init(width: 1000, height: 800))
        suggestionWindow.center()
        suggestionWindow.focusSearchField()
    }
}

extension UUID {
    var shortString: String {
        return String(uuidString.prefix(8))
    }
}

extension Unification.T {
    var badge: String {
        switch self {
        case .fun:
            return "ƒ"
        default:
            return self.debugDescription
        }
    }
}
