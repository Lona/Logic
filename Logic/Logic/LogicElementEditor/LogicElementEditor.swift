import AppKit

// MARK: - LogicElementEditor

public class LogicElementEditor: NSView {

    // MARK: Lifecycle

    public init() {
        super.init(frame: .zero)

        setUpViews()
        setUpConstraints()

        update()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public var formattedContent: Formatter<LogicElement>.Command = .hardLine {
        didSet {
//            invalidateIntrinsicContentSize()
            update()
        }
    }
    public var selectedRange: Range<Int>? {
        didSet {
            update()
        }
    }
    public var outlinedRange: Range<Int>? {
        didSet {
            update()
        }
    }
    public var selectedLine: Int? {
        didSet {
            update()
        }
    }
    public var onActivate: ((Int?) -> Void)?
    public var onActivateLine: ((Int) -> Void)?

    // MARK: Styles

    private var selectedIndex: Int? {
        return selectedRange?.lowerBound
    }

    public var selectionEndIndex: Int? {
        return selectedRange?.upperBound
    }

    public static var textMargin = CGSize(width: 6, height: 6)
    public static var textPadding = CGSize(width: 4, height: 3)
    public static var textBackgroundRadius = CGSize(width: 2, height: 2)

    public static var outlineWidth: CGFloat = 2.0

    public static var textSpacing: CGFloat = 4.0
    public static var lineSpacing: CGFloat = 6.0
    public static var minimumLineHeight: CGFloat = 22.0
    public static var dropdownCarets: Bool = false

    public static var font = TextStyle(family: "San Francisco", size: 13).nsFont

    var selectedElement: LogicElement? {
        return selectedMeasuredElement?.element
    }

    var selectedMeasuredElement: LogicMeasuredElement? {
        guard let index = selectedIndex else { return nil }
        return measuredElements[index]
    }

    func reactivate() {
        onActivate?(selectedIndex)
    }

    // MARK: Overrides

    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    public override var acceptsFirstResponder: Bool {
        return true
    }

    public func nextActivatableIndex(after currentIndex: Int?) -> Int? {
        let measuredElements = self.measuredElements

        let activatableElements = measuredElements.enumerated()
            .filter { $0.element.element.syntaxNodeID != nil }

        if activatableElements.isEmpty { return nil }

        // If there is no selection, focus the first element
        guard let currentIndex = currentIndex else { return activatableElements.first?.offset }

        guard currentIndex < measuredElements.count,
            let currentID = measuredElements[currentIndex].element.syntaxNodeID else { return nil }

        if let index = activatableElements.firstIndex(where: { $0.element.element.syntaxNodeID == currentID }),
            index + 1 < activatableElements.count {
            return activatableElements[index + 1].offset
        } else {
            return nil
        }
    }

    public func previousActivatableIndex(before currentIndex: Int?) -> Int? {
        let measuredElements = self.measuredElements

        let activatableElements = measuredElements.enumerated()
            .filter { $0.element.element.syntaxNodeID != nil }

        if activatableElements.isEmpty { return nil }

        // If there is no selection, focus the last element
        guard let currentIndex = currentIndex else { return activatableElements.last?.offset }

        guard currentIndex < measuredElements.count,
            let currentID = measuredElements[currentIndex].element.syntaxNodeID else { return nil }

        if let index = activatableElements.firstIndex(where: { $0.element.element.syntaxNodeID == currentID }),
            index - 1 >= 0 {
            return activatableElements[index - 1].offset
        } else {
            return nil
        }
    }

    public func getBoundingRect(for index: Int) -> CGRect? {
        if index >= measuredElements.count { return nil }

        return flip(rect: measuredElements[index].backgroundRect)
    }

    public override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if let index = measuredElements.firstIndex(where: { $0.backgroundRect.contains(point) }) {
            onActivate?(index)
        // If we didn't select an element, try to select a line.
        // Find the first element lower than the mouse.
        } else if let lineElementIndex = measuredElements.firstIndex(where: {
            point.y < $0.backgroundRect.maxY
        }) {
            onActivateLine?(formattedContent.lineIndex(for: lineElementIndex))
        } else {
            onActivate?(nil)
        }
    }

