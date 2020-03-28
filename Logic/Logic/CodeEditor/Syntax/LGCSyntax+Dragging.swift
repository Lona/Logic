//
//  LGCSyntax+Dragging.swift
//  Logic
//
//  Created by Devin Abbott on 8/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension LGCSyntaxNode {
    
    /// Find the smallest node that accepts a drop
    public func findDropTarget(relativeTo node: LGCSyntaxNode, accepting sourceNode: LGCSyntaxNode) -> LGCSyntaxNode? {
        guard var path = self.pathTo(id: node.uuid, includeTopLevel: true) else { return nil }

        while let parent = path.dropLast().last {
            if parent.contents.acceptsNode(rootNode: self, childNode: sourceNode) {
                return parent
            }

            path = path.dropLast()
        }

        return nil
    }

    /// Find the smallest node that accepts a line drag
    public func findDragSource(id: UUID) -> LGCSyntaxNode? {
        guard var path = self.pathTo(id: id) else { return nil }

        while let current = path.last {
            if current.contents.acceptsLineDrag(rootNode: self) {
                return current
            }

            path = path.dropLast()
        }

        return nil
    }

    /// Duplicate the selected node, returning the new root node
    public func duplicate(id: UUID) -> (rootNode: LGCSyntaxNode, duplicatedNode: LGCSyntaxNode)? {
        guard let node = find(id: id) else { return nil }

        switch node {
        case .declaration:
            if let targetParent = self.findDropTarget(relativeTo: node, accepting: node),
                let childIndex = targetParent.contents.childrenInSameCollection(as: node).firstIndex(of: node) {
                let childNode = node.copy(deep: true)
                let newParent = targetParent.insert(childNode: childNode, atIndex: childIndex + 1)
                return (self.replace(id: targetParent.uuid, with: newParent), childNode)
            } else {
                break
            }
        default:
            break
        }

        return nil
    }

    public enum InsertPosition {
        case above, below
    }

    /// Insert a placeholder above the selected node, returning the new root node
    public func insert(_ position: InsertPosition, id: UUID) -> (rootNode: LGCSyntaxNode, insertedNode: LGCSyntaxNode)? {
        guard let node = find(id: id) else { return nil }

        switch node {
        case .declaration:
            if let targetParent = self.findDropTarget(relativeTo: node, accepting: node),
                let childIndex = targetParent.contents.childrenInSameCollection(as: node).firstIndex(of: node) {
                let newIndex = childIndex + (position == .above ? 0 : 1)

                // Reuse a placeholder instead of inserting a new one in the same place
                if newIndex < targetParent.contents.childrenInSameCollection(as: node).count,
                    let contents = targetParent.contents.childrenInSameCollection(as: node)[newIndex].contents as? SyntaxNodePlaceholdable,
                    contents.isPlaceholder {

                    return (self, targetParent.contents.childrenInSameCollection(as: node)[newIndex])
                } else {
                    let childNode: LGCSyntaxNode = .declaration(.makePlaceholder())
                    let newParent = targetParent.insert(childNode: childNode, atIndex: newIndex)
                    return (self.replace(id: targetParent.uuid, with: newParent), childNode)
                }
            }
        default:
            break
        }

        return nil
    }
}
