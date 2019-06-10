import AppKit

// MARK: - NSPasteboard.PasteboardType

public extension NSPasteboard.PasteboardType {
    static let logicLineIndex = NSPasteboard.PasteboardType(rawValue: "logic.lineIndex")
}

// MARK: - LogicCanvasView

public class LogicCanvasView: NSView {

    public enum TextAlignment {
        case left, center, right
    }

    public struct Style {
        public var font = TextStyle(family: "San Francisco", size: 13).nsFont
        public var boldFont = TextStyle(family: "San Francisco", weight: NSFont.Weight.semibold, size: 13).nsFont
        public var textPadding = CGSize(width: 4, height: 3)
        public var textMargin = CGSize(width: 6, height: 6)
        public var textBackgroundRadius = CGSize(width: 2, height: 2)
        public var outlineWidth: CGFloat = 2.0
        public var textSpacing: CGFloat = 4.0
        public var lineSpacing: CGFloat = 6.0
        public var minimumLineHeight: CGFloat = 22.0
        public var textAlignment: TextAlignment = .left

        public init() {}
    }

    public static var dropdownCarets: Bool = false

    public enum Item: Equatable {
        case range(Range<Int>)
        case line(Int)
    }

    // MARK: Lifecycle

    public init() {
        super.init(frame: .zero)

        setUpViews()
        setUpConstraints()

        update()

        registerForDraggedTypes([.logicLineIndex])
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public var style: Style = Style() {
        didSet {
            update()
            invalidateIntrinsicContentSize()
        }
    }

    public var formattedContent: FormatterCommand<LogicElement> = .hardLine {
        didSet {
            update()
            invalidateIntrinsicContentSize()
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
    public var underlinedRange: Range<Int>? {
        didSet {
            update()
        }
    }
    public var onActivate: ((Int?) -> Void)?
    public var onActivateLine: ((Int) -> Void)?
    public var onPressTabKey: (() -> Void)?
    public var onPressShiftTabKey: (() -> Void)?
    public var onPressDeleteKey: (() -> Void)?
    public var onMoveLine: ((Int, Int) -> Void)?
    public var onFocus: (() -> Void)?
    public var onBlur: (() -> Void)?

    public var getElementDecoration: ((UUID) -> LogicElement.Decoration?)?

    public func forceUpdate() {
        update()
        invalidateIntrinsicContentSize()
    }

    // MARK: Styles

    private var selectedIndex: Int? {
        return selectedRange?.lowerBound
    }

    var selectedElement: LogicElement? {
        return selectedMeasuredElement?.element
    }

    var selectedMeasuredElement: LogicMeasuredElement? {
        guard let index = selectedIndex else { return nil }
        return measuredElements[index]
    }

    // MARK: Overrides

    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    public override var acceptsFirstResponder: Bool {
        return true
    }

    public override func becomeFirstResponder() -> Bool {
        onFocus?()
        return super.becomeFirstResponder()
    }

    public override func resignFirstResponder() -> Bool {
        onBlur?()
        return super.resignFirstResponder()
    }

    public func getElementRect(for index: Int) -> CGRect? {
        if index >= measuredElements.count { return nil }

        return measuredElements[index].backgroundRect
    }

    public var draggingThreshold: CGFloat = 2.0

    private var pressed = false
    private var pressedPoint = CGPoint.zero

    public override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if bounds.contains(point) {
            pressed = true
            pressedPoint = point
        }

        let clickedItem = item(at: point)

        // Activate on mouseDown so the UI feels more responsive
        switch clickedItem {
        case .none:
            onActivate?(nil)
        case .some(.range(let range)):
            onActivate?(range.lowerBound)
        case .some(.line(let index)):
            onActivateLine?(index)
        }
    }

    public override func mouseUp(with event: NSEvent) {
        pressed = false
    }

    public override func keyDown(with event: NSEvent) {
        Swift.print("LogicElementEditor kd", event.keyCode)

        switch Int(event.keyCode) {
        case 36: // Enter
            if let selectedIndex = selectedIndex {
                onActivate?(selectedIndex)
            } else if let selectedLine = selectedLine,
                let range = formattedContent.elementIndexRange(for: selectedLine) {
                onActivate?(range.lowerBound)
            } else {
                onActivate?(nil)
            }
        case 48: // Tab
            let shiftKey = event.modifierFlags.contains(NSEvent.ModifierFlags.shift)

            Swift.print("Tab \(shiftKey ? "shift" : "no shift")")

            if shiftKey {
                onPressShiftTabKey?()
            } else {
                onPressTabKey?()
            }
        case 51: // Delete
            onPressDeleteKey?()
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

        if let lineIndex = dragDestinationLineIndex {
            NSColor.selectedMenuItemColor.set()

            if lineIndex >= formattedContent.logicalRows.count {
                if let last = measuredElements.last {
                    let rect = NSRect(x: 0, y: last.backgroundRect.maxY, width: bounds.width, height: 1)
                    let path = NSBezierPath(rect: rect)
                    path.fill()
                }
            } else if let range = formattedContent.elementIndexRange(for: lineIndex),
                let first = measuredElements[range].first {
                let rect = NSRect(x: 0, y: first.backgroundRect.minY - 1, width: bounds.width, height: 1)
                let path = NSBezierPath(rect: rect)
                path.fill()
            }
        }

        if let selectedLine = selectedLine, let range = formattedContent.elementIndexRange(for: selectedLine) {
            let elements = measuredElements[range]
            if let first = elements.first, let last = elements.last {
                Colors.highlightedLine.set()
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
            let rect = measuredElements[range].map { $0.backgroundRect }.union
            NSColor.selectedMenuItemColor.setStroke()
            let path = NSBezierPath(
                roundedRect: rect.insetBy(dx: style.outlineWidth / 2, dy: style.outlineWidth / 2),
                xRadius: style.textBackgroundRadius.width,
                yRadius: style.textBackgroundRadius.height)
            path.lineWidth = style.outlineWidth
            path.stroke()
        } else {
            if let range = selectedRange {
                let clampedRange = range.clamped(to: measuredElements.startIndex..<measuredElements.endIndex)
                let rect = measuredElements[clampedRange].map { $0.backgroundRect }.union
                Colors.highlightedCode.set()
                NSBezierPath(
                    roundedRect: rect,
                    xRadius: style.textBackgroundRadius.width,
                    yRadius: style.textBackgroundRadius.height).fill()
            }
        }

        if let range = underlinedRange {
            let clampedRange = range.clamped(to: measuredElements.startIndex..<measuredElements.endIndex)

            NSColor.red.setStroke()

            measuredElements[clampedRange].forEach { element in
                let underlineRect = NSRect(
                    x: element.backgroundRect.minX,
                    y: element.backgroundRect.maxY - 2,
                    width: element.backgroundRect.width,
                    height: 2)

                let underlinePath = NSBezierPath(squiggleWithin: underlineRect, lineWidth: 1)

                underlinePath.stroke()
            }
        }

        measuredElements.enumerated().forEach { textIndex, measuredText in
            let selected = textIndex == self.selectedIndex
            let text = measuredText.element
            let rect = measuredText.attributedStringRect
            let backgroundRect = measuredText.backgroundRect
            let attributedString = measuredText.attributedString

            switch (text) {
            case .colorSwatch(_, let color):
                color.setFill()
                Colors.text.withAlphaComponent(0.1).setStroke()

                let radius: CGFloat = 4

                let insetRect = backgroundRect.insetBy(dx: style.textPadding.width, dy: style.textPadding.height)
                let backgroundBezier = NSBezierPath(roundedRect: insetRect, xRadius: radius, yRadius: radius)

                let outlineRect = insetRect.insetBy(dx: 0.5, dy: 0.5)
                let outlineBezier = NSBezierPath(roundedRect: outlineRect, xRadius: radius, yRadius: radius)

                backgroundBezier.fill()
                outlineBezier.stroke()
            case .text, .coloredText:
                attributedString.draw(at: rect.origin)
            case .title(_, let value),
                 .dropdown(_, let value, _):

                let dropdownStyle: LogicElement.DropdownStyle

                switch text {
                case .dropdown(_, _, let style):
                    dropdownStyle = style
                default:
                    dropdownStyle = .variable
                }

                let drawSelection = selected && outlinedRange == nil
                let color = drawSelection ? NSColor.selectedMenuItemColor : dropdownStyle.color

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
                    xRadius: style.textBackgroundRadius.width,
                    yRadius: style.textBackgroundRadius.height)
                backgroundPath.fill()

                NSShadow().set()

                if LogicCanvasView.dropdownCarets || value.isEmpty {
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

                switch self.cachedDecoration(for: text) {
                case .none:
                    break
                case .some(.color(let color)):
                    color.set()
                    let size: CGFloat = 13
                    let symbolRect = NSRect(x: backgroundRect.minX + 5, y: ceil(backgroundRect.midY - (size / 2)), width: size, height: size)
                    let symbolPath = NSBezierPath(roundedRect: symbolRect, xRadius: 2, yRadius: 2)
                    symbolPath.fill()
                case .some(.character(let attributedString, let textStyleColor)):
                    let size: CGFloat = 13
                    let symbolRect = NSRect(x: backgroundRect.minX + 5, y: ceil(backgroundRect.midY - (size / 2)), width: size, height: size)
                        .insetBy(dx: 0.5, dy: 0.5)
                    let symbolPath = NSBezierPath(roundedRect: symbolRect, xRadius: 2, yRadius: 2)
                    symbolPath.lineWidth = 1

                    if let strokeColor = textStyleColor.blended(withFraction: 0.5, of: textStyleColor.withAlphaComponent(0)) {
                        strokeColor.setStroke()
                        symbolPath.stroke()
                    }

                    if let fillColor = textStyleColor.blended(withFraction: 0.7, of: textStyleColor.withAlphaComponent(0)) {
                        fillColor.setFill()
                        symbolPath.fill()
                    }

                    let image = NSImage(size: attributedString.size(), flipped: false, drawingHandler: { rect in
                        attributedString.draw(at: rect.origin)
                        return true
                    })

                    let scaledSize = image.size.resized(within: symbolRect.size).size
                    let imageRect = NSRect(
                        origin: NSPoint(
                            x: symbolRect.origin.x + (symbolRect.width - scaledSize.width) / 2,
                            y: symbolRect.origin.y + (symbolRect.height - scaledSize.height) / 2),
                        size: scaledSize)

                    image.draw(in: imageRect)
                case .some(.label(let font, let text)):
                    let attributes: [NSAttributedString.Key: Any] = [
                        NSAttributedString.Key.foregroundColor: NSColor.white,
                        NSAttributedString.Key.font: font,
                    ]
                    let labelString = NSAttributedString(string: text, attributes: attributes)
                    let labelSize = labelString.size()
                    let labelWidth = labelSize.width + 6

                    let size: CGFloat = 13
                    let symbolRect = NSRect(
                        x: measuredText.attributedStringRect.maxX + 5,
                        y: ceil(backgroundRect.midY - (size / 2)),
                        width: labelWidth,
                        height: size
                    )
                    let symbolPath = NSBezierPath(roundedRect: symbolRect, xRadius: size / 2, yRadius: size / 2)
                    symbolPath.lineWidth = 0

                    (selected ? NSColor.white.withAlphaComponent(0.4) : Colors.editableText).setFill()
                    symbolPath.fill()

                    let labelOrigin = CGPoint(
                        x: symbolRect.origin.x + 3.0,
                        y: symbolRect.origin.y + (symbolRect.height - labelSize.height) / 2
                    )

                    labelString.draw(at: labelOrigin)
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
    private var _cachedElementDecorations: [UUID: LogicElement.Decoration?] = [:]

    private func cachedDecoration(for element: LogicElement) -> LogicElement.Decoration? {
        guard let id = element.syntaxNodeID else { return nil }

        if let decoration = _cachedElementDecorations[id] {
            return decoration
        }

        let decoration = self.getElementDecoration?(id)

        _cachedElementDecorations[id] = decoration

        return decoration
    }

    private var measuredElements: [LogicMeasuredElement] {
        if let cached = _cachedMeasuredElements {
            return cached
        }

        let getElementSize: (LogicElement, Int) -> CGSize = { [unowned self] element, index in
            return element.measured(
                selected: self.selectedIndex == index,
                origin: .zero,
                font: self.style.font,
                boldFont: self.style.boldFont,
                padding: self.style.textPadding,
                decoration: self.cachedDecoration(for: element)
                ).backgroundRect.size
        }

        let availableContentWidth = bounds.width - style.textMargin.width * 2

        let formattedElementLines = formattedContent.print(
            width: availableContentWidth,
            spaceWidth: style.textSpacing,
            indentWidth: 20,
            getElementSize: getElementSize
        )

        let yOffset = style.textMargin.height
        var formattedElementIndex = 0
        var measuredLine: [LogicMeasuredElement] = []

        formattedElementLines.enumerated().forEach { rowIndex, formattedElementLine in
            var xOffset: CGFloat = 0

            switch style.textAlignment {
            case .left:
                break
            // This setting is uncommon, so we avoid this calculation most of the time
            case .center, .right:
                guard let first = formattedElementLine.first, let last = formattedElementLine.last else { return }
                let lineWidth = last.x + last.width

                switch style.textAlignment {
                case .left:
                    break
                case .center:
                    xOffset = (availableContentWidth - lineWidth - first.x) / 2
                case .right:
                    xOffset = availableContentWidth - lineWidth - first.x
                }
            }

            formattedElementLine.forEach { formattedElement in
                let decoration: LogicElement.Decoration?
                if let id = formattedElement.element.syntaxNodeID {
                    decoration = self.getElementDecoration?(id)
                } else {
                    decoration = nil
                }

                let offset = CGPoint(
                    x: xOffset + formattedElement.x + style.textMargin.width,
                    y: yOffset + formattedElement.y)

                let measured = formattedElement.element.measured(
                    selected: self.selectedIndex == formattedElementIndex,
                    origin: offset,
                    font: style.font,
                    boldFont: style.boldFont,
                    padding: style.textPadding,
                    decoration: decoration
                )

                measuredLine.append(measured)

                formattedElementIndex += 1
            }
        }

        _cachedMeasuredElements = measuredLine

        return measuredLine
    }

    private var minHeight: CGFloat {
        let contentHeight = measuredElements.last?.backgroundRect.maxY ?? style.textMargin.height
        let minHeight = contentHeight + style.textMargin.height
        return minHeight
    }

    private var previousHeight: CGFloat = -1

    // MARK: Private

    private func setUpViews() {}

    private func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
    }

    private func update() {
        clearCache()
        needsDisplay = true
    }

    public override func layout() {
        super.layout()

        clearCache()

        let minHeight = self.minHeight
        if minHeight != previousHeight {
            previousHeight = minHeight
            invalidateIntrinsicContentSize()
        }
    }

    private func clearCache() {
        _cachedMeasuredElements = nil
        _cachedElementDecorations.removeAll(keepingCapacity: true)
    }

    // MARK: Drag and drop

    private var dragDestinationLineIndex: Int? {
        didSet {
            if oldValue != dragDestinationLineIndex {
                needsDisplay = true
            }
        }
    }

    public override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if abs(point.x - pressedPoint.x) < draggingThreshold && abs(point.y - pressedPoint.y) < draggingThreshold {
            return
        }

        let draggedItem = item(at: pressedPoint)
        let selectedLine: Int

        switch draggedItem {
        case .none, .some(.range):
            return
        case .some(.line(let index)):
            selectedLine = index
        }

        onActivate?(nil)

        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(selectedLine.description, forType: .logicLineIndex)

        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)

        guard let range = formattedContent.elementIndexRange(for: selectedLine) else { return }

        var rect = measuredElements[range].map { $0.backgroundRect }.union
        rect.origin.x = 0
        rect.size.width = bounds.width

        let pdf = dataWithPDF(inside: rect)
        guard let image = NSImage(data: pdf) else { return }

        draggingItem.setDraggingFrame(rect, contents: image)

        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }

    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let point = convert(sender.draggingLocation, from: nil)
        dragDestinationLineIndex = logicalLineIndex(at: point)

        return .move
    }

    public override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        let point = convert(sender.draggingLocation, from: nil)
        dragDestinationLineIndex = logicalLineIndex(at: point)

        return .move
    }

    public override func draggingExited(_ sender: NSDraggingInfo?) {
        dragDestinationLineIndex = nil
    }

    public override func draggingEnded(_ sender: NSDraggingInfo) {
        dragDestinationLineIndex = nil
    }

    public override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }

    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let sourceLineString = sender.draggingPasteboard.string(forType: .logicLineIndex),
            let sourceLineIndex = Int(sourceLineString),
            let destinationLineIndex = dragDestinationLineIndex else {
            return false
        }

        if destinationLineIndex == sourceLineIndex || destinationLineIndex - 1 == sourceLineIndex { return false }

        onMoveLine?(sourceLineIndex, destinationLineIndex > sourceLineIndex ? destinationLineIndex - 1 : destinationLineIndex)

        return true
    }
}

// MARK: - Coordinates

extension LogicCanvasView {
    private func item(at point: CGPoint) -> Item? {
        if let index = measuredElements.firstIndex(where: { $0.backgroundRect.contains(point) }) {
            return .range(index..<index + 1)
        }

        if let lineElementIndex = measuredElements.firstIndex(where: { measuredElement in
            return measuredElement.element.allowsLineSelection && point.y < measuredElement.backgroundRect.maxY
        }) {
            return .line(formattedContent.lineIndex(for: lineElementIndex))
        }

        return nil
    }

    private func logicalLineIndex(at point: CGPoint) -> Int {
        if let lineElementIndex = measuredElements.firstIndex(where: { measuredElement in
            measuredElement.element.allowsLineSelection && point.y < measuredElement.backgroundRect.midY
        }) {
            return formattedContent.lineIndex(for: lineElementIndex)
        }

        return formattedContent.logicalRows.count
    }
}

// MARK: - NSDraggingSource

extension LogicCanvasView: NSDraggingSource {
    public func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .move
    }
}
