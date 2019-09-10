//
//  Formatter.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public indirect enum FormatterCommand<Element> {
    case element(Element)
    case line
    case indent(@autoclosure () -> FormatterCommand)
    case hardLine
    case join(with: FormatterCommand, () -> [FormatterCommand])
    case concat(@autoclosure () -> [FormatterCommand])
    case horizontalFloat(decoration: Element, margins: NSEdgeInsets, FormatterCommand)
    case floatRightCollapse(Element)
    case spacer(CGFloat)

    public static var empty: FormatterCommand<Element> {
        return .concat([])
    }

    public struct FormattedElement {
        var element: Element
        var origin: CGPoint
        var size: CGSize

        var x: CGFloat { return origin.x }
        var y: CGFloat { return origin.y }
        var height: CGFloat { return size.height }
        var width: CGFloat { return size.width }
    }

    public var elements: [Element] {
        return Array(logicalRows.joined())
    }

    public var logicalRows: [[Element]] {
        var rows: [[Element]] = []

        var currentRow: [Element] = []
        var currentRowContainsNonFloatingElement = false

        func append(element: Element) {
            currentRow.append(element)
            currentRowContainsNonFloatingElement = true
        }

        func moveToNextRow() {
            rows.append(currentRow)
            currentRow = []
            currentRowContainsNonFloatingElement = false
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
                append(element: element)
            case .concat(let commands):
                commands().forEach(process)
            case .join(with: let separator, let commands):
                process(command: FormatterCommand.performJoin(with: separator, commands))
            case .horizontalFloat(let element, _, let command):
                if !currentRow.isEmpty && currentRowContainsNonFloatingElement {
                    moveToNextRow()
                }
                append(element: element)
                process(command: command)
                if !currentRow.isEmpty {
                    moveToNextRow()
                }
            case .spacer:
                break
            case .floatRightCollapse(let element):
                currentRow.append(element)
            }
        }

        process(command: self)

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    func elementIndexRange(for lineIndex: Int) -> Range<Int>? {
        var elementCount = 0
        for (offset, formattedLine) in logicalRows.enumerated() {
            let endElementCount = elementCount + formattedLine.count

            if offset == lineIndex {
                return elementCount..<endElementCount
            }

            elementCount = endElementCount
        }

        return nil
    }

    func print(
        width maxLineWidth: CGFloat,
        minimumLineHeight: CGFloat = 22,
        spaceWidth: CGFloat,
        indentWidth: CGFloat,
        getElementSize: @escaping (Element, Int) -> CGSize
        ) -> [[FormattedElement]] {

        var rows: [[FormattedElement]] = []

        var currentRow: [FormattedElement] = []
        var currentXOffset: CGFloat = 0
        var currentYOffset: CGFloat = 0
        var currentMaxElementHeight: CGFloat = 0
        var currentIndentLevel: Int = 0
        var currentElementIndex: Int = 0
        var currentDecorationIndent: CGFloat = 0
        var currentRowContainsNonFloatingElement = false
        var currentRightFloatingElementWidth: CGFloat = 0

        func append(element: FormattedElement) {
            currentRow.append(element)
            currentMaxElementHeight = max(currentMaxElementHeight, element.size.height)
            currentElementIndex += 1
            currentRowContainsNonFloatingElement = true
        }

        func append(rightFloatingElement element: FormattedElement) {
            currentRow.append(element)
            currentMaxElementHeight = max(currentMaxElementHeight, element.size.height)
            currentElementIndex += 1
            if currentRightFloatingElementWidth == 0 {
                currentRightFloatingElementWidth = element.size.width
            }
        }

        func append(decoration: FormattedElement) -> (row: Int, column: Int) {
            let result = (rows.count, currentRow.count)
            currentRow.append(decoration)
            currentElementIndex += 1
            return result
        }

        func moveToNextRow(wrapping: Bool) {
            rows.append(currentRow)
            currentRow = []
            currentXOffset = currentDecorationIndent + CGFloat(currentIndentLevel + (wrapping ? 2 : 0)) * indentWidth
            currentYOffset += currentMaxElementHeight
            currentMaxElementHeight = minimumLineHeight
            currentRowContainsNonFloatingElement = false
            currentRightFloatingElementWidth = 0
        }

        func process(command: FormatterCommand) {
            switch command {
            case .indent(let child):
                currentIndentLevel += 1
                process(command: child())
                currentIndentLevel -= 1
            case .line:
                if currentXOffset + spaceWidth >= maxLineWidth {
                    moveToNextRow(wrapping: false)
                }

                currentXOffset += spaceWidth
            case .hardLine:
                moveToNextRow(wrapping: false)
            case .element(let element):
                let elementSize = getElementSize(element, currentElementIndex)

                if currentXOffset + elementSize.width + currentRightFloatingElementWidth >= maxLineWidth && !currentRow.isEmpty {
                    moveToNextRow(wrapping: true)
                }

                let formattedElement = FormatterCommand<Element>.FormattedElement(
                    element: element, origin: CGPoint(x: currentXOffset, y: currentYOffset), size: elementSize)
                append(element: formattedElement)

                currentXOffset += elementSize.width
            case .concat(let commands):
                commands().forEach(process)
            case .join(with: let separator, let commands):
                process(command: FormatterCommand.performJoin(with: separator, commands))
            case .horizontalFloat(let decoration, let margins, let command):
                if !currentRow.isEmpty && currentRowContainsNonFloatingElement {
                    moveToNextRow(wrapping: false)
                }

                currentYOffset += margins.top

                let decorationSize = getElementSize(decoration, currentElementIndex)

                let formattedDecoration = FormatterCommand<Element>.FormattedElement(
                    element: decoration,
                    origin: CGPoint(x: currentXOffset + margins.left, y: currentYOffset),
                    size: decorationSize
                )

                let position = append(decoration: formattedDecoration)
                let horizontalMargin = margins.left + margins.right

//                Swift.print(position)

                let initialYOffset = currentYOffset
                currentXOffset += decorationSize.width + horizontalMargin

                currentDecorationIndent += decorationSize.width + horizontalMargin
                process(command: command)
                currentDecorationIndent -= (decorationSize.width + horizontalMargin)

                if !currentRow.isEmpty {
                    moveToNextRow(wrapping: false)
                }

                let deltaY = currentYOffset - initialYOffset
//                Swift.print(deltaY)
                rows[position.row][position.column].size.height = deltaY

                currentYOffset -= minimumLineHeight
                currentYOffset += margins.bottom

//                Swift.print(currentYOffset, initialYOffset, decorationSize.height)

                currentYOffset = max(currentYOffset, initialYOffset + decorationSize.height - minimumLineHeight)
            case .spacer(let size):
                currentYOffset += size
            case .floatRightCollapse(let element):
                let elementSize = getElementSize(element, currentElementIndex)

                let formattedElement = FormatterCommand<Element>.FormattedElement(
                    element: element, origin: CGPoint(x: maxLineWidth - elementSize.width, y: currentYOffset), size: elementSize)

                append(rightFloatingElement: formattedElement)
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

        return .concat(joinedCommands)
    }
}
