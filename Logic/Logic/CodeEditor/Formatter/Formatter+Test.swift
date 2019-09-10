//
//  Formatter+Test.swift
//  Logic
//
//  Created by Devin Abbott on 3/15/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

func testFormatter() {
    let command: FormatterCommand<String> = .concat(
        [
            .element("Hello"),
            .line,
            .hardLine,
            .indent(
                .concat(
                    [
                        .element("test"),
                        .line,
                        .element("spotlight"),
                        .line,
                        .element("again")
                    ]
                )
            )
        ]
    )

    let lines = command.print(width: 20, spaceWidth: 1, indentWidth: 4, getElementSize: { string, _ in
        CGSize(width: CGFloat(string.count), height: 1)
    })

    Swift.print(lines)
}
