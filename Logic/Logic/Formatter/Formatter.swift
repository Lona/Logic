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

public indirect enum FormatterCommand<Element: FormattableElement> {
    case element(Element)
    case line
    case indent(() -> FormatterCommand)
    case hardLine
    case join(with: FormatterCommand, () -> [FormatterCommand])
    case concat(() -> [FormatterCommand])

    public struct FormattedElement {
        var element: Element
        var position: CGFloat
    }

    public var elements: [Element] {
        return Array(logicalRows.joined())
    }

    public var logicalRows: [[Element]] {
        var rows: [[Element]] = []

        var currentRow: [Element] = []

        func moveToNextRow() {
            rows.append(currentRow)
            currentRow = []
        }

        func process(command: FormatterCommand) {
            switch command {
            case .indent(let child):
                process(command: child())
            case .line:
                break
            case .hardLine:
                moveToNextRow()
            case .element(let element):
                currentRow.append(element)
            case .concat(let commands):
                commands().forEach(process)
            case .join(with: let separator, let commands):
                process(command: FormatterCommand.performJoin(with: separator, commands))
            }
        }

        process(command: self)

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    func lineIndex(for elementIndex: Int) -> Int {
        var elementCount = 0
        for (offset, formattedLine) in logicalRows.enumerated() {
            elementCount += formattedLine.count

            if elementIndex < elementCount {
                return offset
            }
        }

        fatalError("Could not find line number for element index \(elementIndex)")
    }

    func elementIndexRange(for lineIndex: Int) -> Range<Int> {
        var elementCount = 0
        for (offset, formattedLine) in logicalRows.enumerated() {
            let endElementCount = elementCount + formattedLine.count

            if offset == lineIndex {
                return elementCount..<endElementCount
            }

            elementCount = endElementCount
        }

        fatalError("Could not find element range for line index \(lineIndex)")
    }

    func print(
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

        func process(command: FormatterCommand) {
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

                if currentOffset + elementWidth >= maxLineWidth && !currentRow.isEmpty {
                    moveToNextRow()
                }

                let formattedElement = FormatterCommand<Element>.FormattedElement(element: element, position: currentOffset)
                currentRow.append(formattedElement)

                currentOffset += elementWidth
            case .concat(let commands):
                commands().forEach(process)
            case .join(with: let separator, let commands):
                process(command: FormatterCommand.performJoin(with: separator, commands))
            }
        }

        process(command: self)

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    private static func performJoin(with separator: FormatterCommand, _ commands: () -> [FormatterCommand]) -> FormatterCommand {
        var joinedCommands: [FormatterCommand] = []
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
    let command: FormatterCommand<String> = .concat {
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

    let lines = command.print(width: 20, spaceWidth: 1, indentWidth: 4)

    Swift.print(lines)
}
