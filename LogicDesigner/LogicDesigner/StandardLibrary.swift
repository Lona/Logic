//
//  StandardLibrary.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 5/25/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation
import Logic

public enum StandardLibrary {
    public static let math = LGCDeclaration.namespace(
        id: UUID(),
        name: .init(id: UUID(), name: "Math"),
        declarations: LGCList<LGCDeclaration>.init(
            [
                .variable(
                    id: UUID(),
                    name: .init(id: UUID(), name: "PI"),
                    annotation: .some(
                        .typeIdentifier(
                            id: UUID(),
                            identifier: .init(id: UUID(), string: "Number"),
                            genericArguments: .empty
                        )
                    ),
                    initializer: .some(
                        .literalExpression(
                            id: UUID(),
                            literal: .number(id: UUID(), value: CGFloat(3.141592653589793))
                        )
                    )
                )
            ]
        )
    )

    public static let include = LGCProgram(id: UUID(), block: LGCList<LGCStatement>(
        [
            .declaration(id: UUID(), content: math)
        ]
    ))
}
