import AppKit
import Foundation

// MARK: - ControlledSearchInput

public class ControlledSearchInput: NSBox {

  // MARK: Lifecycle

  public init(_ parameters: Parameters) {
    self.parameters = parameters

    super.init(frame: .zero)

    setUpViews()
    setUpConstraints()

    update()
  }

  public convenience init(textValue: String, placeholderText: String?) {
    self.init(Parameters(textValue: textValue, placeholderText: placeholderText))
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
  }

  // MARK: Public

  public var textValue: String {
    get { return parameters.textValue }
    set {
      if parameters.textValue != newValue {
        parameters.textValue = newValue
      }
    }
  }

  public var placeholderText: String? {
    get { return parameters.placeholderText }
    set {
      if parameters.placeholderText != newValue {
        parameters.placeholderText = newValue
      }
    }
  }

  public var onChangeTextValue: ((String) -> Void)? {
    get { return parameters.onChangeTextValue }
    set { parameters.onChangeTextValue = newValue }
  }

  public var onPressDownKey: (() -> Void)? {
    get { return parameters.onPressDownKey }
    set { parameters.onPressDownKey = newValue }
  }

  public var onPressUpKey: (() -> Void)? {
    get { return parameters.onPressUpKey }
    set { parameters.onPressUpKey = newValue }
  }

  public var onSubmit: (() -> Void)? {
    get { return parameters.onSubmit }
    set { parameters.onSubmit = newValue }
  }

  public var onPressEscape: (() -> Void)? {
    get { return parameters.onPressEscape }
    set { parameters.onPressEscape = newValue }
  }

  public var onPressTab: (() -> Void)? {
    get { return parameters.onPressTab }
    set { parameters.onPressTab = newValue }
  }

  public var onPressShiftTab: (() -> Void)? {
    get { return parameters.onPressShiftTab }
    set { parameters.onPressShiftTab = newValue }
  }

  public var onPressCommandUpKey: (() -> Void)? {
    get { return parameters.onPressCommandUpKey }
    set { parameters.onPressCommandUpKey = newValue }
  }

  public var onPressCommandDownKey: (() -> Void)? {
    get { return parameters.onPressCommandDownKey }
    set { parameters.onPressCommandDownKey = newValue }
  }

  public var parameters: Parameters {
    didSet {
      if parameters != oldValue {
        update()
      }
    }
  }

  // MARK: Private

  private var view1View = NSBox()
  private var textView = LNATextField(labelWithString: "")

  private var textViewTextStyle = TextStyles.defaultStyle

  private func setUpViews() {
    boxType = .custom
    borderType = .noBorder
    contentViewMargins = .zero
    view1View.boxType = .custom
    view1View.borderType = .lineBorder
    view1View.contentViewMargins = .zero
    textView.lineBreakMode = .byWordWrapping

    addSubview(view1View)
    view1View.addSubview(textView)

    view1View.borderColor = Colors.divider
    view1View.borderWidth = 1
  }

  private func setUpConstraints() {
    translatesAutoresizingMaskIntoConstraints = false
    view1View.translatesAutoresizingMaskIntoConstraints = false
    textView.translatesAutoresizingMaskIntoConstraints = false

    let view1ViewTopAnchorConstraint = view1View.topAnchor.constraint(equalTo: topAnchor)
    let view1ViewBottomAnchorConstraint = view1View.bottomAnchor.constraint(equalTo: bottomAnchor)
    let view1ViewLeadingAnchorConstraint = view1View.leadingAnchor.constraint(equalTo: leadingAnchor)
    let view1ViewTrailingAnchorConstraint = view1View.trailingAnchor.constraint(equalTo: trailingAnchor)
    let textViewTopAnchorConstraint = textView.topAnchor.constraint(equalTo: view1View.topAnchor, constant: 1)
    let textViewLeadingAnchorConstraint = textView
      .leadingAnchor
      .constraint(equalTo: view1View.leadingAnchor, constant: 1)
    let textViewTrailingAnchorConstraint = textView
      .trailingAnchor
      .constraint(lessThanOrEqualTo: view1View.trailingAnchor, constant: -1)

    NSLayoutConstraint.activate([
      view1ViewTopAnchorConstraint,
      view1ViewBottomAnchorConstraint,
      view1ViewLeadingAnchorConstraint,
      view1ViewTrailingAnchorConstraint,
      textViewTopAnchorConstraint,
      textViewLeadingAnchorConstraint,
      textViewTrailingAnchorConstraint
    ])
  }

