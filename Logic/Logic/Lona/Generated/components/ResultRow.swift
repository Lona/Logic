import AppKit
import Foundation

// MARK: - ResultRow

public class ResultRow: NSBox {

  // MARK: Lifecycle

  public init(_ parameters: Parameters) {
    self.parameters = parameters

    super.init(frame: .zero)

    setUpViews()
    setUpConstraints()

    update()
  }

  public convenience init(titleText: String, selected: Bool, disabled: Bool, badgeText: String?) {
    self.init(Parameters(titleText: titleText, selected: selected, disabled: disabled, badgeText: badgeText))
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

  public var selected: Bool {
    get { return parameters.selected }
    set {
      if parameters.selected != newValue {
        parameters.selected = newValue
      }
    }
  }

  public var disabled: Bool {
    get { return parameters.disabled }
    set {
      if parameters.disabled != newValue {
        parameters.disabled = newValue
      }
    }
  }

  public var badgeText: String? {
    get { return parameters.badgeText }
    set {
      if parameters.badgeText != newValue {
        parameters.badgeText = newValue
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

  private var textView = LNATextField(labelWithString: "")
  private var badgeViewView = NSBox()
  private var badgeTextView = LNATextField(labelWithString: "")

  private var textViewTextStyle = TextStyles.row
  private var badgeTextViewTextStyle = TextStyles.sectionHeader

  private var textViewTrailingAnchorTrailingAnchorConstraint: NSLayoutConstraint?
  private var badgeViewViewHeightAnchorParentConstraint: NSLayoutConstraint?
  private var badgeViewViewTrailingAnchorTrailingAnchorConstraint: NSLayoutConstraint?
  private var badgeViewViewLeadingAnchorTextViewTrailingAnchorConstraint: NSLayoutConstraint?
  private var badgeViewViewCenterYAnchorCenterYAnchorConstraint: NSLayoutConstraint?
  private var badgeViewViewHeightAnchorConstraint: NSLayoutConstraint?
  private var badgeTextViewLeadingAnchorBadgeViewViewLeadingAnchorConstraint: NSLayoutConstraint?
  private var badgeTextViewTrailingAnchorBadgeViewViewTrailingAnchorConstraint: NSLayoutConstraint?
  private var badgeTextViewTopAnchorBadgeViewViewTopAnchorConstraint: NSLayoutConstraint?
  private var badgeTextViewBottomAnchorBadgeViewViewBottomAnchorConstraint: NSLayoutConstraint?

  private func setUpViews() {
    boxType = .custom
    borderType = .noBorder
    contentViewMargins = .zero
    textView.lineBreakMode = .byWordWrapping
    badgeViewView.boxType = .custom
    badgeViewView.borderType = .noBorder
    badgeViewView.contentViewMargins = .zero
    badgeTextView.lineBreakMode = .byWordWrapping

    addSubview(textView)
    addSubview(badgeViewView)
    badgeViewView.addSubview(badgeTextView)

    badgeViewView.cornerRadius = 4
  }

  private func setUpConstraints() {
    translatesAutoresizingMaskIntoConstraints = false
    textView.translatesAutoresizingMaskIntoConstraints = false
    badgeViewView.translatesAutoresizingMaskIntoConstraints = false
    badgeTextView.translatesAutoresizingMaskIntoConstraints = false

    let textViewHeightAnchorParentConstraint = textView
      .heightAnchor
      .constraint(lessThanOrEqualTo: heightAnchor, constant: -8)
    let textViewLeadingAnchorConstraint = textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12)
    let textViewTopAnchorConstraint = textView.topAnchor.constraint(equalTo: topAnchor, constant: 4)
    let textViewCenterYAnchorConstraint = textView.centerYAnchor.constraint(equalTo: centerYAnchor)
    let textViewBottomAnchorConstraint = textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
    let textViewTrailingAnchorTrailingAnchorConstraint = textView
      .trailingAnchor
      .constraint(equalTo: trailingAnchor, constant: -12)
    let badgeViewViewHeightAnchorParentConstraint = badgeViewView
      .heightAnchor
      .constraint(lessThanOrEqualTo: heightAnchor, constant: -8)
    let badgeViewViewTrailingAnchorTrailingAnchorConstraint = badgeViewView
      .trailingAnchor
      .constraint(equalTo: trailingAnchor, constant: -12)
    let badgeViewViewLeadingAnchorTextViewTrailingAnchorConstraint = badgeViewView
      .leadingAnchor
      .constraint(equalTo: textView.trailingAnchor)
    let badgeViewViewCenterYAnchorCenterYAnchorConstraint = badgeViewView
      .centerYAnchor
      .constraint(equalTo: centerYAnchor)
    let badgeViewViewHeightAnchorConstraint = badgeViewView.heightAnchor.constraint(equalToConstant: 14)
    let badgeTextViewLeadingAnchorBadgeViewViewLeadingAnchorConstraint = badgeTextView
      .leadingAnchor
      .constraint(equalTo: badgeViewView.leadingAnchor, constant: 4)
    let badgeTextViewTrailingAnchorBadgeViewViewTrailingAnchorConstraint = badgeTextView
      .trailingAnchor
      .constraint(equalTo: badgeViewView.trailingAnchor, constant: -4)
    let badgeTextViewTopAnchorBadgeViewViewTopAnchorConstraint = badgeTextView
      .topAnchor
      .constraint(equalTo: badgeViewView.topAnchor, constant: 1)
    let badgeTextViewBottomAnchorBadgeViewViewBottomAnchorConstraint = badgeTextView
      .bottomAnchor
      .constraint(equalTo: badgeViewView.bottomAnchor)

    textViewHeightAnchorParentConstraint.priority = NSLayoutConstraint.Priority.defaultLow
    badgeViewViewHeightAnchorParentConstraint.priority = NSLayoutConstraint.Priority.defaultLow

    self.textViewTrailingAnchorTrailingAnchorConstraint = textViewTrailingAnchorTrailingAnchorConstraint
    self.badgeViewViewHeightAnchorParentConstraint = badgeViewViewHeightAnchorParentConstraint
    self.badgeViewViewTrailingAnchorTrailingAnchorConstraint = badgeViewViewTrailingAnchorTrailingAnchorConstraint
    self.badgeViewViewLeadingAnchorTextViewTrailingAnchorConstraint =
      badgeViewViewLeadingAnchorTextViewTrailingAnchorConstraint
    self.badgeViewViewCenterYAnchorCenterYAnchorConstraint = badgeViewViewCenterYAnchorCenterYAnchorConstraint
    self.badgeViewViewHeightAnchorConstraint = badgeViewViewHeightAnchorConstraint
    self.badgeTextViewLeadingAnchorBadgeViewViewLeadingAnchorConstraint =
      badgeTextViewLeadingAnchorBadgeViewViewLeadingAnchorConstraint
    self.badgeTextViewTrailingAnchorBadgeViewViewTrailingAnchorConstraint =
      badgeTextViewTrailingAnchorBadgeViewViewTrailingAnchorConstraint
    self.badgeTextViewTopAnchorBadgeViewViewTopAnchorConstraint = badgeTextViewTopAnchorBadgeViewViewTopAnchorConstraint
    self.badgeTextViewBottomAnchorBadgeViewViewBottomAnchorConstraint =
      badgeTextViewBottomAnchorBadgeViewViewBottomAnchorConstraint

    NSLayoutConstraint.activate(
      [
        textViewHeightAnchorParentConstraint,
        textViewLeadingAnchorConstraint,
        textViewTopAnchorConstraint,
        textViewCenterYAnchorConstraint,
        textViewBottomAnchorConstraint
      ] +
        conditionalConstraints(badgeViewViewIsHidden: badgeViewView.isHidden))
  }

  private func conditionalConstraints(badgeViewViewIsHidden: Bool) -> [NSLayoutConstraint] {
    var constraints: [NSLayoutConstraint?]

    switch (badgeViewViewIsHidden) {
      case (true):
        constraints = [textViewTrailingAnchorTrailingAnchorConstraint]
      case (false):
        constraints = [
          badgeViewViewHeightAnchorParentConstraint,
          badgeViewViewTrailingAnchorTrailingAnchorConstraint,
          badgeViewViewLeadingAnchorTextViewTrailingAnchorConstraint,
          badgeViewViewCenterYAnchorCenterYAnchorConstraint,
          badgeViewViewHeightAnchorConstraint,
          badgeTextViewLeadingAnchorBadgeViewViewLeadingAnchorConstraint,
          badgeTextViewTrailingAnchorBadgeViewViewTrailingAnchorConstraint,
          badgeTextViewTopAnchorBadgeViewViewTopAnchorConstraint,
          badgeTextViewBottomAnchorBadgeViewViewBottomAnchorConstraint
        ]
    }

    return constraints.compactMap({ $0 })
  }

  private func update() {
    let badgeViewViewIsHidden = badgeViewView.isHidden

    badgeTextView.attributedStringValue = badgeTextViewTextStyle.apply(to: "Badge")
    badgeTextViewTextStyle = TextStyles.sectionHeader
    badgeTextView.attributedStringValue = badgeTextViewTextStyle.apply(to: badgeTextView.attributedStringValue)
    badgeViewView.isHidden = !false
    badgeViewView.fillColor = Colors.raisedBackground
    textViewTextStyle = TextStyles.row
    textView.attributedStringValue = textViewTextStyle.apply(to: textView.attributedStringValue)
    textView.attributedStringValue = textViewTextStyle.apply(to: titleText)
    if selected {
      textViewTextStyle = TextStyles.rowInverse
      textView.attributedStringValue = textViewTextStyle.apply(to: textView.attributedStringValue)
      badgeTextViewTextStyle = TextStyles.sectionHeaderInverse
      badgeTextView.attributedStringValue = badgeTextViewTextStyle.apply(to: badgeTextView.attributedStringValue)
      badgeViewView.fillColor = Colors.transparent
    }
    if disabled {
      textViewTextStyle = TextStyles.rowDisabled
      textView.attributedStringValue = textViewTextStyle.apply(to: textView.attributedStringValue)
      badgeTextViewTextStyle = TextStyles.sectionHeaderDisabled
      badgeTextView.attributedStringValue = badgeTextViewTextStyle.apply(to: badgeTextView.attributedStringValue)
      badgeViewView.fillColor = Colors.transparent
    }
    if let badgeText = badgeText {
      badgeViewView.isHidden = !true
      badgeTextView.attributedStringValue = badgeTextViewTextStyle.apply(to: badgeText)
    }

    if badgeViewView.isHidden != badgeViewViewIsHidden {
      NSLayoutConstraint.deactivate(conditionalConstraints(badgeViewViewIsHidden: badgeViewViewIsHidden))
      NSLayoutConstraint.activate(conditionalConstraints(badgeViewViewIsHidden: badgeViewView.isHidden))
    }
  }
}

// MARK: - Parameters

extension ResultRow {
  public struct Parameters: Equatable {
    public var titleText: String
    public var selected: Bool
    public var disabled: Bool
    public var badgeText: String?

    public init(titleText: String, selected: Bool, disabled: Bool, badgeText: String? = nil) {
      self.titleText = titleText
      self.selected = selected
      self.disabled = disabled
      self.badgeText = badgeText
    }

    public init() {
      self.init(titleText: "", selected: false, disabled: false, badgeText: nil)
    }

    public static func ==(lhs: Parameters, rhs: Parameters) -> Bool {
      return lhs.titleText == rhs.titleText &&
        lhs.selected == rhs.selected && lhs.disabled == rhs.disabled && lhs.badgeText == rhs.badgeText
    }
  }
}

// MARK: - Model

extension ResultRow {
  public struct Model: LonaViewModel, Equatable {
    public var id: String?
    public var parameters: Parameters
    public var type: String {
      return "ResultRow"
    }

    public init(id: String? = nil, parameters: Parameters) {
      self.id = id
      self.parameters = parameters
    }

    public init(_ parameters: Parameters) {
      self.parameters = parameters
    }

    public init(titleText: String, selected: Bool, disabled: Bool, badgeText: String? = nil) {
      self.init(Parameters(titleText: titleText, selected: selected, disabled: disabled, badgeText: badgeText))
    }

    public init() {
      self.init(titleText: "", selected: false, disabled: false, badgeText: nil)
    }
  }
}