    public override func keyDown(with event: NSEvent) {
        Swift.print("LogicElementEditor kd", event.keyCode)

        switch Int(event.keyCode) {
        case 36: // Enter
            if let selectedIndex = selectedIndex {
                onActivate?(selectedIndex)
            } else if let selectedLine = selectedLine {
                let range = formattedContent.elementIndexRange(for: selectedLine)
                onActivate?(range.lowerBound)
            } else {
                onActivate?(nil)
            }
        case 48: // Tab
            let shiftKey = event.modifierFlags.contains(NSEvent.ModifierFlags.shift)

            Swift.print("Tab \(shiftKey ? "shift" : "no shift")")

            if shiftKey {
                if let previousIndex = previousActivatableIndex(before: selectedIndex) {
                    onActivate?(previousIndex)
                }
            } else {
                if let nextIndex = nextActivatableIndex(after: selectedIndex) {
                    onActivate?(nextIndex)
                }
            }
        case 123: // Left
            Swift.print("Left arrow")
        case 124: // Right
            Swift.print("Right arrow")
        case 125: // Down
            if let selectedLine = selectedLine, selectedLine + 1 < formattedContent.logicalRows.count {
                onActivateLine?(selectedLine + 1)
            }
        case 126: // Up
            if let selectedLine = selectedLine, selectedLine - 1 >= 0 {
                onActivateLine?(selectedLine - 1)
            }
        default:
            break
        }
    }

    private var heightConstraint: NSLayoutConstraint = NSLayoutConstraint()

    public override var isFlipped: Bool {
        return true
    }

    public override var intrinsicContentSize: NSSize {
        return NSSize(width: NSView.noIntrinsicMetric, height: minHeight)
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSGraphicsContext.current?.cgContext.setShouldSmoothFonts(false)

        if let selectedLine = selectedLine {
            let range = formattedContent.elementIndexRange(for: selectedLine)
            let elements = measuredElements[range]
            if let first = elements.first, let last = elements.last {
                NSColor.selectedMenuItemColor.highlight(withLevel: 0.9)?.set()
                let rect = NSRect(
                    x: 0,
                    y: first.backgroundRect.minY,
                    width: bounds.width,
                    height: last.backgroundRect.maxY - first.backgroundRect.minY)
                let path = NSBezierPath(rect: rect)
                path.fill()
            }
        }

        if let range = outlinedRange {
            var rect = measuredElements[range.startIndex].backgroundRect
            for index in range.startIndex...range.endIndex {
                rect = rect.union(measuredElements[index].backgroundRect)
            }
            NSColor.selectedMenuItemColor.setStroke()
            let path = NSBezierPath(
                roundedRect: rect.insetBy(dx: LogicElementEditor.outlineWidth / 2, dy: LogicElementEditor.outlineWidth / 2),
                xRadius: LogicElementEditor.textBackgroundRadius.width,
                yRadius: LogicElementEditor.textBackgroundRadius.height)
            path.lineWidth = LogicElementEditor.outlineWidth
            path.stroke()
        } else {
            if let start = selectedIndex, let end = selectionEndIndex, start < end, end < measuredElements.count {
                var rect = measuredElements[start].backgroundRect
                for index in start...end {
                    rect = rect.union(measuredElements[index].backgroundRect)
                }
                NSColor.selectedMenuItemColor.highlight(withLevel: 0.8)?.set()
                NSBezierPath(
                    roundedRect: rect,
                    xRadius: LogicElementEditor.textBackgroundRadius.width,
                    yRadius: LogicElementEditor.textBackgroundRadius.height).fill()
            }
        }

        measuredElements.enumerated().forEach { textIndex, measuredText in
            let selected = textIndex == self.selectedIndex
            let text = measuredText.element
            let rect = measuredText.attributedStringRect
            let backgroundRect = measuredText.backgroundRect
            let attributedString = measuredText.attributedString

            switch (text) {
            case .text, .coloredText:
                attributedString.draw(at: rect.origin)
            case .dropdown(_, let value, let color):
                let drawSelection = selected && outlinedRange == nil
                let color = drawSelection ? NSColor.selectedMenuItemColor : color

                let shadow = NSShadow()
                shadow.shadowBlurRadius = 1
                shadow.shadowOffset = NSSize(width: 0, height: -1)
                shadow.shadowColor = NSColor.black.withAlphaComponent(0.2)
                shadow.set()

                if drawSelection {
                    color.setFill()
                } else {
                    NSColor.clear.setFill()
                }

                let backgroundPath = NSBezierPath(
                    roundedRect: backgroundRect,
                    xRadius: LogicElementEditor.textBackgroundRadius.width,
                    yRadius: LogicElementEditor.textBackgroundRadius.height)
                backgroundPath.fill()

                NSShadow().set()

                if LogicElementEditor.dropdownCarets || value.isEmpty {
                    if drawSelection {
                        NSColor.white.setStroke()
                    } else {
                        color.setStroke()
                    }

                    let caretX = rect.maxX + (value.isEmpty ? 0 : 3)
                    let caret = NSBezierPath(downwardCaretWithin:
                        CGRect(x: caretX, y: backgroundRect.midY, width: 5, height: 2.5))

                    caret.stroke()
                }

                if drawSelection {
                    let attributedString = NSMutableAttributedString(attributedString: attributedString)
                    attributedString.addAttributes(
                        [NSAttributedString.Key.foregroundColor: NSColor.white],
                        range: NSRange(location: 0, length: attributedString.length))
                    attributedString.draw(at: rect.origin)
                } else {
                    attributedString.draw(at: rect.origin)
                }
            }
        }
    }

