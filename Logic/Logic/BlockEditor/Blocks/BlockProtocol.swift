//
//  BlockProtocol.swift
//  Logic
//
//  Created by Devin Abbott on 9/15/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

protocol BlockSelection {
    init()
}

protocol BlockParameters {
    init()
}

protocol BlockView where Self: NSView {}

protocol BlockProtocol {
    associatedtype View: BlockView
    associatedtype Parameters: BlockParameters
    associatedtype Selection: BlockSelection

    init(id: UUID)

    var id: UUID { get }
    var view: View { get }
    var parameters: Parameters { get set }
    var selection: Selection { get set }
    var onChangeParameters: ((Parameters) -> Void)? { get set }
    var onChangeSelection: ((Selection) -> Void)? { get set }
}

extension BlockProtocol {
    init(id: UUID, parameters: Parameters) {
        self.init(id: id)
        self.parameters = parameters
    }

    init(_ parameters: Parameters) {
        self.init(id: UUID())
        self.parameters = parameters
    }
}
