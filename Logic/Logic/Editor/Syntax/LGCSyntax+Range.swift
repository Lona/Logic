//
//  LGCSyntax+Range.swift
//  Logic
//
//  Created by Devin Abbott on 6/4/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public extension LGCSyntaxNode {
    func elementRange(for targetID: UUID, options: LogicFormattingOptions) -> Range<Int>? {
        let topNode = topNodeWithEqualElements(as: targetID, options: options)
        let topNodeFormattedElements = topNode.formatted(using: options).elements

        guard let topFirstFocusableIndex = topNodeFormattedElements.firstIndex(where: { $0.syntaxNodeID != nil }) else { return nil }

        guard let firstIndex = formatted(using: options).elements.firstIndex(where: { formattedElement in
            guard let id = formattedElement.syntaxNodeID else { return false }
            return id == topNodeFormattedElements[topFirstFocusableIndex].syntaxNodeID
        }) else { return nil }

        let lastIndex = firstIndex + (topNodeFormattedElements.count - topFirstFocusableIndex - 1)

        return firstIndex..<lastIndex + 1
    }

    func topNodeWithEqualElements(as targetID: UUID, options: LogicFormattingOptions) -> LGCSyntaxNode {
        let elementPath = uniqueElementPathTo(id: targetID, options: options)

        return elementPath[elementPath.count - 1]
    }

    // Returns the top-most node containing the given range.
    //
    // Returns nil if a non-focusable node selected. This is most likely due to temporarily
    // invalid selection range after a modification, e.g. after a deletion but before the selection range
    // has been updated
    func topNodeWithEqualRange(as range: Range<Int>, options: LogicFormattingOptions) -> LGCSyntaxNode? {
        let elements = formatted(using: options).elements
        let clampedRange = range.clamped(to: elements.startIndex..<elements.endIndex)
        guard let firstId = elements[clampedRange].first?.syntaxNodeID else {
            return nil
        }

        let uniquePath = uniqueElementPathTo(id: firstId, options: options).reversed()

        for node in uniquePath {
            if node.formatted(using: options).elements.count >= range.count {
                return node
            }
        }

        return nil
    }

    func uniqueElementPathTo(id targetID: UUID, options: LogicFormattingOptions) -> [LGCSyntaxNode] {
        guard let pathToTarget = pathTo(id: targetID), pathToTarget.count > 0 else {
            fatalError("Node not found")
        }

        let (_, uniquePath): (min: Int, path: [LGCSyntaxNode]) = pathToTarget
            .reduce((min: Int.max, path: []), { result, next in
                let formattedElements = next.formatted(using: options).elements
                if formattedElements.count < result.min {
                    return (formattedElements.count, result.path + [next])
                } else {
                    return result
                }
            })

        return uniquePath
    }
}
