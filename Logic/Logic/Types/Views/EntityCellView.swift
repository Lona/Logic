//
//  EntityCellView.swift
//  Logic
//
//  Created by Devin Abbott on 9/24/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import AppKit
import Foundation

class EntityCellView: NSTableCellView, Selectable {

    // MARK: Lifecycle

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setUpViews()
        setUpConstraints()
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    var items: [String] = [] {
        didSet {
            dropdownView.removeAllItems()
            dropdownView.addItems(withTitles: items)
        }
    }

    var selectedItem: String? {
        get {
            return dropdownView.selectedItem?.title
        }
        set {
            guard let value = newValue else { return }
            dropdownView.selectItem(withTitle: value)
        }
    }

    var isSelected: Bool = false { didSet { update() } }

    var onChangeSelectedItem: ((String) -> Void)?

    // MARK: Private

    private var dropdownView = NSPopUpButton()

    @objc private func handleChange(_ sender: AnyObject) {
        guard let selectedItem = selectedItem else { return }
        onChangeSelectedItem?(selectedItem)
    }

    func setUpViews() {
        dropdownView.isEnabled = true
        dropdownView.isBordered = false
        dropdownView.autoenablesItems = true

        dropdownView.target = self
        dropdownView.action = #selector(handleChange(_:))

        addSubview(dropdownView)
    }

    func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        dropdownView.translatesAutoresizingMaskIntoConstraints = false

        dropdownView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        dropdownView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        dropdownView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4).isActive = true
        dropdownView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4).isActive = true
    }

    func update() {
    }
}
