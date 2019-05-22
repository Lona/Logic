//
//  EnumType.swift
//  Logic
//
//  Created by Devin Abbott on 5/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

// MARK: - EnumType

public struct EnumType: Codable & Equatable {
    public var name: String
    public var cases: [TypeCase]

    public init(name: String, cases: [TypeCase] = []) {
        self.name = name
        self.cases = cases
    }

    public var genericParameterNames: [String] {
        let all = cases.map({ genericCase -> [String] in
            switch genericCase {
            case .normal(_, let parameters):
                let all = parameters.map({ parameter -> [String] in
                    switch parameter.value {
                    case .generic(let name):
                        return [name]
                    case .type:
                        return []
                    }
                })
                return Array(all.joined())
            case .record(_, let parameters):
                let all = parameters.map({ parameter -> [String] in
                    switch parameter.value {
                    case .generic(let name):
                        return [name]
                    case .type:
                        return []
                    }
                })
                return Array(all.joined())
            }
        })

        return Array(all.joined())
    }
}

// MARK: - CustomDebugStringConvertible

extension EnumType: CustomDebugStringConvertible {
    public var debugDescription: String {
        if genericParameterNames.isEmpty {
            return name
        } else {
            return "\(name)<\(genericParameterNames.joined(separator: ", "))>"
        }
    }
}
