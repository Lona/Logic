import AppKit
import Foundation

public enum LogicEditorText {
    case unstyled(String)
    case colored(String, NSColor)

    var value: String {
        switch self {
        case .unstyled(let value):
            return value
        case .colored(let value, _):
            return value
        }
    }
}

private struct MeasuredEditorText {
    var text: LogicEditorText
    var rect: CGRect
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

    public var underlinedRange: NSRange?

    public var inlineTextPadding: CGFloat = 10.0

    // MARK: Overrides

    public override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        let selectedIndex = measuredBody.firstIndex(where: { measuredText in
            return measuredText.rect.contains(point)
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
            let rect = measuredText.rect
            let attributedString = NSMutableAttributedString(string: text.value)
            let range = NSRange(location: 0, length: attributedString.length)

            switch (text) {
            case .unstyled:
                let attributes: [NSAttributedString.Key: Any] = [
                    NSAttributedString.Key.foregroundColor: NSColor.black,
                    NSAttributedString.Key.font: NSFont.systemFont(ofSize: 14)
                ]

                attributedString.setAttributes(attributes, range: range)
                attributedString.draw(at: rect.origin)
            case .colored(_, let color):
                let attributes: [NSAttributedString.Key: Any] = [
                    NSAttributedString.Key.foregroundColor: color,
                    NSAttributedString.Key.font: NSFont.systemFont(ofSize: 14)
                ]

                attributedString.setAttributes(attributes, range: range)
                attributedString.draw(at: rect.origin)
            }
        }

        if let range = underlinedRange, range.location + range.length < body.count {
            let first = measuredBody[range.location]
            let last = measuredBody[range.location + range.length]

            NSColor.systemBlue.setFill()

            let underlineRect = NSRect(
                x: first.rect.minX,
                y: first.rect.maxY + 4,
                width: last.rect.maxX - first.rect.minX,
                height: 2)

            underlineRect.fill()
        }
    }

    private var measuredBody: [MeasuredEditorText] {
        var measuredBody: [MeasuredEditorText] = []
        var xOffset = textMargin.width

        body.forEach { text in
            let attributedString = NSMutableAttributedString(string: text.value)
            let attributedStringSize = attributedString.size()

            switch (text) {
            case .unstyled:
                let rect = CGRect(origin: CGPoint(x: xOffset, y: textMargin.height), size: attributedStringSize)
                xOffset += rect.width + inlineTextPadding
                measuredBody.append(MeasuredEditorText(text: text, rect: rect))
            case .colored:
                let rect = CGRect(origin: CGPoint(x: xOffset, y: textMargin.height), size: attributedStringSize)
                xOffset += rect.width + inlineTextPadding
                measuredBody.append(MeasuredEditorText(text: text, rect: rect))
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
