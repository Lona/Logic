import AppKit

extension NSBezierPath {
    convenience init(regularPolygonAt centre: NSPoint, startPoint startCorner: NSPoint, sides: Int) {
        self.init()

        let xDiff = abs(startCorner.x - centre.x)
        let yDiff = abs(startCorner.y - centre.y)
        let radius = sqrt(xDiff * xDiff + yDiff * yDiff)

        if xDiff <= 0 { return }

        // Calc angle at which centre & startCorner are, so we know at what angle to put the first point.
        var degrees = (xDiff == 0) ? 0 : ((yDiff == 0) ? 0.5 * CGFloat.pi : yDiff / xDiff)
        let stepSize = (2.0 * CGFloat.pi) / CGFloat(sides)

        // Draw first corner at start angle:
        var firstCorner = CGPoint.zero
        firstCorner.x = centre.x + radius * cos(degrees)
        firstCorner.y = centre.y + radius * sin(degrees)

        move(to: firstCorner)

        // Now draw following corners:
        for _ in 0..<sides {
            var currCorner = CGPoint.zero

            degrees += stepSize

            if degrees > (2.0 * CGFloat.pi) {
                degrees -= (2.0 * CGFloat.pi)
            }

            currCorner.x = centre.x + radius * cos( degrees )
            currCorner.y = centre.y + radius * sin( degrees )

            line(to: currCorner)
        }

        line(to: firstCorner)
    }

    static func makeTriangle(equilateralSide: CGFloat, center: CGPoint, rotation: CGFloat = 0) -> NSBezierPath {
        let altitude = CGFloat(sqrt(3.0) / 2.0 * equilateralSide)
        let heightToCenter = altitude / 3

        let path = NSBezierPath()

        path.move(to: CGPoint(x: center.x, y: center.y - heightToCenter * 2))
        path.line(to: CGPoint(x: center.x + equilateralSide / 2, y: center.y + heightToCenter))
        path.line(to: CGPoint(x: center.x - equilateralSide / 2, y: center.y + heightToCenter))
        path.close()

        return path
    }
}

public enum LogicEditorText {
    case unstyled(String)
    case colored(String, NSColor)
    case dropdown(String, NSColor)

    var value: String {
        switch self {
        case .unstyled(let value):
            return value
        case .colored(let value, _):
            return value
        case .dropdown(let value, _):
            return value
        }
    }

    var color: NSColor {
        switch self {
        case .unstyled:
            return NSColor.black
        case .colored(_, let color):
            return color
        case .dropdown(_, let color):
            return color
        }
    }
}

private struct MeasuredEditorText {
    var text: LogicEditorText
    var attributedString: NSAttributedString
    var attributedStringRect: CGRect
    var backgroundRect: CGRect
}

// MARK: - LogicEditor

public class LogicEditor: NSBox {

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

    public var body: [LogicEditorText] = [] { didSet { update() } }

    public var onClickText: ((Int) -> Void)?

    public var textMargin = CGSize(width: 4, height: 4)
    public var textPadding = CGSize(width: 4, height: 1)

    public var underlinedRange: NSRange?
    public var underlineColor: NSColor = NSColor.systemBlue
    public var underlineOffset: CGFloat = 2.0

    public var textSpacing: CGFloat = 6.0

    public var font = TextStyle(family: "monaco", size: 13).nsFont

    // MARK: Overrides

    public override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        let selectedIndex = measuredBody.firstIndex(where: { measuredText in
            return measuredText.backgroundRect.contains(point)
        })

