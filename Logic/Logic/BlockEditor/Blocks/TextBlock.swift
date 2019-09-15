//
//  TextBlock.swift
//  Logic
//
//  Created by Devin Abbott on 9/15/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension InlineBlockEditor: BlockView {}

extension NSAttributedString: BlockParameters {}

extension NSRange: BlockSelection {}

public struct TextBlock: BlockProtocol {
    public typealias View = InlineBlockEditor
    public typealias Parameters = NSAttributedString
    public typealias Selection = NSRange

    public init(id: UUID, parameters: Parameters) {
        self.id = id
        self.parameters = parameters
    }

    public var id: UUID

    public var view: View = InlineBlockEditor()

    public var parameters: Parameters {
        get { return view.textValue }
        set { view.textValue = newValue }
    }

    public var selection: Selection {
        get { return view.selectedRange() }
        set { view.setSelectedRangesWithoutNotification([NSValue(range: newValue)]) }
    }

    public var onChangeParameters: ((Parameters) -> Void)? {
        get { return view.onChangeTextValue }
        set { view.onChangeTextValue = newValue }
    }

    public var onChangeSelection: ((Selection) -> Void)? {
        get { return view.onChangeSelectedRange }
        set { view.onChangeSelectedRange = newValue }
    }
}
