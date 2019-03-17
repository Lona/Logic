//
//  Formatter+LogicElement.swift
//  Logic
//
//  Created by Devin Abbott on 3/15/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension FormatterCommand where Element == LogicElement {
    public func nextActivatableElementIndex(after currentIndex: Int?) -> Int? {
        let elements = self.elements

        let activatableElements = elements.enumerated().filter { $0.element.isActivatable }

        if activatableElements.isEmpty { return nil }

        // If there is no selection, focus the first element
        guard let currentIndex = currentIndex else { return activatableElements.first?.offset }

        guard currentIndex < elements.count,
            let currentID = elements[currentIndex].syntaxNodeID else { return nil }

        if let index = activatableElements.firstIndex(where: { $0.element.syntaxNodeID == currentID }),
            index + 1 < activatableElements.count {
            return activatableElements[index + 1].offset
        } else {
            return nil
        }
    }

    public func previousActivatableElementIndex(before currentIndex: Int?) -> Int? {
        let elements = self.elements

        let activatableElements = elements.enumerated().filter { $0.element.isActivatable }

        if activatableElements.isEmpty { return nil }

        // If there is no selection, focus the last element
        guard let currentIndex = currentIndex else { return activatableElements.last?.offset }

        guard currentIndex < elements.count,
            let currentID = elements[currentIndex].syntaxNodeID else { return nil }

        if let index = activatableElements.firstIndex(where: { $0.element.syntaxNodeID == currentID }),
            index - 1 >= 0 {
            return activatableElements[index - 1].offset
        } else {
            return nil
        }
    }
}

