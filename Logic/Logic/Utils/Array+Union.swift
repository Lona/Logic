//
//  Array+Union.swift
//  Logic
//
//  Created by Devin Abbott on 4/6/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension Array where Element == CGRect {
    public var union: CGRect {
        guard let first = self.first else { return .zero }

        return self.dropFirst().reduce(first, { result, rect in
            return result.union(rect)
        })
    }
}
