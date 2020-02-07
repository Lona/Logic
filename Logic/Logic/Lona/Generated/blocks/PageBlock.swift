// Generated by Lona Compiler 0.9.1

import AppKit
import Foundation

// MARK: - PageBlock

public class PageBlock: NSBox {

  // MARK: Lifecycle

  public init(_ parameters: Parameters) {
    self.parameters = parameters

    super.init(frame: .zero)

    setUpViews()
    setUpConstraints()

    update()

    addTrackingArea(trackingArea)
  }

  public convenience init(titleText: String, linkTarget: String) {
    self.init(Parameters(titleText: titleText, linkTarget: linkTarget))
  }

  public convenience init() {
    self.init(Parameters())
  }

  public required init?(coder aDecoder: NSCoder) {
    self.parameters = Parameters()

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

  public var onPressBlock: (() -> Void)? {
    get { return parameters.onPressBlock }
    set { parameters.onPressBlock = newValue }
  }

  public var titleText: String {
    get { return parameters.titleText }
    set {
      if parameters.titleText != newValue {
        parameters.titleText = newValue
      }
    }
  }

  public var linkTarget: String {
    get { return parameters.linkTarget }
    set {
      if parameters.linkTarget != newValue {
        parameters.linkTarget = newValue
      }
    }
  }

  public var parameters: Parameters {
    didSet {
      if parameters != oldValue {
        update()
      }
    }
  }

  // MARK: Private

  private lazy var trackingArea = NSTrackingArea(
    rect: self.frame,
    options: [.mouseEnteredAndExited, .activeAlways, .mouseMoved, .inVisibleRect],
    owner: self)

  private var titleView = LNATextField(labelWithString: "")

  private var titleViewTextStyle = TextStyles.pageLink

  private var hovered = false
  private var pressed = false
  private var onPress: (() -> Void)?

  private func setUpViews() {
    boxType = .custom
    borderType = .noBorder
    contentViewMargins = .zero
    titleView.lineBreakMode = .byWordWrapping

    addSubview(titleView)

    fillColor = Colors.blockBackground
    titleViewTextStyle = TextStyles.pageLink
    titleView.attributedStringValue = titleViewTextStyle.apply(to: titleView.attributedStringValue)
  }

  private func setUpConstraints() {
    translatesAutoresizingMaskIntoConstraints = false
    titleView.translatesAutoresizingMaskIntoConstraints = false

    let titleViewTopAnchorConstraint = titleView.topAnchor.constraint(equalTo: topAnchor, constant: 8)
    let titleViewBottomAnchorConstraint = titleView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
    let titleViewLeadingAnchorConstraint = titleView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
    let titleViewTrailingAnchorConstraint = titleView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)

    NSLayoutConstraint.activate([
      titleViewTopAnchorConstraint,
      titleViewBottomAnchorConstraint,
      titleViewLeadingAnchorConstraint,
      titleViewTrailingAnchorConstraint
    ])
  }

  private func update() {
    alphaValue = 1
    onPress = handleOnPressBlock
    titleView.attributedStringValue = titleViewTextStyle.apply(to: titleText)
    if hovered {
      alphaValue = 0.75
    }
  }

  private func handleOnPressBlock() {
    onPressBlock?()
  }

  private func updateHoverState(with event: NSEvent) {
    let hovered = bounds.contains(convert(event.locationInWindow, from: nil))
    if hovered != self.hovered {
      self.hovered = hovered

      update()
    }
  }

  public override func mouseEntered(with event: NSEvent) {
    updateHoverState(with: event)
  }

  public override func mouseMoved(with event: NSEvent) {
    updateHoverState(with: event)
  }

  public override func mouseDragged(with event: NSEvent) {
    updateHoverState(with: event)
  }

  public override func mouseExited(with event: NSEvent) {
    updateHoverState(with: event)
  }

  public override func mouseDown(with event: NSEvent) {
    let pressed = bounds.contains(convert(event.locationInWindow, from: nil))
    if pressed != self.pressed {
      self.pressed = pressed

      update()
    }
  }

  public override func mouseUp(with event: NSEvent) {
    let clicked = pressed && bounds.contains(convert(event.locationInWindow, from: nil))

    if pressed {
      pressed = false

      update()
    }

    if clicked {
      onPress?()
    }
  }
}

// MARK: - Parameters

extension PageBlock {
  public struct Parameters: Equatable {
    public var titleText: String
    public var linkTarget: String
    public var onPressBlock: (() -> Void)?

    public init(titleText: String, linkTarget: String, onPressBlock: (() -> Void)? = nil) {
      self.titleText = titleText
      self.linkTarget = linkTarget
      self.onPressBlock = onPressBlock
    }

    public init() {
      self.init(titleText: "", linkTarget: "")
    }

    public static func ==(lhs: Parameters, rhs: Parameters) -> Bool {
      return lhs.titleText == rhs.titleText && lhs.linkTarget == rhs.linkTarget
    }
  }
}

// MARK: - Model

extension PageBlock {
  public struct Model: LonaViewModel, Equatable {
    public var id: String?
    public var parameters: Parameters
    public var type: String {
      return "PageBlock"
    }

    public init(id: String? = nil, parameters: Parameters) {
      self.id = id
      self.parameters = parameters
    }

    public init(_ parameters: Parameters) {
      self.parameters = parameters
    }

    public init(titleText: String, linkTarget: String, onPressBlock: (() -> Void)? = nil) {
      self.init(Parameters(titleText: titleText, linkTarget: linkTarget, onPressBlock: onPressBlock))
    }

    public init() {
      self.init(titleText: "", linkTarget: "")
    }
  }
}
