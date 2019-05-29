//
//  LGCProgram+Builders.swift
//  Logic
//
//  Created by Devin Abbott on 5/29/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public extension LGCProgram {
    static func join(programs: [LGCProgram]) -> LGCProgram {
        let blocks = Array(programs.map { program in program.block.map { $0 } }.joined())

        return LGCProgram(id: UUID(), block: .init(blocks))
    }
}
