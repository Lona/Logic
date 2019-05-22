//
//  Dictionary+Keys.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 5/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension Dictionary where Value: Equatable {
    public func keys(for value: Value) -> [Key] {
        var results: [Key] = []

        for pair in self {
            if value == pair.value {
                results.append(pair.key)
            }
        }

        return results
    }

    public func firstKey(for value: Value) -> Key? {
        for pair in self {
            if value == pair.value {
                return value
            }
        }

        return nil
    }
}
