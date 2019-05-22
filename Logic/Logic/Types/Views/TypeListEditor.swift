//
//  TypeListEditor.swift
//  Logic
//
//  Created by Devin Abbott on 9/23/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import AppKit
import Foundation

// MARK: - NSPasteboard.PasteboardType

public extension NSPasteboard.PasteboardType {
    static let typeListIndex = NSPasteboard.PasteboardType(rawValue: "logic.typelist.index")
    static let typeListItem = NSPasteboard.PasteboardType(rawValue: "logic.typelist.item")
}

// MARK: Protocols

protocol Selectable {
    var isSelected: Bool { get set }
}

protocol Hoverable {
    var isHovered: Bool { get set }
}

private extension NSTableColumn {
    convenience init(
        title: String,
        resizingMask: ResizingOptions = .autoresizingMask,
        minWidth: CGFloat? = nil,
        maxWidth: CGFloat? = nil) {
        self.init(identifier: NSUserInterfaceItemIdentifier(rawValue: title))
        self.title = title
        self.resizingMask = resizingMask

        if let minWidth = minWidth {
            self.minWidth = minWidth
        }

        if let maxWidth = maxWidth {
            self.maxWidth = maxWidth
        }
    }
}

public class TypeList: NSBox {

    // MARK: Lifecycle

    public init() {
        super.init(frame: .zero)

        sharedInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        sharedInit()
    }

    private func sharedInit() {
        setUpViews()
        setUpConstraints()

        outlineView.registerForDraggedTypes([.typeListIndex])

        update()
    }

    // MARK: Private

    private var scrollView = NSScrollView(frame: .zero)
    private var outlineView = TypeListEditor()

//    private var autosaveName: NSTableView.AutosaveName {
//        return NSTableView.AutosaveName(rawValue: "typeListEditor")
//    }

    func setUpViews() {
        boxType = .custom
        borderType = .lineBorder
        contentViewMargins = .zero
        borderWidth = 0

//        outlineView.autosaveExpandedItems = true
        outlineView.dataSource = outlineView
        outlineView.delegate = outlineView
//        outlineView.autosaveName = autosaveName
//        outlineView.target = self
//        outlineView.action = #selector(handleAction(_:))

        outlineView.reloadData()

        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.addSubview(outlineView)
        scrollView.documentView = outlineView

        outlineView.sizeToFit()

        addSubview(scrollView)
    }

    func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
    }

    func update() {
        outlineView.reloadData()
    }

    public var list: [TypeEntity] {
        get { return outlineView.list }
        set { outlineView.list = newValue }
    }

    public var onChange: ([TypeEntity]) -> Void {
        get { return outlineView.onChange }
        set { outlineView.onChange = newValue }
    }

    public var getTypeList: () -> [String] {
        get { return outlineView.getTypeList }
        set { outlineView.getTypeList = newValue }
    }

    public var getGenericParametersForType: (String) -> [String] {
        get { return outlineView.getGenericParametersForType }
        set { outlineView.getGenericParametersForType = newValue }
    }
}

class TypeListEditor: NSOutlineView, NSOutlineViewDataSource, NSOutlineViewDelegate, NSTextFieldDelegate {

    override func drawGrid(inClipRect clipRect: NSRect) { }

