//
//  InlineBlockLayoutManager.swift
//  Logic
//
//  Created by Devin Abbott on 10/13/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

class InlineBlockLayoutManager: NSLayoutManager {

    var getFont: (() -> NSFont?) = { return nil }

    private var font: NSFont {
        return getFont()!
    }

    private var lineHeight: CGFloat {
        let fontLineHeight = self.defaultLineHeight(for: font)
        let lineHeight = fontLineHeight * TextBlockView.lineHeightMultiple
        return lineHeight
    }

    // Takes care only of the last empty newline in the text backing
    // store, or totally empty text views.
    override func setExtraLineFragmentRect(
        _ fragmentRect: NSRect,
        usedRect: NSRect,
        textContainer container: NSTextContainer) {

        // This is only called when editing, and re-computing the
        // `lineHeight` isn't that expensive, so I do no caching.
        let lineHeight = self.lineHeight
        var fragmentRect = fragmentRect
        fragmentRect.size.height = lineHeight
        var usedRect = usedRect
        usedRect.size.height = lineHeight

        super.setExtraLineFragmentRect(fragmentRect,
            usedRect: usedRect,
            textContainer: container)
    }
}