        if let selectedIndex = selectedIndex {
            onClickText?(selectedIndex)
        }
    }

    public override var isFlipped: Bool {
        return true
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let measuredBody = self.measuredBody

        measuredBody.forEach { measuredText in
            let text = measuredText.text
            let rect = measuredText.attributedStringRect
            let backgroundRect = measuredText.backgroundRect
            let attributedString = measuredText.attributedString

            switch (text) {
            case .unstyled, .colored:
                attributedString.draw(at: rect.origin)
            case .dropdown(_, let color):
                color.highlight(withLevel: 0.7)?.setFill()
                let backgroundPath = NSBezierPath(roundedRect: backgroundRect, xRadius: 2, yRadius: 2)
                backgroundPath.fill()

                color.setFill()
                let caretCenter = CGPoint(x: backgroundRect.maxX - 10, y: backgroundRect.midY - 1)
                let caretStart = CGPoint(x: backgroundRect.maxX - 16, y: backgroundRect.midY - 1)
                let caret = NSBezierPath(regularPolygonAt: caretCenter, startPoint: caretStart, sides: 3)
                caret.fill()

                attributedString.draw(at: rect.origin)
            }
        }

        if let range = underlinedRange, range.location + range.length < body.count {
            let first = measuredBody[range.location]
            let last = measuredBody[range.location + range.length]

            underlineColor.setFill()
            
            let underlineRect = NSRect(
                x: first.backgroundRect.minX,
                y: first.backgroundRect.maxY + underlineOffset,
                width: last.backgroundRect.maxX - first.backgroundRect.minX,
                height: 2)

            underlineRect.fill()
        }
    }

    private var measuredBody: [MeasuredEditorText] {
        var measuredBody: [MeasuredEditorText] = []
        var xOffset = textMargin.width

        body.forEach { text in
            let attributedString = NSMutableAttributedString(string: text.value)
            let range = NSRange(location: 0, length: attributedString.length)

            switch (text) {
            case .unstyled:
                let attributes: [NSAttributedString.Key: Any] = [
                    NSAttributedString.Key.foregroundColor: NSColor.black,
                    NSAttributedString.Key.font: font
                ]
                attributedString.setAttributes(attributes, range: range)

                let attributedStringSize = attributedString.size()
                let rect = CGRect(origin: CGPoint(x: xOffset, y: textMargin.height), size: attributedStringSize)
                let backgroundRect = rect.insetBy(dx: -textPadding.width, dy: -textPadding.height)

                xOffset += backgroundRect.width + textSpacing

                let measured = MeasuredEditorText(
                    text: text,
                    attributedString: attributedString,
                    attributedStringRect: rect,
                    backgroundRect: backgroundRect)

                measuredBody.append(measured)
            case .colored(_, let color):
                let attributes: [NSAttributedString.Key: Any] = [
                    NSAttributedString.Key.foregroundColor: color,
                    NSAttributedString.Key.font: font
                ]
                attributedString.setAttributes(attributes, range: range)

                let attributedStringSize = attributedString.size()
                let rect = CGRect(origin: CGPoint(x: xOffset, y: textMargin.height), size: attributedStringSize)
                let backgroundRect = rect.insetBy(dx: -textPadding.width, dy: -textPadding.height)

                xOffset += backgroundRect.width + textSpacing

                let measured = MeasuredEditorText(
                    text: text,
                    attributedString: attributedString,
                    attributedStringRect: rect,
                    backgroundRect: backgroundRect)

                measuredBody.append(measured)
            case .dropdown(_, let color):
                let attributes: [NSAttributedString.Key: Any] = [
                    NSAttributedString.Key.foregroundColor: color,
                    NSAttributedString.Key.font: font
                ]
                attributedString.setAttributes(attributes, range: range)

                let attributedStringSize = attributedString.size()
                let rect = CGRect(origin: CGPoint(x: xOffset, y: textMargin.height), size: attributedStringSize)
                var backgroundRect = rect.insetBy(dx: -textPadding.width, dy: -textPadding.height)
                backgroundRect.size.width += 20

                xOffset += backgroundRect.width + textSpacing

                let measured = MeasuredEditorText(
                    text: text,
                    attributedString: attributedString,
                    attributedStringRect: rect,
                    backgroundRect: backgroundRect)

                measuredBody.append(measured)
            }
        }

        return measuredBody
    }

    // MARK: Private

    private func setUpViews() {
        boxType = .custom
        borderType = .noBorder
        contentViewMargins = .zero
    }

    private func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
    }

    private func update() {
        needsDisplay = true
    }
}
