//
//  EditableBlockFactory.swift
//  Logic
//
//  Created by Devin Abbott on 10/2/20.
//  Copyright © 2020 BitDisco, Inc. All rights reserved.
//

import Foundation

public class EditableBlockFactory {

    var transformImageURL: ((URL) -> URL)?

    private func makeView(block: EditableBlock) -> NSView {
        switch block.content {
        case .text:
            return TextBlockContainerView()
        case .page(title: let title, target: let target):
            return PageBlock(titleText: "→ " + title, linkTarget: target)
        case .tokens(let syntaxNode):
            let view = LogicEditor(rootNode: syntaxNode, formattingOptions: .visual)
            view.fillColor = Colors.blockBackground
            view.cornerRadius = 4

            var style = view.canvasStyle
            style.textMargin = .init(width: 8, height: 8)
            view.canvasStyle = style

            view.scrollsVertically = false

            return view
        case .divider:
            return DividerBlock()
        case .image:
            return ImageBackground()
        }
    }

    private func configure(block: EditableBlock, view: NSView) {
        switch block.content {
        case .text(let attributedString, let sizeLevel):
            let view = view as! TextBlockContainerView
            view.textValue = attributedString
            view.sizeLevel = sizeLevel
            view.onRequestInvalidateIntrinsicContentSize = { [weak self] in
                self?.wrapperView(for: block).invalidateIntrinsicContentSize()
            }
        case .page(title: let title, _):
            let view = view as! PageBlock
            view.title = "→ " + title
        case .tokens(let value):
            let view = view as! LogicEditor
            view.rootNode = value
        case .divider:
            break
        case .image(let url):
            let view = view as! ImageBackground

            if let url = url {
                let transformedURL = transformImageURL?(url) ?? url

                if let image = EditableBlockFactory.fetchImage(transformedURL) {
                    view.image = image
                    return
                }
            }

            view.image = nil
        }
    }

    public func view(for block: EditableBlock) -> NSView {
        if let view = viewCache[block.id] { return view }

        let view = makeView(block: block)
        configure(block: block, view: view)
        viewCache[block.id] = view
        return view
    }

    public func wrapperView(for block: EditableBlock) -> EditableBlockView {
        if let wrapperView = wrapperViewCache[block.id] {
            // TODO: Updating the wrapperView should probably go wherever we update the view.
            // However, this should be consistent with behavior before refactoring, so will leave
            // it here for now.
            wrapperView.listDepth = block.listDepth
            wrapperView.lineButtonAlignmentHeight = block.lineButtonAlignmentHeight

            return wrapperView
        }

        let wrapperView = EditableBlockView()
        wrapperView.contentView = view(for: block)

        wrapperViewCache[block.id] = wrapperView

        return wrapperView
    }

    public func updateView(block: EditableBlock) {
        configure(block: block, view: view(for: block))
        enqueueLayoutUpdate(block: block)
    }

    public func updateViewWidth(block: EditableBlock, _ width: CGFloat) {
        let width = width - block.listDepth.margin

        switch block.content {
        case .text:
            let view = self.view(for: block) as! TextBlockContainerView
            view.width = width
        default:
            break
        }
    }

    public func enqueueLayoutUpdate(block: EditableBlock) {
        let wrapperView = self.wrapperView(for: block)

        switch block.content {
        case .text:
            wrapperView.invalidateIntrinsicContentSize()
            wrapperView.needsLayout = true
        default:
            wrapperView.needsLayout = true
        }
    }

    private var viewCache: [UUID: NSView] = [:]

    private var wrapperViewCache: [UUID: EditableBlockView] = [:]

    static var fetchImage: (URL) -> NSImage? = Memoize.all { url in
        guard let data = try? Data(contentsOf: url), let image = NSImage(data: data) else { return nil }
        return image
    }
}
