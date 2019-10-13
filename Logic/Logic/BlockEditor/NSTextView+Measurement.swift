//
//  NSTextView+Measurement.swift
//  Logic
//
//  Created by Devin Abbott on 10/13/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

extension NSTextView {
    var lineRects: [NSRect] {
        guard let container = textContainer, let manager = container.layoutManager else { return [] }

        let fullGlyphRange = manager.glyphRange(for: container)
        var rects: [NSRect] = []

        manager.enumerateLineFragments(forGlyphRange: fullGlyphRange) { (rect, usedRect, textContainer, glyphRange, boolPointer) in
            rects.append(rect)
        }

        if manager.extraLineFragmentRect.height > 4 {
            rects.append(manager.extraLineFragmentRect)
        }

        return rects
    }

    var currentLineFragmentIndex: Int? {
        guard let container = textContainer, let manager = container.layoutManager else { return nil }

        let selectedGlyphRange = manager.glyphRange(forCharacterRange: selectedRange(), actualCharacterRange: nil)
        let selectedGlyphRect = manager.boundingRect(forGlyphRange: selectedGlyphRange, in: container)

        for (line, rect) in lineRects.enumerated() {
            if rect.minY <= selectedGlyphRect.midY && selectedGlyphRect.midY <= rect.maxY {
                return line
            }
        }

        return nil
    }

    public func nearestCharacter(at point: NSPoint) -> Int? {
        guard let container = textContainer, let manager = container.layoutManager else { return nil }

        let glyph = manager.glyphIndex(for: point, in: container, fractionOfDistanceThroughGlyph: nil)

        return manager.characterIndexForGlyph(at: glyph)
    }


    public var linkRects: [(rect: NSRect, url: NSURL)] {
        guard let container = textContainer, let manager = container.layoutManager else { return [] }

        let textValue = attributedString()
        var values: [(NSRect, NSURL)] = []

        textValue.enumerateAttribute(.link, in: .init(location: 0, length: textValue.length), options: []) { (value, range, pointer) in
            guard let link = value as? NSURL else { return }

            let glyphRange = manager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            let rect = manager.boundingRect(forGlyphRange: glyphRange, in: container)

            values.append((rect, link))
        }

        return values
    }
}