    private var _cachedMeasuredElements: [LogicMeasuredElement]? = nil

    private var measuredElements: [LogicMeasuredElement] {
        if let cached = _cachedMeasuredElements {
            return cached
        }

        let formattedElementLines = formattedContent.print(
            width: bounds.width - LogicElementEditor.textMargin.width * 2,
            spaceWidth: LogicElementEditor.textSpacing,
            indentWidth: 20)

        let yOffset = LogicElementEditor.textMargin.height
        var measuredLine: [LogicMeasuredElement] = []
        var formattedElementIndex = 0

        formattedElementLines.enumerated().forEach { rowIndex, formattedElementLine in
            formattedElementLine.forEach { formattedElement in
                let measured = formattedElement.element.measured(
                    selected: self.selectedIndex == formattedElementIndex,
                    offset: CGPoint(
                        x: LogicElementEditor.textMargin.width + formattedElement.position,
                        y: yOffset + CGFloat(rowIndex) * LogicElementEditor.minimumLineHeight))

                measuredLine.append(measured)

                formattedElementIndex += 1
            }
        }

        _cachedMeasuredElements = measuredLine

        return measuredLine
    }

    private var minHeight: CGFloat {
        let contentHeight = measuredElements.last?.backgroundRect.maxY ?? LogicElementEditor.textMargin.height
        let minHeight = contentHeight + LogicElementEditor.textMargin.height
        return minHeight
    }

    private var previousHeight: CGFloat = -1

    // MARK: Private

    private func flip(rect: CGRect) -> CGRect {
        return CGRect(
            x: rect.origin.x,
            y: bounds.height - rect.height - rect.origin.y,
            width: rect.width,
            height: rect.height)
    }

    private func setUpViews() {}

    private func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
    }

    private func update() {
        _cachedMeasuredElements = nil
        needsDisplay = true
    }

    public override func layout() {
        super.layout()

        _cachedMeasuredElements = nil

        let minHeight = self.minHeight
        if minHeight != previousHeight {
            previousHeight = minHeight
            invalidateIntrinsicContentSize()
        }
    }
}
