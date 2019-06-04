//
//  LGCSyntax+Range.swift
//  Logic
//
//  Created by Devin Abbott on 6/4/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public extension LGCSyntaxNode {
    func elementRange(for targetID: UUID) -> Range<Int>? {
        let topNode = topNodeWithEqualElements(as: targetID)
        let topNodeFormattedElements = topNode.formatted.elements

        guard let topFirstFocusableIndex = topNodeFormattedElements.firstIndex(where: { $0.syntaxNodeID != nil }) else { return nil }

        guard let firstIndex = formatted.elements.firstIndex(where: { formattedElement in
            guard let id = formattedElement.syntaxNodeID else { return false }
            return id == topNodeFormattedElements[topFirstFocusableIndex].syntaxNodeID
        }) else { return nil }

        let lastIndex = firstIndex + (topNodeFormattedElements.count - topFirstFocusableIndex - 1)

        return firstIndex..<lastIndex + 1
    }

    func topNodeWithEqualElements(as targetID: UUID) -> LGCSyntaxNode {
        let elementPath = uniqueElementPathTo(id: targetID)

        return elementPath[elementPath.count - 1]
    }

    // Returns the top-most node containing the given range.
    //
    // Returns nil if a non-focusable node selected. This is most likely due to temporarily
    // invalid selection range after a modification, e.g. after a deletion but before the selection range
    // has been updated
    func topNodeWithEqualRange(as range: Range<Int>) -> LGCSyntaxNode? {
        let elements = formatted.elements
        let clampedRange = range.clamped(to: elements.startIndex..<elements.endIndex)
        guard let firstId = elements[clampedRange].first?.syntaxNodeID else {
            return nil
        }

        let uniquePath = uniqueElementPathTo(id: firstId).reversed()

        for node in uniquePath {
            if node.formatted.elements.count >= range.count {
                return node
            }
        }

        return nil
    }

    func uniqueElementPathTo(id targetID: UUID) -> [LGCSyntaxNode] {
        guard let pathToTarget = pathTo(id: targetID), pathToTarget.count > 0 else {
            fatalError("Node not found")
        }

        let (_, uniquePath): (min: Int, path: [LGCSyntaxNode]) = pathToTarget
            .reduce((min: Int.max, path: []), { result, next in
                let formattedElements = next.formatted.elements
                if formattedElements.count < result.min {
                    return (formattedElements.count, result.path + [next])
                } else {
                    return result
                }
            })

        return uniquePath
    }
}
