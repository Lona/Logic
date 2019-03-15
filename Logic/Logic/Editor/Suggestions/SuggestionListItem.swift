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
    case row(String, Bool)

    public var isSelectable: Bool {
        switch self {
        case .row:
            return true
        case .sectionHeader:
            return false
        }
    }
}
