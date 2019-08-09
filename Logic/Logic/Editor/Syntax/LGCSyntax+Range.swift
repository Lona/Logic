//
//  LGCSyntax+Range.swift
//  Logic
//
//  Created by Devin Abbott on 6/4/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public extension LGCSyntaxNode {
    private func nodeId(_ element: LogicElement, useOwnerId: Bool) -> UUID? {
        return useOwnerId ? element.ownerNodeId : element.syntaxNodeID
    }

    func elementRange(for targetID: UUID, options: LogicFormattingOptions, includeTopLevel: Bool, useOwnerId: Bool = false) -> Range<Int>? {
        let topNode = topNodeWithEqualElements(as: targetID, options: options, includeTopLevel: includeTopLevel)
        let topNodeFormattedElements = topNode.formatted(using: options).elements

        guard let topFirstFocusableIndex = topNodeFormattedElements.firstIndex(where: {
            nodeId($0, useOwnerId: useOwnerId) != nil
        }) else { return nil }

        guard let firstIndex = formatted(using: options).elements.firstIndex(where: { formattedElement in
            guard let id = nodeId(formattedElement, useOwnerId: useOwnerId) else { return false }
            return id == nodeId(topNodeFormattedElements[topFirstFocusableIndex], useOwnerId: useOwnerId)
        }) else { return nil }

        let lastIndex = firstIndex + (topNodeFormattedElements.count - topFirstFocusableIndex - 1)

        return firstIndex..<lastIndex + 1
    }

    // Find a unique path and take the last (smallest) element in the path.
    func topNodeWithEqualElements(as targetID: UUID, options: LogicFormattingOptions, includeTopLevel: Bool) -> LGCSyntaxNode {
        let elementPath = uniqueElementPathTo(id: targetID, options: options, includeTopLevel: includeTopLevel)

        return elementPath[elementPath.count - 1]
    }

    // Returns the top-most node containing the given range.
    //
    // Returns nil if a non-focusable node selected. This is most likely due to temporarily
    // invalid selection range after a modification, e.g. after a deletion but before the selection range
    // has been updated
    func topNodeWithEqualRange(
        as range: Range<Int>,
        options: LogicFormattingOptions,
        includeTopLevel: Bool,
        useOwnerId: Bool = false) -> LGCSyntaxNode? {
        let elements = formatted(using: options).elements
        let clampedRange = range.clamped(to: elements.startIndex..<elements.endIndex)

        guard let first = elements[clampedRange].first(where: { $0.isActivatable }),
            let firstId = nodeId(first, useOwnerId: useOwnerId) else {
            return nil
        }

        let uniquePath = uniqueElementPathTo(id: firstId, options: options, includeTopLevel: includeTopLevel).reversed()

        for node in uniquePath {
            if node.formatted(using: options).elements.count >= range.count {
                return node
            }
        }

        return nil
    }

    // Returns a path containing only the first node for any given # of formatted elements.
    // E.g. If nodes have counts (11, 7, 7, 3, 3, 3, 1), then the result will be the first
    // node to have each distinct count, (11, 7, 3, 1)
    func uniqueElementPathTo(id targetID: UUID, options: LogicFormattingOptions, includeTopLevel: Bool) -> [LGCSyntaxNode] {
        guard let pathToTarget = pathTo(id: targetID, includeTopLevel: includeTopLevel), pathToTarget.count > 0 else {
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
