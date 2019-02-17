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

  public convenience init(textValue: String) {
    self.init(Parameters(textValue: textValue))
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

  public var onChangeTextValue: ((String) -> Void)? {
    get { return parameters.onChangeTextValue }
    set { parameters.onChangeTextValue = newValue }
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
}

// MARK: - Parameters

extension ControlledSearchInput {
  public struct Parameters: Equatable {
    public var textValue: String
    public var onChangeTextValue: ((String) -> Void)?

    public init(textValue: String, onChangeTextValue: ((String) -> Void)? = nil) {
      self.textValue = textValue
      self.onChangeTextValue = onChangeTextValue
    }

    public init() {
      self.init(textValue: "")
    }

    public static func ==(lhs: Parameters, rhs: Parameters) -> Bool {
      return lhs.textValue == rhs.textValue
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

    public init(textValue: String, onChangeTextValue: ((String) -> Void)? = nil) {
      self.init(Parameters(textValue: textValue, onChangeTextValue: onChangeTextValue))
    }

    public init() {
      self.init(textValue: "")
    }
  }
}
