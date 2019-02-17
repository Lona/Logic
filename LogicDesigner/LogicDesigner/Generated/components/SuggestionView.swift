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

  public convenience init(searchText: String) {
    self.init(Parameters(searchText: searchText))
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

  public var onChangeSearchText: ((String) -> Void)? {
    get { return parameters.onChangeSearchText }
    set { parameters.onChangeSearchText = newValue }
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

    dividerView.fillColor = Colors.divider
  }

  private func setUpConstraints() {
    translatesAutoresizingMaskIntoConstraints = false
    searchAreaView.translatesAutoresizingMaskIntoConstraints = false
    dividerView.translatesAutoresizingMaskIntoConstraints = false
    suggestionAreaView.translatesAutoresizingMaskIntoConstraints = false
    searchInputView.translatesAutoresizingMaskIntoConstraints = false

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
      suggestionAreaViewHeightAnchorConstraint
    ])
  }

  private func update() {
    searchInputView.onChangeTextValue = handleOnChangeSearchText
    searchInputView.textValue = searchText
  }

  private func handleOnChangeSearchText(_ arg0: String) {
    onChangeSearchText?(arg0)
  }
}

// MARK: - Parameters

extension SuggestionView {
  public struct Parameters: Equatable {
    public var searchText: String
    public var onChangeSearchText: ((String) -> Void)?

    public init(searchText: String, onChangeSearchText: ((String) -> Void)? = nil) {
      self.searchText = searchText
      self.onChangeSearchText = onChangeSearchText
    }

    public init() {
      self.init(searchText: "")
    }

    public static func ==(lhs: Parameters, rhs: Parameters) -> Bool {
      return lhs.searchText == rhs.searchText
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

    public init(searchText: String, onChangeSearchText: ((String) -> Void)? = nil) {
      self.init(Parameters(searchText: searchText, onChangeSearchText: onChangeSearchText))
    }

    public init() {
      self.init(searchText: "")
    }
  }
}

// LONA: KEEP BELOW

extension SuggestionView {
    public var searchInput: ControlledSearchInput {
        return searchInputView
    }
}
