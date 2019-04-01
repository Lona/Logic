import AppKit
import Foundation

// MARK: - ResultSectionHeader

public class ResultSectionHeader: NSBox {

  // MARK: Lifecycle

  public init(_ parameters: Parameters) {
    self.parameters = parameters

    super.init(frame: .zero)

    setUpViews()
    setUpConstraints()

    update()
  }

  public convenience init(titleText: String) {
    self.init(Parameters(titleText: titleText))
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

  public var titleText: String {
    get { return parameters.titleText }
    set {
      if parameters.titleText != newValue {
        parameters.titleText = newValue
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

  private var view1View = NSBox()
  private var textView = LNATextField(labelWithString: "")

  private var textViewTextStyle = TextStyles.sectionHeader

  private func setUpViews() {
    boxType = .custom
    borderType = .noBorder
    contentViewMargins = .zero
    view1View.boxType = .custom
    view1View.borderType = .noBorder
    view1View.contentViewMargins = .zero
    textView.lineBreakMode = .byWordWrapping

    addSubview(view1View)
    view1View.addSubview(textView)

    view1View.fillColor = Colors.divider
    textViewTextStyle = TextStyles.sectionHeader
    textView.attributedStringValue = textViewTextStyle.apply(to: textView.attributedStringValue)
  }

  private func setUpConstraints() {
    translatesAutoresizingMaskIntoConstraints = false
    view1View.translatesAutoresizingMaskIntoConstraints = false
    textView.translatesAutoresizingMaskIntoConstraints = false

    let view1ViewTopAnchorConstraint = view1View.topAnchor.constraint(equalTo: topAnchor)
    let view1ViewBottomAnchorConstraint = view1View.bottomAnchor.constraint(equalTo: bottomAnchor)
    let view1ViewLeadingAnchorConstraint = view1View.leadingAnchor.constraint(equalTo: leadingAnchor)
    let view1ViewTrailingAnchorConstraint = view1View.trailingAnchor.constraint(equalTo: trailingAnchor)
    let textViewTopAnchorConstraint = textView.topAnchor.constraint(equalTo: view1View.topAnchor, constant: 2)
    let textViewBottomAnchorConstraint = textView.bottomAnchor.constraint(equalTo: view1View.bottomAnchor)
    let textViewLeadingAnchorConstraint = textView
      .leadingAnchor
      .constraint(equalTo: view1View.leadingAnchor, constant: 12)
    let textViewTrailingAnchorConstraint = textView
      .trailingAnchor
      .constraint(lessThanOrEqualTo: view1View.trailingAnchor, constant: -12)

    NSLayoutConstraint.activate([
      view1ViewTopAnchorConstraint,
      view1ViewBottomAnchorConstraint,
      view1ViewLeadingAnchorConstraint,
      view1ViewTrailingAnchorConstraint,
      textViewTopAnchorConstraint,
      textViewBottomAnchorConstraint,
      textViewLeadingAnchorConstraint,
      textViewTrailingAnchorConstraint
    ])
  }

  private func update() {
    textView.attributedStringValue = textViewTextStyle.apply(to: titleText)
  }
}

// MARK: - Parameters

extension ResultSectionHeader {
  public struct Parameters: Equatable {
    public var titleText: String

    public init(titleText: String) {
      self.titleText = titleText
    }

    public init() {
      self.init(titleText: "")
    }

    public static func ==(lhs: Parameters, rhs: Parameters) -> Bool {
      return lhs.titleText == rhs.titleText
    }
  }
}

// MARK: - Model

extension ResultSectionHeader {
  public struct Model: LonaViewModel, Equatable {
    public var id: String?
    public var parameters: Parameters
    public var type: String {
      return "ResultSectionHeader"
    }

    public init(id: String? = nil, parameters: Parameters) {
      self.id = id
      self.parameters = parameters
    }

    public init(_ parameters: Parameters) {
      self.parameters = parameters
    }

    public init(titleText: String) {
      self.init(Parameters(titleText: titleText))
    }

    public init() {
      self.init(titleText: "")
    }
  }
}
