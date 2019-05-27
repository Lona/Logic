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
                .function(
                    id: UUID(),
                    name: .init(id: UUID(), name: "min"),
                    returnType: .typeIdentifier(id: UUID(), identifier: .init(id: UUID(), string: "Number"), genericArguments: .empty),
                    genericParameters: .empty,
                    parameters: LGCList<LGCFunctionParameter>(
                        [
                            .parameter(
                                id: UUID(),
                                externalName: nil,
                                localName: .init(id: UUID(), name: "a"),
                                annotation: .typeIdentifier(id: UUID(), identifier: .init(id: UUID(), string: "Number"), genericArguments: .empty),
                                defaultValue: .none(id: UUID())
                            ),
                            .parameter(
                                id: UUID(),
                                externalName: nil,
                                localName: .init(id: UUID(), name: "b"),
                                annotation: .typeIdentifier(id: UUID(), identifier: .init(id: UUID(), string: "Number"), genericArguments: .empty),
                                defaultValue: .none(id: UUID())
                            ),
                        ]
                    ),
                    block: .empty
                ),
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
            .declaration(
                id: UUID(),
                content: LGCDeclaration.record(
                    id: UUID(),
                    name: .init(id: UUID(), name: "Boolean"),
                    declarations: .empty
                )
            ),
            .declaration(
                id: UUID(),
                content: LGCDeclaration.record(
                    id: UUID(),
                    name: .init(id: UUID(), name: "Number"),
                    declarations: .empty
                )
            ),
            .declaration(
                id: UUID(),
                content: LGCDeclaration.record(
                    id: UUID(),
                    name: .init(id: UUID(), name: "String"),
                    declarations: .empty
                )
            ),
            .declaration(
                id: UUID(),
                content: .enumeration(
                    id: UUID(),
                    name: .init(id: UUID(), name: "Optional"),
                    genericParameters: .init(
                        [
                            .parameter(id: UUID(), name: .init(id: UUID(), name: "Wrapped"))
                        ]
                    ),
                    cases: .empty
                )
            ),
            .declaration(id: UUID(), content: math),
        ]
    ))

    public static let program: LGCSyntaxNode = .program(StandardLibrary.include)
}
