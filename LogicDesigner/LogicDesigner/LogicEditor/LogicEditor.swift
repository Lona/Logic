import AppKit

// MARK: - LogicEditor

public class LogicEditor: NSView {

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

    public var formattedContent: Formatter<LogicEditorElement>.Command = .hardLine { didSet { update() } }
    public var selectedIndex: Int? { didSet { update() } }
    public var underlinedRange: NSRange?
    public var onActivateIndex: ((Int?) -> Void)?

    // MARK: Styles

    public static var textMargin = CGSize(width: 6, height: 6)
    public static var textPadding = CGSize(width: 4, height: 3)
    public static var textBackgroundRadius = CGSize(width: 2, height: 2)

    public static var underlineColor: NSColor = NSColor.systemBlue
    public static var underlineOffset: CGFloat = 2.0

    public static var textSpacing: CGFloat = 4.0
    public static var lineSpacing: CGFloat = 6.0
    public static var minimumLineHeight: CGFloat = 20.0

    public static var font = TextStyle(family: "San Francisco", size: 13).nsFont

    // MARK: Overrides

    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    public override var acceptsFirstResponder: Bool {
        return true
    }

    public func getBoundingRect(for index: Int) -> CGRect? {
        if index >= measuredLines.count { return nil }

        return flip(rect: measuredLines[index].backgroundRect)
    }

    public override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        let index = measuredLines.firstIndex(where: { $0.backgroundRect.contains(point) })

        onActivateIndex?(index)
    }

    public override func keyDown(with event: NSEvent) {
        Swift.print("LogicEditor kd", event.keyCode)

        switch Int(event.keyCode) {
        case 36: // Enter
            onActivateIndex?(selectedIndex)
        case 48: // Tab
            Swift.print("Tab")
        case 123: // Left
            Swift.print("Left arrow")
        case 124: // Right
            Swift.print("Right arrow")
        case 125: // Down
            Swift.print("Down arrow")
        case 126: // Up
            Swift.print("Up arrow")
        default:
            break
        }
    }

    public override var isFlipped: Bool {
        return true
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSGraphicsContext.current?.cgContext.setShouldSmoothFonts(false)

        let measuredLines = self.measuredLines

        measuredLines.enumerated().forEach { textIndex, measuredText in
            let selected = textIndex == self.selectedIndex
            let text = measuredText.text
            let rect = measuredText.attributedStringRect
            let backgroundRect = measuredText.backgroundRect
            let attributedString = measuredText.attributedString

            switch (text) {
            case .text, .coloredText:
                attributedString.draw(at: rect.origin)
            case .dropdown(_, let value, let color):
                let color = selected ? NSColor.selectedMenuItemColor : color

                let shadow = NSShadow()
                shadow.shadowBlurRadius = 1
                shadow.shadowOffset = NSSize(width: 0, height: -1)
                shadow.shadowColor = NSColor.black.withAlphaComponent(0.2)
                shadow.set()

                if selected {
                    color.setFill()
                } else {
                    NSColor.clear.setFill()
                    //                        NSColor.white.withAlphaComponent(0.2).setFill()
                    //                        color.highlight(withLevel: 0.7)?.setFill()
                }

                let backgroundPath = NSBezierPath(
                    roundedRect: backgroundRect,
                    xRadius: LogicEditor.textBackgroundRadius.width,
                    yRadius: LogicEditor.textBackgroundRadius.height)
                backgroundPath.fill()

                NSShadow().set()

                if selected {
                    NSColor.white.setFill()
                } else {
                    color.setFill()
                }
                let caretX = backgroundRect.maxX - (value.isEmpty ? 13 : 9)
                let caretCenter = CGPoint(x: caretX, y: backgroundRect.midY)
                let caretStart = CGPoint(x: caretX - 4, y: backgroundRect.midY)
                let caret = NSBezierPath(regularPolygonAt: caretCenter, startPoint: caretStart, sides: 3)
                caret.fill()

                if selected {
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

    private var measuredLines: [MeasuredEditorText] {
        let yOffset = LogicEditor.textMargin.height

        var measuredLine: [MeasuredEditorText] = []

        let formattedElementLines = formattedContent.print(
            width: bounds.width - LogicEditor.textMargin.width * 2,
            spaceWidth: LogicEditor.textSpacing,
            indentWidth: 20)

        var formattedElementIndex = 0

        formattedElementLines.enumerated().forEach { rowIndex, formattedElementLine in
            formattedElementLine.forEach { formattedElement in
                let measured = formattedElement.element.measured(
                    selected: self.selectedIndex == formattedElementIndex,
                    offset: CGPoint(
                        x: LogicEditor.textMargin.width + formattedElement.position,
                        y: yOffset + CGFloat(rowIndex) * LogicEditor.minimumLineHeight))

                measuredLine.append(measured)

                formattedElementIndex += 1
            }
        }

        return measuredLine
    }

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
        needsDisplay = true
    }
}
