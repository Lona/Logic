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

  public convenience init(
    titleText: String,
    subtitleText: String?,
    selected: Bool,
    disabled: Bool,
    badgeText: String?)
  {
    self
      .init(
        Parameters(
          titleText: titleText,
          subtitleText: subtitleText,
          selected: selected,
          disabled: disabled,
          badgeText: badgeText))
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

  public var subtitleText: String? {
    get { return parameters.subtitleText }
    set {
      if parameters.subtitleText != newValue {
        parameters.subtitleText = newValue
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

  private var contentViewView = NSBox()
  private var textView = LNATextField(labelWithString: "")
  private var subtitleTextView = LNATextField(labelWithString: "")
  private var badgeViewView = NSBox()
  private var badgeTextView = LNATextField(labelWithString: "")

  private var textViewTextStyle = TextStyles.row
  private var subtitleTextViewTextStyle = TextStyles.sectionHeader
  private var badgeTextViewTextStyle = TextStyles.sectionHeader

  private var contentViewViewTrailingAnchorTrailingAnchorConstraint: NSLayoutConstraint?
  private var textViewBottomAnchorContentViewViewBottomAnchorConstraint: NSLayoutConstraint?
  private var subtitleTextViewBottomAnchorContentViewViewBottomAnchorConstraint: NSLayoutConstraint?
  private var subtitleTextViewTopAnchorTextViewBottomAnchorConstraint: NSLayoutConstraint?
  private var subtitleTextViewLeadingAnchorContentViewViewLeadingAnchorConstraint: NSLayoutConstraint?
  private var subtitleTextViewTrailingAnchorContentViewViewTrailingAnchorConstraint: NSLayoutConstraint?
  private var badgeViewViewHeightAnchorParentConstraint: NSLayoutConstraint?
  private var badgeViewViewTrailingAnchorTrailingAnchorConstraint: NSLayoutConstraint?
  private var badgeViewViewLeadingAnchorContentViewViewTrailingAnchorConstraint: NSLayoutConstraint?
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
    contentViewView.boxType = .custom
    contentViewView.borderType = .noBorder
    contentViewView.contentViewMargins = .zero
    badgeViewView.boxType = .custom
    badgeViewView.borderType = .noBorder
    badgeViewView.contentViewMargins = .zero
    textView.lineBreakMode = .byWordWrapping
    subtitleTextView.lineBreakMode = .byWordWrapping
    badgeTextView.lineBreakMode = .byWordWrapping

    addSubview(contentViewView)
    addSubview(badgeViewView)
    contentViewView.addSubview(textView)
    contentViewView.addSubview(subtitleTextView)
    badgeViewView.addSubview(badgeTextView)

    badgeViewView.cornerRadius = 4
  }

  private func setUpConstraints() {
    translatesAutoresizingMaskIntoConstraints = false
    contentViewView.translatesAutoresizingMaskIntoConstraints = false
    badgeViewView.translatesAutoresizingMaskIntoConstraints = false
    textView.translatesAutoresizingMaskIntoConstraints = false
    subtitleTextView.translatesAutoresizingMaskIntoConstraints = false
    badgeTextView.translatesAutoresizingMaskIntoConstraints = false

    let contentViewViewHeightAnchorParentConstraint = contentViewView
      .heightAnchor
      .constraint(lessThanOrEqualTo: heightAnchor, constant: -8)
    let contentViewViewLeadingAnchorConstraint = contentViewView
      .leadingAnchor
      .constraint(equalTo: leadingAnchor, constant: 12)
    let contentViewViewTopAnchorConstraint = contentViewView.topAnchor.constraint(equalTo: topAnchor, constant: 4)
    let contentViewViewCenterYAnchorConstraint = contentViewView.centerYAnchor.constraint(equalTo: centerYAnchor)
    let contentViewViewBottomAnchorConstraint = contentViewView
      .bottomAnchor
      .constraint(equalTo: bottomAnchor, constant: -4)
    let textViewTopAnchorConstraint = textView.topAnchor.constraint(equalTo: contentViewView.topAnchor)
    let textViewLeadingAnchorConstraint = textView.leadingAnchor.constraint(equalTo: contentViewView.leadingAnchor)
    let textViewTrailingAnchorConstraint = textView
      .trailingAnchor
      .constraint(lessThanOrEqualTo: contentViewView.trailingAnchor)
    let contentViewViewTrailingAnchorTrailingAnchorConstraint = contentViewView
      .trailingAnchor
      .constraint(equalTo: trailingAnchor, constant: -12)
    let textViewBottomAnchorContentViewViewBottomAnchorConstraint = textView
      .bottomAnchor
      .constraint(equalTo: contentViewView.bottomAnchor)
    let subtitleTextViewBottomAnchorContentViewViewBottomAnchorConstraint = subtitleTextView
      .bottomAnchor
      .constraint(equalTo: contentViewView.bottomAnchor)
    let subtitleTextViewTopAnchorTextViewBottomAnchorConstraint = subtitleTextView
      .topAnchor
      .constraint(equalTo: textView.bottomAnchor)
    let subtitleTextViewLeadingAnchorContentViewViewLeadingAnchorConstraint = subtitleTextView
      .leadingAnchor
      .constraint(equalTo: contentViewView.leadingAnchor)
    let subtitleTextViewTrailingAnchorContentViewViewTrailingAnchorConstraint = subtitleTextView
      .trailingAnchor
      .constraint(lessThanOrEqualTo: contentViewView.trailingAnchor)
    let badgeViewViewHeightAnchorParentConstraint = badgeViewView
      .heightAnchor
      .constraint(lessThanOrEqualTo: heightAnchor, constant: -8)
    let badgeViewViewTrailingAnchorTrailingAnchorConstraint = badgeViewView
      .trailingAnchor
      .constraint(equalTo: trailingAnchor, constant: -12)
    let badgeViewViewLeadingAnchorContentViewViewTrailingAnchorConstraint = badgeViewView
      .leadingAnchor
      .constraint(equalTo: contentViewView.trailingAnchor)
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

    contentViewViewHeightAnchorParentConstraint.priority = NSLayoutConstraint.Priority.defaultLow
    badgeViewViewHeightAnchorParentConstraint.priority = NSLayoutConstraint.Priority.defaultLow

    self.contentViewViewTrailingAnchorTrailingAnchorConstraint = contentViewViewTrailingAnchorTrailingAnchorConstraint
    self.textViewBottomAnchorContentViewViewBottomAnchorConstraint =
      textViewBottomAnchorContentViewViewBottomAnchorConstraint
    self.subtitleTextViewBottomAnchorContentViewViewBottomAnchorConstraint =
      subtitleTextViewBottomAnchorContentViewViewBottomAnchorConstraint
    self.subtitleTextViewTopAnchorTextViewBottomAnchorConstraint =
      subtitleTextViewTopAnchorTextViewBottomAnchorConstraint
    self.subtitleTextViewLeadingAnchorContentViewViewLeadingAnchorConstraint =
      subtitleTextViewLeadingAnchorContentViewViewLeadingAnchorConstraint
    self.subtitleTextViewTrailingAnchorContentViewViewTrailingAnchorConstraint =
      subtitleTextViewTrailingAnchorContentViewViewTrailingAnchorConstraint
    self.badgeViewViewHeightAnchorParentConstraint = badgeViewViewHeightAnchorParentConstraint
    self.badgeViewViewTrailingAnchorTrailingAnchorConstraint = badgeViewViewTrailingAnchorTrailingAnchorConstraint
    self.badgeViewViewLeadingAnchorContentViewViewTrailingAnchorConstraint =
      badgeViewViewLeadingAnchorContentViewViewTrailingAnchorConstraint
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
        contentViewViewHeightAnchorParentConstraint,
        contentViewViewLeadingAnchorConstraint,
        contentViewViewTopAnchorConstraint,
        contentViewViewCenterYAnchorConstraint,
        contentViewViewBottomAnchorConstraint,
        textViewTopAnchorConstraint,
        textViewLeadingAnchorConstraint,
        textViewTrailingAnchorConstraint
      ] +
        conditionalConstraints(
          badgeViewViewIsHidden: badgeViewView.isHidden,
          subtitleTextViewIsHidden: subtitleTextView.isHidden))
  }

  private func conditionalConstraints(
    badgeViewViewIsHidden: Bool,
    subtitleTextViewIsHidden: Bool) -> [NSLayoutConstraint]
  {
    var constraints: [NSLayoutConstraint?]

    switch (badgeViewViewIsHidden, subtitleTextViewIsHidden) {
      case (true, true):
        constraints = [
          contentViewViewTrailingAnchorTrailingAnchorConstraint,
          textViewBottomAnchorContentViewViewBottomAnchorConstraint
        ]
      case (true, false):
        constraints = [
          contentViewViewTrailingAnchorTrailingAnchorConstraint,
          subtitleTextViewBottomAnchorContentViewViewBottomAnchorConstraint,
          subtitleTextViewTopAnchorTextViewBottomAnchorConstraint,
          subtitleTextViewLeadingAnchorContentViewViewLeadingAnchorConstraint,
          subtitleTextViewTrailingAnchorContentViewViewTrailingAnchorConstraint
        ]
      case (false, true):
        constraints = [
          badgeViewViewHeightAnchorParentConstraint,
          badgeViewViewTrailingAnchorTrailingAnchorConstraint,
          badgeViewViewLeadingAnchorContentViewViewTrailingAnchorConstraint,
          badgeViewViewCenterYAnchorCenterYAnchorConstraint,
          textViewBottomAnchorContentViewViewBottomAnchorConstraint,
          badgeViewViewHeightAnchorConstraint,
          badgeTextViewLeadingAnchorBadgeViewViewLeadingAnchorConstraint,
          badgeTextViewTrailingAnchorBadgeViewViewTrailingAnchorConstraint,
          badgeTextViewTopAnchorBadgeViewViewTopAnchorConstraint,
          badgeTextViewBottomAnchorBadgeViewViewBottomAnchorConstraint
        ]
      case (false, false):
        constraints = [
          badgeViewViewHeightAnchorParentConstraint,
          badgeViewViewTrailingAnchorTrailingAnchorConstraint,
          badgeViewViewLeadingAnchorContentViewViewTrailingAnchorConstraint,
          badgeViewViewCenterYAnchorCenterYAnchorConstraint,
          subtitleTextViewBottomAnchorContentViewViewBottomAnchorConstraint,
          subtitleTextViewTopAnchorTextViewBottomAnchorConstraint,
          subtitleTextViewLeadingAnchorContentViewViewLeadingAnchorConstraint,
          subtitleTextViewTrailingAnchorContentViewViewTrailingAnchorConstraint,
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
    let subtitleTextViewIsHidden = subtitleTextView.isHidden

    badgeTextView.attributedStringValue = badgeTextViewTextStyle.apply(to: "Badge")
    badgeTextViewTextStyle = TextStyles.sectionHeader
    badgeTextView.attributedStringValue = badgeTextViewTextStyle.apply(to: badgeTextView.attributedStringValue)
    badgeViewView.isHidden = !false
    badgeViewView.fillColor = Colors.raisedBackground
    subtitleTextView.isHidden = !false
    subtitleTextView.attributedStringValue = subtitleTextViewTextStyle.apply(to: "Text goes here")
    subtitleTextViewTextStyle = TextStyles.sectionHeader
    subtitleTextView.attributedStringValue = subtitleTextViewTextStyle.apply(to: subtitleTextView.attributedStringValue)
    textViewTextStyle = TextStyles.row
    textView.attributedStringValue = textViewTextStyle.apply(to: textView.attributedStringValue)
    textView.attributedStringValue = textViewTextStyle.apply(to: titleText)
    if let subtitle = subtitleText {
      subtitleTextView.attributedStringValue = subtitleTextViewTextStyle.apply(to: subtitle)
      subtitleTextView.isHidden = !true
    }
    if selected {
      textViewTextStyle = TextStyles.rowInverse
      textView.attributedStringValue = textViewTextStyle.apply(to: textView.attributedStringValue)
      badgeTextViewTextStyle = TextStyles.sectionHeaderInverse
      badgeTextView.attributedStringValue = badgeTextViewTextStyle.apply(to: badgeTextView.attributedStringValue)
      subtitleTextViewTextStyle = TextStyles.sectionHeaderInverse
      subtitleTextView.attributedStringValue =
        subtitleTextViewTextStyle.apply(to: subtitleTextView.attributedStringValue)
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

    if badgeViewView.isHidden != badgeViewViewIsHidden || subtitleTextView.isHidden != subtitleTextViewIsHidden {
      NSLayoutConstraint.deactivate(
        conditionalConstraints(
          badgeViewViewIsHidden: badgeViewViewIsHidden,
          subtitleTextViewIsHidden: subtitleTextViewIsHidden))
      NSLayoutConstraint.activate(
        conditionalConstraints(
          badgeViewViewIsHidden: badgeViewView.isHidden,
          subtitleTextViewIsHidden: subtitleTextView.isHidden))
    }
  }
}

// MARK: - Parameters

extension ResultRow {
  public struct Parameters: Equatable {
    public var titleText: String
    public var subtitleText: String?
    public var selected: Bool
    public var disabled: Bool
    public var badgeText: String?

    public init(
      titleText: String,
      subtitleText: String? = nil,
      selected: Bool,
      disabled: Bool,
      badgeText: String? = nil)
    {
      self.titleText = titleText
      self.subtitleText = subtitleText
      self.selected = selected
      self.disabled = disabled
      self.badgeText = badgeText
    }

    public init() {
      self.init(titleText: "", subtitleText: nil, selected: false, disabled: false, badgeText: nil)
    }

    public static func ==(lhs: Parameters, rhs: Parameters) -> Bool {
      return lhs.titleText == rhs.titleText &&
        lhs.subtitleText == rhs.subtitleText &&
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

    public init(
      titleText: String,
      subtitleText: String? = nil,
      selected: Bool,
      disabled: Bool,
      badgeText: String? = nil)
    {
      self
        .init(
          Parameters(
            titleText: titleText,
            subtitleText: subtitleText,
            selected: selected,
            disabled: disabled,
            badgeText: badgeText))
    }

    public init() {
      self.init(titleText: "", subtitleText: nil, selected: false, disabled: false, badgeText: nil)
    }
  }
}
