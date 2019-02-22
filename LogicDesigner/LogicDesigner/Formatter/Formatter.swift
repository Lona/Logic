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

public enum Formatter<Element: FormattableElement> {
    public struct FormattedElement {
        var element: Element
        var position: CGFloat
    }

    public indirect enum Command {
        case element(Element)
        case line
        case indent(() -> Command)
        case hardLine
        case join(with: Command, () -> [Command])
        case concat(() -> [Command])

        func print(
            width maxLineWidth: CGFloat,
            spaceWidth: CGFloat,
            indentWidth: CGFloat
            ) -> [[Formatter<Element>.FormattedElement]] {

            return Formatter<Element>.print(
                command: self,
                width: maxLineWidth,
                spaceWidth: spaceWidth,
                indentWidth: indentWidth)
        }

        var elements: [Element] {
            var allElements: [Element] = []

            func process(command: Command) {
                switch command {
                case .indent(let child):
                    process(command: child())
                case .line, .hardLine:
                    break
                case .element(let element):
                    allElements.append(element)
                case .concat(let commands):
                    commands().forEach(process)
                case .join(with: let separator, let commands):
                    process(command: Formatter.performJoin(with: separator, commands))
                }
            }

            process(command: self)

            return allElements
        }
    }

    static func print(
        command: Command,
        width maxLineWidth: CGFloat,
        spaceWidth: CGFloat,
        indentWidth: CGFloat
        ) -> [[Formatter<Element>.FormattedElement]] {

        var rows: [[Formatter<Element>.FormattedElement]] = []

        var currentRow: [Formatter<Element>.FormattedElement] = []
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

                let formattedElement = Formatter<Element>.FormattedElement(element: element, position: currentOffset)
                currentRow.append(formattedElement)

                currentOffset += elementWidth
            case .concat(let commands):
                commands().forEach(process)
            case .join(with: let separator, let commands):
                process(command: Formatter.performJoin(with: separator, commands))
            }
        }

        process(command: command)

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    private static func performJoin(with separator: Command, _ commands: () -> [Command]) -> Command {
        var joinedCommands: [Command] = []
        let commands = commands()

        commands.enumerated().forEach { offset, command in
            joinedCommands.append(command)

            if offset < commands.count - 1 {
                joinedCommands.append(separator)
            }
        }

        return .concat { joinedCommands }
    }
}

extension String: FormattableElement {
    public var width: CGFloat {
        return CGFloat(count)
    }
}

func testFormatter() {
    let command: Formatter<String>.Command = .concat {
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
