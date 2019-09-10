//
//  FormatterContext.swift
//  Logic
//
//  Created by Devin Abbott on 9/5/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public class FormatterContext {
    public let formatted: FormatterCommand<LogicElement>

    public init(_ formatted: FormatterCommand<LogicElement>) {
        self.formatted = formatted
    }

    public lazy var logicalRows: [[LogicElement]] = {
        return self.formatted.logicalRows
    }()

    public lazy var elements: [LogicElement] = {
        return Array(self.logicalRows.joined())
    }()

    // MARK: Utilities

    func lineIndex(for elementIndex: Int) -> Int {
        var elementCount = 0
        for (offset, formattedLine) in logicalRows.enumerated() {
            elementCount += formattedLine.count

            if elementIndex < elementCount {
                return offset
            }
        }

        fatalError("Could not find line number for element index \(elementIndex)")
    }

    func elementIndexRange(for lineIndex: Int) -> Range<Int>? {
        return elementIndexRange(for: lineIndex, where: { $0.isLogicalNode })
    }

    func elementIndexRange(for lineIndex: Int, where predicate: (LogicElement) -> Bool) -> Range<Int>? {
        var elementCount = 0
        for (offset, formattedLine) in logicalRows.enumerated() {
            let endElementCount = elementCount + formattedLine.count

            if offset == lineIndex {
                let result = elementCount..<endElementCount
                let resultElements = elements[result]
                if let firstIndex = resultElements.firstIndex(where: predicate),
                    let lastIndex = resultElements.lastIndex(where: predicate) {
                    return firstIndex..<lastIndex + 1
                } else {
                    return nil
                }
            }

            elementCount = endElementCount
        }

        return nil
    }

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
