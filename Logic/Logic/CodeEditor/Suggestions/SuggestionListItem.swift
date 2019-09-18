//
//  SuggestionListItem.swift
//  Logic
//
//  Created by Devin Abbott on 3/15/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public enum SuggestionListItem {
    case sectionHeader(String)
    case row(String, String?, Bool, String?, NSImage?)
    case colorRow(name: String, code: String, NSColor, Bool)
    case textStyleRow(String, TextStyle, Bool)

    public var isSelectable: Bool {
        switch self {
        case .row, .colorRow, .textStyleRow:
            return true
        case .sectionHeader:
            return false
        }
    }

    public var isGroupRow: Bool {
        switch self {
        case .row, .colorRow, .textStyleRow:
            return false
        case .sectionHeader:
            return true
        }
    }

    public var height: CGFloat {
        switch self {
        case .row(_, .none, _, _, .none):
            return 26 + 4 + 6
        case .row(_, _, _, _, _):
            return 40 + 12
        case .colorRow:
            return 40
        case .sectionHeader:
            return 21
        case .textStyleRow(let value, let style, _):
            return 8 + style.apply(to: value).size().height
        }
    }
}