  private func update() {
    textView.attributedStringValue = textViewTextStyle.apply(to: textValue)
  }

  private func handleOnChangeTextValue(_ arg0: String) {
    onChangeTextValue?(arg0)
  }

  private func handleOnPressDownKey() {
    onPressDownKey?()
  }

  private func handleOnPressUpKey() {
    onPressUpKey?()
  }

  private func handleOnSubmit() {
    onSubmit?()
  }

  private func handleOnPressEscape() {
    onPressEscape?()
  }

  private func handleOnPressTab() {
    onPressTab?()
  }

  private func handleOnPressShiftTab() {
    onPressShiftTab?()
  }

  private func handleOnPressCommandUpKey() {
    onPressCommandUpKey?()
  }

  private func handleOnPressCommandDownKey() {
    onPressCommandDownKey?()
  }
}

// MARK: - Parameters

extension ControlledSearchInput {
  public struct Parameters: Equatable {
    public var textValue: String
    public var placeholderText: String?
    public var onChangeTextValue: ((String) -> Void)?
    public var onPressDownKey: (() -> Void)?
    public var onPressUpKey: (() -> Void)?
    public var onSubmit: (() -> Void)?
    public var onPressEscape: (() -> Void)?
    public var onPressTab: (() -> Void)?
    public var onPressShiftTab: (() -> Void)?
    public var onPressCommandUpKey: (() -> Void)?
    public var onPressCommandDownKey: (() -> Void)?

    public init(
      textValue: String,
      placeholderText: String? = nil,
      onChangeTextValue: ((String) -> Void)? = nil,
      onPressDownKey: (() -> Void)? = nil,
      onPressUpKey: (() -> Void)? = nil,
      onSubmit: (() -> Void)? = nil,
      onPressEscape: (() -> Void)? = nil,
      onPressTab: (() -> Void)? = nil,
      onPressShiftTab: (() -> Void)? = nil,
      onPressCommandUpKey: (() -> Void)? = nil,
      onPressCommandDownKey: (() -> Void)? = nil)
    {
      self.textValue = textValue
      self.placeholderText = placeholderText
      self.onChangeTextValue = onChangeTextValue
      self.onPressDownKey = onPressDownKey
      self.onPressUpKey = onPressUpKey
      self.onSubmit = onSubmit
      self.onPressEscape = onPressEscape
      self.onPressTab = onPressTab
      self.onPressShiftTab = onPressShiftTab
      self.onPressCommandUpKey = onPressCommandUpKey
      self.onPressCommandDownKey = onPressCommandDownKey
    }

    public init() {
      self.init(textValue: "", placeholderText: nil)
    }

    public static func ==(lhs: Parameters, rhs: Parameters) -> Bool {
      return lhs.textValue == rhs.textValue && lhs.placeholderText == rhs.placeholderText
    }
  }
}

// MARK: - Model

extension ControlledSearchInput {
  public struct Model: LonaViewModel, Equatable {
    public var id: String?
    public var parameters: Parameters
    public var type: String {
      return "ControlledSearchInput"
    }

    public init(id: String? = nil, parameters: Parameters) {
      self.id = id
      self.parameters = parameters
    }

    public init(_ parameters: Parameters) {
      self.parameters = parameters
    }

    public init(
      textValue: String,
      placeholderText: String? = nil,
      onChangeTextValue: ((String) -> Void)? = nil,
      onPressDownKey: (() -> Void)? = nil,
      onPressUpKey: (() -> Void)? = nil,
      onSubmit: (() -> Void)? = nil,
      onPressEscape: (() -> Void)? = nil,
      onPressTab: (() -> Void)? = nil,
      onPressShiftTab: (() -> Void)? = nil,
      onPressCommandUpKey: (() -> Void)? = nil,
      onPressCommandDownKey: (() -> Void)? = nil)
    {
      self
        .init(
          Parameters(
            textValue: textValue,
            placeholderText: placeholderText,
            onChangeTextValue: onChangeTextValue,
            onPressDownKey: onPressDownKey,
            onPressUpKey: onPressUpKey,
            onSubmit: onSubmit,
            onPressEscape: onPressEscape,
            onPressTab: onPressTab,
            onPressShiftTab: onPressShiftTab,
            onPressCommandUpKey: onPressCommandUpKey,
            onPressCommandDownKey: onPressCommandDownKey))
    }

    public init() {
      self.init(textValue: "", placeholderText: nil)
    }
  }
}
