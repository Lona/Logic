//
//  ImageBlock.swift
//  Logic
//
//  Created by Devin Abbott on 9/15/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension LNAImageView: BlockView {}

extension String: BlockParameters {}

extension Bool: BlockSelection {}

public struct ImageBlock: BlockProtocol {
    public typealias View = LNAImageView
    public typealias Parameters = String
    public typealias Selection = Bool

    public init(id: UUID, parameters: Parameters) {
        self.id = id
        self.parameters = parameters
    }

    public var id: UUID

    public var view: View = View()

    public var parameters: Parameters {
        didSet {
            if oldValue != parameters {
                if let url = URL(string: parameters) {
                    view.image = NSImage(byReferencing: url)
                }
            }
        }
    }

    public var selection: Selection = false

    public var onChangeParameters: ((Parameters) -> Void)?

    public var onChangeSelection: ((Selection) -> Void)?
}