    func setup() {

        let columns: [NSTableColumn] = [
            NSTableColumn(title: "Name", minWidth: 100),
            NSTableColumn(title: "Entity", minWidth: 100),
            NSTableColumn(title: "Value", minWidth: 100)
        ]

        columns.forEach { column in
            addTableColumn(column)

            column.headerCell = EmptyHeaderCell(textCell: column.title)
        }

        outlineTableColumn = columns[0]

        columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        backgroundColor = .clear
        autoresizesOutlineColumn = true

        gridColor = NSColor.black.withAlphaComponent(0.1)
        gridStyleMask = .solidHorizontalGridLineMask
        intercellSpacing = NSSize(width: 1, height: 1)

        let header = TypeListHeaderView(frame: NSRect(x: 0, y: 0, width: 300, height: 26))
        header.tableView = self
        header.onPressPlus = {
            var copy = self.list
            copy.append(TypeEntity.enumType(EnumType.init(name: "", cases: [])))
            self.onChange(copy)
        }
        header.update()

        focusRingType = .none
        rowSizeStyle = .medium
        headerView = header

        doubleAction = #selector(doubleClick(sender:))

        self.reloadData()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    var list: [TypeEntity] = [] {
        didSet {
//            saveExpandedItems()
            self.reloadData()
            restoreExpandedItems()
//            self.expand
        }
    }

    var onChange: ([TypeEntity]) -> Void = {_ in }

    var defaultTypeName = "Unit"

    var defaultTypeParameter = TypeParameter.type("Unit", [])

    var getTypeList: () -> [String] = {
        return []
    }

    var getGenericParametersForType: (String) -> [String] = { _ in
        return []
    }

    func getDisplayType(for type: String) -> String {
        let genericParameters = getGenericParametersForType(type)
        if genericParameters.count > 0 {
            return "\(type)<\(genericParameters.joined(separator: ", "))>"
        } else {
            return type
        }
    }

    func getType(for displayType: String) -> String {
        for item in getTypeList() {
            if displayType == getDisplayType(for: item) {
                return item
            }
        }

        return displayType
    }

    private func remove(item: Any) {
        let itemPath = self.path(forItem: item)

        if itemPath.count == 1 {
            self.onChange(self.list.removing(at: itemPath[0]))
        } else {
            var copy = self.list
            let entity = copy[itemPath[0]]
            copy[itemPath[0]] = entity.removing(itemAtPath: Array(itemPath.dropFirst()))
            self.onChange(copy)
        }
    }

    private func replace(item: Any, with newItem: Any) {
        var copy = self.list
        let itemPath = path(forItem: item)
        let entity = copy[itemPath[0]]
        copy[itemPath[0]] = entity.replacing(
            itemAtPath: Array(itemPath.dropFirst()),
            with: newItem as! TypeListItem).entity!
        self.onChange(copy)
    }

    @objc fileprivate func doubleClick(sender: AnyObject) {
        if clickedColumn == -1 { return }

        if tableColumns[clickedColumn].title == "Name" {
            editColumn(clickedColumn, row: clickedRow, with: nil, select: true)
        }
    }

    override func viewWillDraw() {
//        sizeLastColumnToFit()
        super.viewWillDraw()
        (headerView as? TypeListHeaderView)?.update()
    }

    override func tile() {
        super.tile()
        (headerView as? TypeListHeaderView)?.update()
    }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return list.count
        }

        if let parameter = item as? TypeListItem {
            return parameter.children.count
        }

