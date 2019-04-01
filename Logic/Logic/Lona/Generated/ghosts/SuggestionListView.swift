import AppKit
import Foundation

// MARK: - SuggestionListView

public class SuggestionListView: NSBox {

  // MARK: Lifecycle

  public init(_ parameters: Parameters) {
    self.parameters = parameters

    super.init(frame: .zero)

    setUpViews()
    setUpConstraints()

    update()
  }

  public convenience init(selectedIndex: Int?) {
    self.init(Parameters(selectedIndex: selectedIndex))
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

  public var onSelectIndex: ((Int?) -> Void)? {
    get { return parameters.onSelectIndex }
    set { parameters.onSelectIndex = newValue }
  }

  public var selectedIndex: Int? {
    get { return parameters.selectedIndex }
    set {
      if parameters.selectedIndex != newValue {
        parameters.selectedIndex = newValue
      }
    }
  }

  public var onActivateIndex: ((Int) -> Void)? {
    get { return parameters.onActivateIndex }
    set { parameters.onActivateIndex = newValue }
  }

  public var parameters: Parameters {
    didSet {
      if parameters != oldValue {
        update()
      }
    }
  }

  // MARK: Private

  private var rowWrapperView = NSBox()
  private var resultSectionHeaderView = ResultSectionHeader()
  private var resultRowView = ResultRow()
  private var resultRow1View = ResultRow()

  private func setUpViews() {
    boxType = .custom
    borderType = .noBorder
    contentViewMargins = .zero
    rowWrapperView.boxType = .custom
    rowWrapperView.borderType = .noBorder
    rowWrapperView.contentViewMargins = .zero

    addSubview(rowWrapperView)
    addSubview(resultRowView)
    addSubview(resultRow1View)
    rowWrapperView.addSubview(resultSectionHeaderView)

    resultSectionHeaderView.titleText = "STATEMENTS"
    resultRowView.titleText = "If condition"
    resultRow1View.titleText = "For loop"
  }

  private func setUpConstraints() {
    translatesAutoresizingMaskIntoConstraints = false
    rowWrapperView.translatesAutoresizingMaskIntoConstraints = false
    resultRowView.translatesAutoresizingMaskIntoConstraints = false
    resultRow1View.translatesAutoresizingMaskIntoConstraints = false
    resultSectionHeaderView.translatesAutoresizingMaskIntoConstraints = false

    let rowWrapperViewTopAnchorConstraint = rowWrapperView.topAnchor.constraint(equalTo: topAnchor)
    let rowWrapperViewLeadingAnchorConstraint = rowWrapperView.leadingAnchor.constraint(equalTo: leadingAnchor)
    let rowWrapperViewTrailingAnchorConstraint = rowWrapperView.trailingAnchor.constraint(equalTo: trailingAnchor)
    let resultRowViewTopAnchorConstraint = resultRowView.topAnchor.constraint(equalTo: rowWrapperView.bottomAnchor)
    let resultRowViewLeadingAnchorConstraint = resultRowView.leadingAnchor.constraint(equalTo: leadingAnchor)
    let resultRowViewTrailingAnchorConstraint = resultRowView.trailingAnchor.constraint(equalTo: trailingAnchor)
    let resultRow1ViewTopAnchorConstraint = resultRow1View.topAnchor.constraint(equalTo: resultRowView.bottomAnchor)
    let resultRow1ViewLeadingAnchorConstraint = resultRow1View.leadingAnchor.constraint(equalTo: leadingAnchor)
    let resultRow1ViewTrailingAnchorConstraint = resultRow1View.trailingAnchor.constraint(equalTo: trailingAnchor)
    let rowWrapperViewHeightAnchorConstraint = rowWrapperView.heightAnchor.constraint(equalToConstant: 18)
    let resultSectionHeaderViewTopAnchorConstraint = resultSectionHeaderView
      .topAnchor
      .constraint(equalTo: rowWrapperView.topAnchor)
    let resultSectionHeaderViewBottomAnchorConstraint = resultSectionHeaderView
      .bottomAnchor
      .constraint(equalTo: rowWrapperView.bottomAnchor)
    let resultSectionHeaderViewLeadingAnchorConstraint = resultSectionHeaderView
      .leadingAnchor
      .constraint(equalTo: rowWrapperView.leadingAnchor)
    let resultSectionHeaderViewTrailingAnchorConstraint = resultSectionHeaderView
      .trailingAnchor
      .constraint(equalTo: rowWrapperView.trailingAnchor)

    NSLayoutConstraint.activate([
      rowWrapperViewTopAnchorConstraint,
      rowWrapperViewLeadingAnchorConstraint,
      rowWrapperViewTrailingAnchorConstraint,
      resultRowViewTopAnchorConstraint,
      resultRowViewLeadingAnchorConstraint,
      resultRowViewTrailingAnchorConstraint,
      resultRow1ViewTopAnchorConstraint,
      resultRow1ViewLeadingAnchorConstraint,
      resultRow1ViewTrailingAnchorConstraint,
      rowWrapperViewHeightAnchorConstraint,
      resultSectionHeaderViewTopAnchorConstraint,
      resultSectionHeaderViewBottomAnchorConstraint,
      resultSectionHeaderViewLeadingAnchorConstraint,
      resultSectionHeaderViewTrailingAnchorConstraint
    ])
  }

  private func update() {}

  private func handleOnSelectIndex(_ arg0: Int?) {
    onSelectIndex?(arg0)
  }

  private func handleOnActivateIndex(_ arg0: Int) {
    onActivateIndex?(arg0)
  }
}

// MARK: - Parameters

extension SuggestionListView {
  public struct Parameters: Equatable {
    public var selectedIndex: Int?
    public var onSelectIndex: ((Int?) -> Void)?
    public var onActivateIndex: ((Int) -> Void)?

    public init(
      selectedIndex: Int? = nil,
      onSelectIndex: ((Int?) -> Void)? = nil,
      onActivateIndex: ((Int) -> Void)? = nil)
    {
      self.selectedIndex = selectedIndex
      self.onSelectIndex = onSelectIndex
      self.onActivateIndex = onActivateIndex
    }

    public static func ==(lhs: Parameters, rhs: Parameters) -> Bool {
      return lhs.selectedIndex == rhs.selectedIndex
    }
  }
}

// MARK: - Model

extension SuggestionListView {
  public struct Model: LonaViewModel, Equatable {
    public var id: String?
    public var parameters: Parameters
    public var type: String {
      return "SuggestionListView"
    }

    public init(id: String? = nil, parameters: Parameters) {
      self.id = id
      self.parameters = parameters
    }

    public init(_ parameters: Parameters) {
      self.parameters = parameters
    }

    public init(
      selectedIndex: Int? = nil,
      onSelectIndex: ((Int?) -> Void)? = nil,
      onActivateIndex: ((Int) -> Void)? = nil)
    {
      self
        .init(Parameters(selectedIndex: selectedIndex, onSelectIndex: onSelectIndex, onActivateIndex: onActivateIndex))
    }
  }
}
