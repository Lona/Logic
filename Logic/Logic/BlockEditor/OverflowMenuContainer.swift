import AppKit
import Foundation

// MARK: - OverflowMenuContainer

public class OverflowMenuContainer: NSBox {

    // MARK: Lifecycle

    public init(menuButtonOffset: NSSize = .init(width: 4, height: 4)) {
        self.menuButtonOffset = menuButtonOffset

        super.init(frame: .zero)

        setUpViews()
        setUpConstraints()

        update()

        addTrackingArea(trackingArea)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setUpViews()
        setUpConstraints()

        update()

        addTrackingArea(trackingArea)
    }

    deinit {
        removeTrackingArea(trackingArea)
    }

    // MARK: Public

    public var onPressButton: (() -> Void)? {
        get { return overflowMenuButton.onPressButton }
        set { overflowMenuButton.onPressButton = newValue }
    }

    public var menuButtonOffset: NSSize = .init(width: 4, height: 4) {
        didSet {
            if menuButtonOffset != oldValue {
                update()
            }
        }
    }

    public var innerContentView: NSView? {
        didSet {
            if innerContentView != oldValue {
                oldValue?.removeFromSuperview()
                overflowMenuButton.removeFromSuperview()

                if let innerContentView = innerContentView {
                    addSubview(innerContentView)
                    addSubview(overflowMenuButton)

                    innerContentView.translatesAutoresizingMaskIntoConstraints = false

                    NSLayoutConstraint.activate(
                        [
                            innerContentView.topAnchor.constraint(equalTo: topAnchor),
                            innerContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
                            innerContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
                            innerContentView.bottomAnchor.constraint(equalTo: bottomAnchor),
                            overflowMenuButtonTopConstraint,
                            overflowMenuButtonTrailingConstraint
                        ].compactMap({ $0 })
                    )

                    update()
                }
            }
        }
    }

    // MARK: Private

    private var overflowMenuButtonTopConstraint: NSLayoutConstraint?
    private var overflowMenuButtonTrailingConstraint: NSLayoutConstraint?

    private lazy var trackingArea = NSTrackingArea(
        rect: self.frame,
        options: [.mouseEnteredAndExited, .activeAlways, .mouseMoved, .inVisibleRect],
        owner: self)

    public let overflowMenuButton = OverflowMenuButton()

    private var hovered = false {
        didSet {
            if hovered != oldValue {
                update()
            }
        }
    }

    private func setUpViews() {
        boxType = .custom
        borderType = .noBorder
        contentViewMargins = .zero
    }

    private func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        overflowMenuButton.translatesAutoresizingMaskIntoConstraints = false

        overflowMenuButtonTopConstraint = overflowMenuButton.topAnchor.constraint(equalTo: topAnchor)
        overflowMenuButtonTrailingConstraint = overflowMenuButton.trailingAnchor.constraint(equalTo: trailingAnchor)
        overflowMenuButton.isHidden = true
    }

    private func update() {
        overflowMenuButton.isHidden = !hovered
        overflowMenuButtonTopConstraint?.constant = menuButtonOffset.height
        overflowMenuButtonTrailingConstraint?.constant = -menuButtonOffset.width
//        fillColor = hovered ? Colors.blockBackground : NSColor.clear
    }

    public override func mouseEntered(with event: NSEvent) {
        hovered = true
    }

    public override func mouseExited(with event: NSEvent) {
        hovered = false
    }
}