        return 0
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return TypeListItem.entity(list[index])
        }

        if let parameter = item as? TypeListItem {
            return parameter.children[index]
        }

        fatalError("Bad state")
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return self.outlineView(outlineView, numberOfChildrenOfItem: item) > 0
    }

    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        return TypeListRowView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let typeListItem = item as? TypeListItem, let column = tableColumn else { return NSView() }

        var cell: NSView? = nil

        switch column.title {
        case "Name":
            switch typeListItem {
            case .entity(let entity):
                let view = NameCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
                switch entity {
                case .enumType:
                    view.textColor = #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)
                case .nativeType:
                    view.textColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
                case .functionType:
                    view.textColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
                }
                view.textValue = entity.name
                view.placeholderTextValue = "Type name"
                cell = view

                switch entity {
                case .enumType(var genericType):
                    view.onPressPlus = {
                        genericType.cases.append(TypeCase.normal("", []))
                        self.replace(item: item, with: TypeListItem.entity(TypeEntity.enumType(genericType)))
                    }
                case .nativeType(var nativeType):
                    view.onPressPlus = {
                        nativeType.parameters.append(NativeTypeParameter(name: ""))
                        self.replace(item: item, with: TypeListItem.entity(TypeEntity.nativeType(nativeType)))
                    }
                case .functionType(let functionType):
                    view.onPressPlus = {
//                        nativeType.parameters.append(NativeTypeParameter(name: ""))
                        self.replace(item: item, with: TypeListItem.entity(TypeEntity.functionType(functionType)))
                    }
                }
                view.onPressMinus = {
                    self.remove(item: item)
                }
                view.onChangeText = { name in
                    switch entity {
                    case .enumType(var genericType):
                        genericType.name = name
                        self.replace(item: item, with: TypeListItem.entity(TypeEntity.enumType(genericType)))
                    case .nativeType(var nativeType):
                        nativeType.name = name
                        self.replace(item: item, with: TypeListItem.entity(TypeEntity.nativeType(nativeType)))
                    case .functionType:
                        break
//                        functionType.name = name
//                        self.replace(item: item, with: TypeListItem.entity(TypeEntity.functionType(functionType)))
                    }
                }
            case .typeCase(let typeCase):
                let view = NameCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
                view.textValue = typeCase.name
                view.placeholderTextValue = "Case name"
                cell = view

                view.onPressPlus = {
                    switch typeCase {
                    case .normal(let name, var parameters):
                        parameters.append(
                            NormalTypeCaseParameter(value: self.defaultTypeParameter))
                        self.replace(item: item, with: TypeListItem.typeCase(TypeCase.normal(name, parameters)))
                    case .record(let name, var parameters):
                        parameters.append(
                            KeyedParameter(key: "", value: self.defaultTypeParameter))
                        self.replace(item: item, with: TypeListItem.typeCase(TypeCase.record(name, parameters)))
                    }
                }
                view.onPressMinus = { self.remove(item: item) }
                view.onChangeText = { name in
                    switch typeCase {
                    case .normal(_, let parameters):
                        self.replace(item: item, with: TypeListItem.typeCase(TypeCase.normal(name, parameters)))
                    case .record(_, let parameters):
                        self.replace(item: item, with: TypeListItem.typeCase(TypeCase.record(name, parameters)))
                    }
                }
            case .normalTypeCaseParameter:
                let view = NameCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
                view.textValue = "(Parameter \(childIndex(forItem: item)))"
                cell = view

                view.onPressMinus = { self.remove(item: item) }
            case .recordTypeCaseParameter(let parameter):
                let view = NameCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
                view.textValue = parameter.key
                view.placeholderTextValue = "Key name"
                cell = view

                view.onPressMinus = { self.remove(item: item) }
                view.onChangeText = { name in
                    self.replace(item: item, with: TypeListItem.recordTypeCaseParameter(
                        KeyedParameter(key: name, value: parameter.value)))
                }
            case .genericTypeParameterSubstitution(let substitution):
                let view = NameCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
                view.textValue = substitution.generic
                cell = view
            case .nativeTypeParameter:
                let view = NameCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
                view.textValue = "(Parameter \(childIndex(forItem: item)))"
                cell = view

                view.onPressMinus = { self.remove(item: item) }
            }
        case "Entity":
            switch typeListItem {
            case .entity(let entity):
                let view = EntityCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
//                view.items = ["Enum Type", "Generic Type", "Native Type", "Instance Type", "Alias Type"]
                view.items = ["Enum Type", "Native Type"]
                switch entity {
                case .enumType:
                    view.selectedItem = "Enum Type"
                case .nativeType:
                    view.selectedItem = "Native Type"
                case .functionType:
                    view.selectedItem = "Function Type"
                }
                view.onChangeSelectedItem = { selectedItem in
                    switch selectedItem {
                    case "Enum Type":
                        self.replace(item: item, with:
                            TypeListItem.entity(
                                TypeEntity.enumType(
                                    EnumType(name: entity.name, cases: []))))
                    case "Native Type":
                        self.replace(item: item, with:
                            TypeListItem.entity(
                                TypeEntity.nativeType(
                                    NativeType(name: entity.name, parameters: []))))
//                    case "Function Type":
//                        self.replace(item: item, with:
//                            TypeListItem.entity(
//                                TypeEntity.functionType(
//                                    FunctionType(name: entity.name, parameters: [], returnType: self.defaultTypeParameter))))
                    default:
                        break
                    }
                }
                cell = view
            case .typeCase(let typeCase):
                let view = EntityCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
                view.items = ["Case", "Record Case"]
                switch typeCase {
                case .normal:
                    view.selectedItem = "Case"
                case .record:
                    view.selectedItem = "Record Case"
                }
                view.onChangeSelectedItem = { selectedItem in
                    switch selectedItem {
                    case "Case":
                        self.replace(item: item, with: TypeListItem.typeCase(.normal(typeCase.name, [])))
                    case "Record Case":
                        self.replace(item: item, with: TypeListItem.typeCase(.record(typeCase.name, [])))
                    default:
                        break
                    }
                }
                cell = view
            case .normalTypeCaseParameter(let parameter):
                let entity = list[path(forItem: item)[0]]
                // If the top-level entity is generic, then we allow using generic parameters
                switch entity {
                case .enumType:
                    let view = EntityCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
                    view.items = ["Type", "Generic Parameter"]
                    switch parameter.value {
                    case .generic:
                        view.selectedItem = "Generic Parameter"
                    case .type:
                        view.selectedItem = "Type"
                    }
                    view.onChangeSelectedItem = { selectedItem in
                        switch selectedItem {
                        case "Type":
                            self.replace(item: item, with:
                                TypeListItem.normalTypeCaseParameter(
                                    NormalTypeCaseParameter(value: self.defaultTypeParameter)))
                        case "Generic Parameter":
                            self.replace(item: item, with:
                                TypeListItem.normalTypeCaseParameter(
                                    NormalTypeCaseParameter(value:
                                        TypeParameter.generic("T"))))
                        default:
                            break
                        }
                    }
                    cell = view
                case .nativeType:
                    break
                case .functionType:
                    break
                }
            case .recordTypeCaseParameter(let parameter):
                let entity = list[path(forItem: item)[0]]
                // If the top-level entity is generic, then we allow using generic parameters
                switch entity {
                case .enumType:
                    let view = EntityCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
                    view.items = ["Type", "Generic Parameter"]
                    switch parameter.value {
                    case .generic:
                        view.selectedItem = "Generic Parameter"
                    case .type:
                        view.selectedItem = "Type"
                    }
                    view.onChangeSelectedItem = { selectedItem in
                        switch selectedItem {
                        case "Type":
                            self.replace(item: item, with:
                                TypeListItem.recordTypeCaseParameter(
                                    KeyedParameter(key: parameter.key, value: self.defaultTypeParameter)))
                        case "Generic Parameter":
                            self.replace(item: item, with:
                                TypeListItem.recordTypeCaseParameter(
                                    KeyedParameter(key: parameter.key, value:
                                        TypeParameter.generic("T"))))
                        default:
                            break
                        }
                    }
                    cell = view
                case .nativeType:
                    break
                case .functionType:
                    break
                }
            case .genericTypeParameterSubstitution:
                let view = NameCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
                view.textValue = "(Generic Substitution)"
                cell = view
            case .nativeTypeParameter:
                let view = NameCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
                view.textValue = "(Generic Parameter)"
                cell = view
            }
        case "Value":
            switch typeListItem {
            case .entity(let entity):
                let view = NameCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
                view.textValue = "(\(entity.children.count) case\(entity.children.count == 1 ? "" : "s"))"
                cell = view
            case .typeCase(let typeCase):
                let view = NameCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
                view.textValue = "(\(typeCase.children.count) parameter\(typeCase.children.count == 1 ? "" : "s"))"
                cell = view
            case .normalTypeCaseParameter(let parameter):
                switch parameter.value {
                case .type:
                    let view = EntityCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
                    view.items = getTypeList().map(getDisplayType)
                    view.selectedItem = getDisplayType(for: parameter.value.name)
                    view.onChangeSelectedItem = { displayType in
                        let selectedItem = self.getType(for: displayType)
                        let genericParameters = self.getGenericParametersForType(selectedItem)
                        var substitutions = genericParameters.map { generic in
                            GenericTypeParameterSubstitution(generic: generic, instance: self.defaultTypeName)
                        }
                        let entity = self.list[self.path(forItem: item)[0]]
                        if selectedItem == entity.name {
                            substitutions = []
                        }

                        self.replace(item: item, with:
                            TypeListItem.normalTypeCaseParameter(
                                NormalTypeCaseParameter(value:
                                    TypeParameter.type(selectedItem, substitutions))))
                    }
                    cell = view
                case .generic:
                    let view = NameCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
                    view.textValue = parameter.value.name
                    view.placeholderTextValue = "Generic name"
                    view.onChangeText = { name in
                        self.replace(item: item, with:
                            TypeListItem.normalTypeCaseParameter(
                                NormalTypeCaseParameter(value:
                                    TypeParameter.generic(name))))
                    }
                    cell = view
                }
            case .recordTypeCaseParameter(let parameter):
                switch parameter.value {
                case .type:
                    let view = EntityCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
                    view.items = getTypeList().map(getDisplayType)
                    view.selectedItem = getDisplayType(for: parameter.value.name)
                    view.onChangeSelectedItem = { displayType in
                        let selectedItem = self.getType(for: displayType)
                        let genericParameters = self.getGenericParametersForType(selectedItem)
                        var substitutions = genericParameters.map { generic in
                            GenericTypeParameterSubstitution(generic: generic, instance: self.defaultTypeName)
                        }
                        let entity = self.list[self.path(forItem: item)[0]]
                        if selectedItem == entity.name {
                            substitutions = []
                        }

                        self.replace(item: item, with:
                            TypeListItem.recordTypeCaseParameter(
                                KeyedParameter(key: parameter.key, value:
                                    TypeParameter.type(selectedItem, substitutions))))
                    }
                    cell = view
                case .generic:
                    let view = NameCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
                    view.textValue = parameter.value.name
                    view.placeholderTextValue = "Generic name"
                    view.onChangeText = { name in
                        self.replace(item: item, with:
                            TypeListItem.recordTypeCaseParameter(
                                KeyedParameter(key: parameter.key, value:
                                    TypeParameter.generic(name))))
                    }
                    cell = view
                }
            case .genericTypeParameterSubstitution(let substitution):
                let view = EntityCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
                view.items = getTypeList().map(getDisplayType)
                view.selectedItem = getDisplayType(for: substitution.instance)
                view.onChangeSelectedItem = { displayType in
                    let selectedItem = self.getType(for: displayType)
                    self.replace(item: item, with:
                        TypeListItem.genericTypeParameterSubstitution(
                            GenericTypeParameterSubstitution(generic: substitution.generic, instance: selectedItem)))
                }
                cell = view
            case .nativeTypeParameter(let parameter):
                let view = NameCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
                view.textValue = parameter.name
                view.placeholderTextValue = "Generic name"
                view.onChangeText = { name in
                    self.replace(item: item, with:
                        TypeListItem.nativeTypeParameter(NativeTypeParameter(name: name)))
                }
                cell = view
            }
        default:
            break
        }

        return cell ?? NSView()
    }

    func path(forItem item: Any) -> [Int] {
        var output: [Int] = [childIndex(forItem: item)]
        var item = item

        while let parentItem = parent(forItem: item) {
            output.append(childIndex(forItem: parentItem))
            item = parentItem
        }

        return output.reversed()
    }

    func expandedItems() -> [Bool] {
        return (0..<numberOfRows).map { index in
            return isItemExpanded(item(atRow: index))
        }
    }

    func setExpandedItems(_ state: [Bool]) {
        for (index, isExpanded) in state.enumerated() {
            if isExpanded {
                expandItem(item(atRow: index))
            }
        }
    }

    func outlineViewItemDidExpand(_ notification: Notification) {
//        Swift.print("ovide", expandedItems())
        saveExpandedItems()
    }

    func outlineViewItemDidCollapse(_ notification: Notification) {
//        Swift.print("ovidc", expandedItems())
        saveExpandedItems()
    }

    private func saveExpandedItems() {
        UserDefaults.standard.set(expandedItems(), forKey: "Logic typeListExpandedItems")
    }

    private func restoreExpandedItems() {
        guard let state = UserDefaults.standard
            .value(forKey: "Logic typeListExpandedItems") as? [Bool] else { return }
        setExpandedItems(state)
    }

    // MARK: - Drag and drop

    typealias Element = TypeListItem

    public func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        let pasteboardItem = NSPasteboardItem()
        let index = outlineView.row(forItem: item)

        pasteboardItem.setString(String(index), forType: .typeListIndex)

        return pasteboardItem
    }

    public func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {

        let sourceIndexString = info.draggingPasteboard.string(forType: .typeListIndex)

        if let sourceIndexString = sourceIndexString,
            let sourceIndex = Int(sourceIndexString),
            let sourceItem = outlineView.item(atRow: sourceIndex) as? Element,
            let relativeItem = item as? Element? {

            let acceptanceCategory = outlineView.shouldAccept(dropping: sourceItem, relativeTo: relativeItem, at: index)

            switch acceptanceCategory {
            case .into(parent: let parent, at: _):
                switch (sourceItem, parent) {
                case (.typeCase, .entity(.enumType)):
                    return NSDragOperation.move
                default:
                    break
                }
            case .intoContainer:
                switch sourceItem {
                case .entity:
                    return NSDragOperation.move
                default:
                    break
                }
            case .intoDescendant:
                break
            }
        }

        return NSDragOperation()
    }

    public func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        let sourceIndexString = info.draggingPasteboard.string(forType: .typeListIndex)

        if let sourceIndexString = sourceIndexString,
            let sourceIndex = Int(sourceIndexString),
            let sourceItem = outlineView.item(atRow: sourceIndex) as? Element,
            let relativeItem = item as? Element? {

            let acceptanceCategory = outlineView.shouldAccept(dropping: sourceItem, relativeTo: relativeItem, at: index)
            let (sourceParent, relativeIndex) = relativePosition(for: sourceItem)

            switch acceptanceCategory {
            case .into(parent: let targetParent, at: let targetIndex):
                switch (sourceItem, targetParent) {
                case (.typeCase, .entity):
                    let sourceItemPath = self.path(forItem: sourceItem)
                    let targetParentPath = self.path(forItem: targetParent)

                    var copy = self.list

                    copy[sourceItemPath[0]] = copy[sourceItemPath[0]]
                        .removing(itemAtPath: Array(sourceItemPath.dropFirst()))

                    if let targetIndex = targetIndex {
                        let adjustedIndex = relativeIndex < targetIndex && sourceParent == targetParent
                            ? targetIndex - 1
                            : targetIndex

                        copy[targetParentPath[0]] = copy[targetParentPath[0]]
                            .inserting(item: sourceItem, atPath: Array(targetParentPath.dropFirst()) + [adjustedIndex])
                    } else {
                        copy[targetParentPath[0]] = copy[targetParentPath[0]]
                            .appending(item: sourceItem, atPath: Array(targetParentPath.dropFirst()))
                    }

                    self.onChange(copy)
                default:
                    break
                }
            case .intoContainer(let targetIndex):
                guard let entity = sourceItem.entity else { return false }

                var copy = self.list

                copy.remove(at: relativeIndex)

                if let targetIndex = targetIndex {
                    if relativeIndex < targetIndex {
                        copy.insert(entity, at: targetIndex - 1)
                    } else {
                        copy.insert(entity, at: targetIndex)
                    }
                } else {
                    copy.append(entity)
                }

                onChange(copy)
            default:
                break
            }
        }

        return false
    }
}
