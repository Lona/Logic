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

    init(id: UUID, parameters: Parameters)

    var id: UUID { get }
    var view: View { get }
    var parameters: Parameters { get set }
    var selection: Selection { get set }
    var onChangeParameters: ((Parameters) -> Void)? { get set }
    var onChangeSelection: ((Selection) -> Void)? { get set }
}

extension BlockProtocol {
    init(_ parameters: Parameters) {
        self.init(id: UUID(), parameters: parameters)
    }

    init() {
        let parameters: Parameters = Parameters.init()
        self.init(id: UUID(), parameters: parameters)
    }
}

public enum BlockType: Equatable {
    case text(TextBlock)
    case image(ImageBlock)

    var id: UUID {
        switch self {
        case .text(let value):
            return value.id
        case .image(let value):
            return value.id
        }
    }

    var view: BlockView {
        switch self {
        case .text(let value):
            return value.view
        case .image(let value):
            return value.view
        }
    }

    var parameters: BlockParameters {
        switch self {
        case .text(let value):
            return value.parameters
        case .image(let value):
            return value.parameters
        }
    }

    var onChangeParameters: ((BlockParameters) -> Void)? {
        switch self {
        case .text(let value):
            return value.onChangeParameters
        case .image(let value):
            return value.onChangeParameters
        }
    }

    public static func == (lhs: BlockType, rhs: BlockType) -> Bool {
        switch (lhs, rhs) {
        case let (.text(lhs), .text(rhs)):
            return lhs.id == rhs.id && lhs.parameters == rhs.parameters
        case let (.image(lhs), .image(rhs)):
            return lhs.id == rhs.id && lhs.parameters == rhs.parameters
        default:
            return false
        }
    }
}
