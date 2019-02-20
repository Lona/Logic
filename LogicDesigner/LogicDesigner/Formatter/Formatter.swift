//
//  Formatter.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public protocol FormattableElement {
    var width: CGFloat { get }
}

public enum Formatter {
    public struct FormattedElement {
        var element: FormattableElement
        var position: CGFloat
    }

    public indirect enum Command {
        case element(FormattableElement)
        case line
        case indent(() -> Command)
        case hardLine
        case concat(() -> [Command])
    }

    static func print(
        command: Command,
        width maxLineWidth: CGFloat,
        spaceWidth: CGFloat,
        indentWidth: CGFloat
        ) -> [[FormattedElement]] {

        var rows: [[FormattedElement]] = []

        var currentRow: [FormattedElement] = []
        var currentOffset: CGFloat = 0
        var currentIndentLevel: Int = 0

        func moveToNextRow() {
            rows.append(currentRow)
            currentRow = []
            currentOffset = CGFloat(currentIndentLevel) * indentWidth
        }

        func process(command: Command) {
            switch command {
            case .indent(let child):
                currentIndentLevel += 1
                process(command: child())
                currentIndentLevel -= 1
            case .line:
                if currentOffset + spaceWidth >= maxLineWidth {
                    moveToNextRow()
                }

                currentOffset += spaceWidth
            case .hardLine:
                moveToNextRow()
            case .element(let element):
                let elementWidth = element.width

                if currentOffset + elementWidth >= maxLineWidth {
                    moveToNextRow()
                }

                currentRow.append(FormattedElement(element: element, position: currentOffset))

                currentOffset += elementWidth
            case .concat(let commands):
                commands().forEach(process)
            }
        }

        process(command: command)

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }
}

extension String: FormattableElement {
    public var width: CGFloat {
        return CGFloat(count)
    }
}

func testFormatter() {
    let command: Formatter.Command = .concat {
        [
            .element("Hello"),
            .line,
            .hardLine,
            .indent {
                .concat {
                    [
                        .element("test"),
                        .line,
                        .element("spotlight"),
                        .line,
                        .element("again")
                    ]
                }
            }
        ]
    }

    let lines = Formatter.print(command: command, width: 20, spaceWidth: 1, indentWidth: 4)

    Swift.print(lines)
}
