//
//  LGCSyntax+Constructors.swift
//  Logic
//
//  Created by Devin Abbott on 4/3/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension LGCIdentifier {
    public init(id: UUID, string: String) {
        self.id = id
        self.string = string
        self.isPlaceholder = false
    }
}
