import AppKit
import Foundation

// MARK: - SuggestionView

public class SuggestionView: NSBox {

  // MARK: Lifecycle

  public init(_ parameters: Parameters) {
    self.parameters = parameters

    super.init(frame: .zero)

    setUpViews()
    setUpConstraints()

    update()
  }

  public convenience init(searchText: String, placeholderText: String?, selectedIndex: Int?) {
    self.init(Parameters(searchText: searchText, placeholderText: placeholderText, selectedIndex: selectedIndex))
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

  public var searchText: String {
    get { return parameters.searchText }
    set {
      if parameters.searchText != newValue {
        parameters.searchText = newValue
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

  public var onChangeSearchText: ((String) -> Void)? {
    get { return parameters.onChangeSearchText }
    set { parameters.onChangeSearchText = newValue }
  }

  public var onPressDownKey: (() -> Void)? {
    get { return parameters.onPressDownKey }
    set { parameters.onPressDownKey = newValue }
  }

  public var onPressUpKey: (() -> Void)? {
    get { return parameters.onPressUpKey }
    set { parameters.onPressUpKey = newValue }
  }

  public var selectedIndex: Int? {
    get { return parameters.selectedIndex }
    set {
      if parameters.selectedIndex != newValue {
        parameters.selectedIndex = newValue
      }
    }
  }

  public var onSelectIndex: ((Int?) -> Void)? {
    get { return parameters.onSelectIndex }
    set { parameters.onSelectIndex = newValue }
  }

  public var onActivateIndex: ((Int) -> Void)? {
    get { return parameters.onActivateIndex }
    set { parameters.onActivateIndex = newValue }
  }

  public var onSubmit: (() -> Void)? {
    get { return parameters.onSubmit }
    set { parameters.onSubmit = newValue }
  }

  public var onPressTabKey: (() -> Void)? {
    get { return parameters.onPressTabKey }
    set { parameters.onPressTabKey = newValue }
  }

  public var onPressShiftTabKey: (() -> Void)? {
    get { return parameters.onPressShiftTabKey }
    set { parameters.onPressShiftTabKey = newValue }
  }

  public var onPressEscapeKey: (() -> Void)? {
    get { return parameters.onPressEscapeKey }
    set { parameters.onPressEscapeKey = newValue }
  }

  public var parameters: Parameters {
    didSet {
      if parameters != oldValue {
        update()
      }
    }
  }

  // MARK: Private

  private var searchAreaView = NSBox()
  private var searchInputView = ControlledSearchInput()
  private var dividerView = NSBox()
  private var suggestionAreaView = NSBox()
  private var suggestionListViewView = SuggestionListView()

  private func setUpViews() {
    boxType = .custom
    borderType = .noBorder
    contentViewMargins = .zero
    searchAreaView.boxType = .custom
    searchAreaView.borderType = .noBorder
    searchAreaView.contentViewMargins = .zero
    dividerView.boxType = .custom
    dividerView.borderType = .noBorder
    dividerView.contentViewMargins = .zero
    suggestionAreaView.boxType = .custom
    suggestionAreaView.borderType = .noBorder
    suggestionAreaView.contentViewMargins = .zero

    addSubview(searchAreaView)
    addSubview(dividerView)
    addSubview(suggestionAreaView)
    searchAreaView.addSubview(searchInputView)
    suggestionAreaView.addSubview(suggestionListViewView)

    dividerView.fillColor = Colors.divider
  }

  private func setUpConstraints() {
    translatesAutoresizingMaskIntoConstraints = false
    searchAreaView.translatesAutoresizingMaskIntoConstraints = false
    dividerView.translatesAutoresizingMaskIntoConstraints = false
    suggestionAreaView.translatesAutoresizingMaskIntoConstraints = false
    searchInputView.translatesAutoresizingMaskIntoConstraints = false
    suggestionListViewView.translatesAutoresizingMaskIntoConstraints = false

    let searchAreaViewTopAnchorConstraint = searchAreaView.topAnchor.constraint(equalTo: topAnchor)
    let searchAreaViewLeadingAnchorConstraint = searchAreaView.leadingAnchor.constraint(equalTo: leadingAnchor)
    let searchAreaViewTrailingAnchorConstraint = searchAreaView.trailingAnchor.constraint(equalTo: trailingAnchor)
    let dividerViewTopAnchorConstraint = dividerView.topAnchor.constraint(equalTo: searchAreaView.bottomAnchor)
    let dividerViewLeadingAnchorConstraint = dividerView.leadingAnchor.constraint(equalTo: leadingAnchor)
    let dividerViewTrailingAnchorConstraint = dividerView.trailingAnchor.constraint(equalTo: trailingAnchor)
    let suggestionAreaViewBottomAnchorConstraint = suggestionAreaView.bottomAnchor.constraint(equalTo: bottomAnchor)
    let suggestionAreaViewTopAnchorConstraint = suggestionAreaView
      .topAnchor
      .constraint(equalTo: dividerView.bottomAnchor)
    let suggestionAreaViewLeadingAnchorConstraint = suggestionAreaView.leadingAnchor.constraint(equalTo: leadingAnchor)
    let suggestionAreaViewTrailingAnchorConstraint = suggestionAreaView
      .trailingAnchor
      .constraint(equalTo: trailingAnchor)
    let searchAreaViewHeightAnchorConstraint = searchAreaView.heightAnchor.constraint(equalToConstant: 32)
    let searchInputViewLeadingAnchorConstraint = searchInputView
      .leadingAnchor
      .constraint(equalTo: searchAreaView.leadingAnchor, constant: 10)
    let searchInputViewTrailingAnchorConstraint = searchInputView
      .trailingAnchor
      .constraint(equalTo: searchAreaView.trailingAnchor, constant: -10)
    let searchInputViewTopAnchorConstraint = searchInputView
      .topAnchor
      .constraint(equalTo: searchAreaView.topAnchor, constant: 5)
    let searchInputViewBottomAnchorConstraint = searchInputView
      .bottomAnchor
      .constraint(equalTo: searchAreaView.bottomAnchor, constant: -5)
    let dividerViewHeightAnchorConstraint = dividerView.heightAnchor.constraint(equalToConstant: 1)
    let suggestionAreaViewHeightAnchorConstraint = suggestionAreaView.heightAnchor.constraint(equalToConstant: 200)
    let suggestionListViewViewTopAnchorConstraint = suggestionListViewView
      .topAnchor
      .constraint(equalTo: suggestionAreaView.topAnchor)
    let suggestionListViewViewBottomAnchorConstraint = suggestionListViewView
      .bottomAnchor
      .constraint(equalTo: suggestionAreaView.bottomAnchor)
    let suggestionListViewViewLeadingAnchorConstraint = suggestionListViewView
      .leadingAnchor
      .constraint(equalTo: suggestionAreaView.leadingAnchor)
    let suggestionListViewViewTrailingAnchorConstraint = suggestionListViewView
      .trailingAnchor
      .constraint(equalTo: suggestionAreaView.trailingAnchor)

    NSLayoutConstraint.activate([
      searchAreaViewTopAnchorConstraint,
      searchAreaViewLeadingAnchorConstraint,
      searchAreaViewTrailingAnchorConstraint,
      dividerViewTopAnchorConstraint,
      dividerViewLeadingAnchorConstraint,
      dividerViewTrailingAnchorConstraint,
      suggestionAreaViewBottomAnchorConstraint,
      suggestionAreaViewTopAnchorConstraint,
      suggestionAreaViewLeadingAnchorConstraint,
      suggestionAreaViewTrailingAnchorConstraint,
      searchAreaViewHeightAnchorConstraint,
      searchInputViewLeadingAnchorConstraint,
      searchInputViewTrailingAnchorConstraint,
      searchInputViewTopAnchorConstraint,
      searchInputViewBottomAnchorConstraint,
      dividerViewHeightAnchorConstraint,
      suggestionAreaViewHeightAnchorConstraint,
      suggestionListViewViewTopAnchorConstraint,
      suggestionListViewViewBottomAnchorConstraint,
      suggestionListViewViewLeadingAnchorConstraint,
      suggestionListViewViewTrailingAnchorConstraint
    ])
  }

  private func update() {
    searchInputView.onChangeTextValue = handleOnChangeSearchText
    searchInputView.textValue = searchText
    searchInputView.placeholderText = placeholderText
    searchInputView.onPressDownKey = handleOnPressDownKey
    searchInputView.onPressUpKey = handleOnPressUpKey
    suggestionListViewView.selectedIndex = selectedIndex
    suggestionListViewView.onSelectIndex = handleOnSelectIndex
    suggestionListViewView.onActivateIndex = handleOnActivateIndex
    searchInputView.onSubmit = handleOnSubmit
    searchInputView.onPressEscape = handleOnPressEscapeKey
    searchInputView.onPressTab = handleOnPressTabKey
    searchInputView.onPressShiftTab = handleOnPressShiftTabKey
  }

  private func handleOnChangeSearchText(_ arg0: String) {
    onChangeSearchText?(arg0)
  }

  private func handleOnPressDownKey() {
    onPressDownKey?()
  }

  private func handleOnPressUpKey() {
    onPressUpKey?()
  }

  private func handleOnSelectIndex(_ arg0: Int?) {
    onSelectIndex?(arg0)
  }

  private func handleOnActivateIndex(_ arg0: Int) {
    onActivateIndex?(arg0)
  }

  private func handleOnSubmit() {
    onSubmit?()
  }

  private func handleOnPressTabKey() {
    onPressTabKey?()
  }

  private func handleOnPressShiftTabKey() {
    onPressShiftTabKey?()
  }

  private func handleOnPressEscapeKey() {
    onPressEscapeKey?()
  }
}

// MARK: - Parameters

extension SuggestionView {
  public struct Parameters: Equatable {
    public var searchText: String
    public var placeholderText: String?
    public var selectedIndex: Int?
    public var onChangeSearchText: ((String) -> Void)?
    public var onPressDownKey: (() -> Void)?
    public var onPressUpKey: (() -> Void)?
    public var onSelectIndex: ((Int?) -> Void)?
    public var onActivateIndex: ((Int) -> Void)?
    public var onSubmit: (() -> Void)?
    public var onPressTabKey: (() -> Void)?
    public var onPressShiftTabKey: (() -> Void)?
    public var onPressEscapeKey: (() -> Void)?

    public init(
      searchText: String,
      placeholderText: String? = nil,
      selectedIndex: Int? = nil,
      onChangeSearchText: ((String) -> Void)? = nil,
      onPressDownKey: (() -> Void)? = nil,
      onPressUpKey: (() -> Void)? = nil,
      onSelectIndex: ((Int?) -> Void)? = nil,
      onActivateIndex: ((Int) -> Void)? = nil,
      onSubmit: (() -> Void)? = nil,
      onPressTabKey: (() -> Void)? = nil,
      onPressShiftTabKey: (() -> Void)? = nil,
      onPressEscapeKey: (() -> Void)? = nil)
    {
      self.searchText = searchText
      self.placeholderText = placeholderText
      self.selectedIndex = selectedIndex
      self.onChangeSearchText = onChangeSearchText
      self.onPressDownKey = onPressDownKey
      self.onPressUpKey = onPressUpKey
      self.onSelectIndex = onSelectIndex
      self.onActivateIndex = onActivateIndex
      self.onSubmit = onSubmit
      self.onPressTabKey = onPressTabKey
      self.onPressShiftTabKey = onPressShiftTabKey
      self.onPressEscapeKey = onPressEscapeKey
    }

    public init() {
      self.init(searchText: "", placeholderText: nil, selectedIndex: nil)
    }

    public static func ==(lhs: Parameters, rhs: Parameters) -> Bool {
      return lhs.searchText == rhs.searchText &&
        lhs.placeholderText == rhs.placeholderText && lhs.selectedIndex == rhs.selectedIndex
    }
  }
}

// MARK: - Model

extension SuggestionView {
  public struct Model: LonaViewModel, Equatable {
    public var id: String?
    public var parameters: Parameters
    public var type: String {
      return "SuggestionView"
    }

    public init(id: String? = nil, parameters: Parameters) {
      self.id = id
      self.parameters = parameters
    }

    public init(_ parameters: Parameters) {
      self.parameters = parameters
    }

    public init(
      searchText: String,
      placeholderText: String? = nil,
      selectedIndex: Int? = nil,
      onChangeSearchText: ((String) -> Void)? = nil,
      onPressDownKey: (() -> Void)? = nil,
      onPressUpKey: (() -> Void)? = nil,
      onSelectIndex: ((Int?) -> Void)? = nil,
      onActivateIndex: ((Int) -> Void)? = nil,
      onSubmit: (() -> Void)? = nil,
      onPressTabKey: (() -> Void)? = nil,
      onPressShiftTabKey: (() -> Void)? = nil,
      onPressEscapeKey: (() -> Void)? = nil)
    {
      self
        .init(
          Parameters(
            searchText: searchText,
            placeholderText: placeholderText,
            selectedIndex: selectedIndex,
            onChangeSearchText: onChangeSearchText,
            onPressDownKey: onPressDownKey,
            onPressUpKey: onPressUpKey,
            onSelectIndex: onSelectIndex,
            onActivateIndex: onActivateIndex,
            onSubmit: onSubmit,
            onPressTabKey: onPressTabKey,
            onPressShiftTabKey: onPressShiftTabKey,
            onPressEscapeKey: onPressEscapeKey))
    }

    public init() {
      self.init(searchText: "", placeholderText: nil, selectedIndex: nil)
    }
  }
}

// LONA: KEEP BELOW

extension SuggestionView {
    public var searchInput: ControlledSearchInput {
        return searchInputView
    }

    public var suggestionList: SuggestionListView {
        return suggestionListViewView
    }
}
