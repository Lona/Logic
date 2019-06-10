import AppKit
import Foundation

// MARK: - InfoBar

public class InfoBar: NSBox {

  // MARK: Lifecycle

  public init(_ parameters: Parameters) {
    self.parameters = parameters

    super.init(frame: .zero)

    setUpViews()
    setUpConstraints()

    update()
  }

  public convenience init(dropdownValues: [String], dropdownIndex: Int) {
    self.init(Parameters(dropdownValues: dropdownValues, dropdownIndex: dropdownIndex))
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

  public var dropdownValues: [String] {
    get { return parameters.dropdownValues }
    set {
      if parameters.dropdownValues != newValue {
        parameters.dropdownValues = newValue
      }
    }
  }

  public var dropdownIndex: Int {
    get { return parameters.dropdownIndex }
    set {
      if parameters.dropdownIndex != newValue {
        parameters.dropdownIndex = newValue
      }
    }
  }

  public var onChangeDropdownIndex: ((Int) -> Void)? {
    get { return parameters.onChangeDropdownIndex }
    set { parameters.onChangeDropdownIndex = newValue }
  }

  public var parameters: Parameters {
    didSet {
      if parameters != oldValue {
        update()
      }
    }
  }

  // MARK: Private

  private var spacerView = NSBox()
  private var controlledDropdownContainerView = NSBox()
  private var controlledDropdownView = ControlledDropdown()

  private func setUpViews() {
    boxType = .custom
    borderType = .noBorder
    contentViewMargins = .zero
    spacerView.boxType = .custom
    spacerView.borderType = .noBorder
    spacerView.contentViewMargins = .zero
    controlledDropdownContainerView.boxType = .custom
    controlledDropdownContainerView.borderType = .noBorder
    controlledDropdownContainerView.contentViewMargins = .zero

    addSubview(spacerView)
    addSubview(controlledDropdownContainerView)
    controlledDropdownContainerView.addSubview(controlledDropdownView)
  }

  private func setUpConstraints() {
    translatesAutoresizingMaskIntoConstraints = false
    spacerView.translatesAutoresizingMaskIntoConstraints = false
    controlledDropdownContainerView.translatesAutoresizingMaskIntoConstraints = false
    controlledDropdownView.translatesAutoresizingMaskIntoConstraints = false

    let heightAnchorConstraint = heightAnchor.constraint(equalToConstant: 32)
    let spacerViewLeadingAnchorConstraint = spacerView.leadingAnchor.constraint(equalTo: leadingAnchor)
    let spacerViewTopAnchorConstraint = spacerView.topAnchor.constraint(equalTo: topAnchor)
    let spacerViewBottomAnchorConstraint = spacerView.bottomAnchor.constraint(equalTo: bottomAnchor)
    let controlledDropdownContainerViewTrailingAnchorConstraint = controlledDropdownContainerView
      .trailingAnchor
      .constraint(equalTo: trailingAnchor)
    let controlledDropdownContainerViewLeadingAnchorConstraint = controlledDropdownContainerView
      .leadingAnchor
      .constraint(equalTo: spacerView.trailingAnchor)
    let controlledDropdownContainerViewTopAnchorConstraint = controlledDropdownContainerView
      .topAnchor
      .constraint(equalTo: topAnchor)
    let controlledDropdownContainerViewBottomAnchorConstraint = controlledDropdownContainerView
      .bottomAnchor
      .constraint(equalTo: bottomAnchor)
    let controlledDropdownViewLeadingAnchorConstraint = controlledDropdownView
      .leadingAnchor
      .constraint(equalTo: controlledDropdownContainerView.leadingAnchor, constant: 5)
    let controlledDropdownViewTrailingAnchorConstraint = controlledDropdownView
      .trailingAnchor
      .constraint(equalTo: controlledDropdownContainerView.trailingAnchor, constant: -5)
    let controlledDropdownViewTopAnchorConstraint = controlledDropdownView
      .topAnchor
      .constraint(greaterThanOrEqualTo: controlledDropdownContainerView.topAnchor)
    let controlledDropdownViewCenterYAnchorConstraint = controlledDropdownView
      .centerYAnchor
      .constraint(equalTo: controlledDropdownContainerView.centerYAnchor)
    let controlledDropdownViewBottomAnchorConstraint = controlledDropdownView
      .bottomAnchor
      .constraint(lessThanOrEqualTo: controlledDropdownContainerView.bottomAnchor)

    NSLayoutConstraint.activate([
      heightAnchorConstraint,
      spacerViewLeadingAnchorConstraint,
      spacerViewTopAnchorConstraint,
      spacerViewBottomAnchorConstraint,
      controlledDropdownContainerViewTrailingAnchorConstraint,
      controlledDropdownContainerViewLeadingAnchorConstraint,
      controlledDropdownContainerViewTopAnchorConstraint,
      controlledDropdownContainerViewBottomAnchorConstraint,
      controlledDropdownViewLeadingAnchorConstraint,
      controlledDropdownViewTrailingAnchorConstraint,
      controlledDropdownViewTopAnchorConstraint,
      controlledDropdownViewCenterYAnchorConstraint,
      controlledDropdownViewBottomAnchorConstraint
    ])
  }

  private func update() {
    controlledDropdownView.selectedIndex = dropdownIndex
    controlledDropdownView.values = dropdownValues
    controlledDropdownView.onChangeIndex = handleOnChangeDropdownIndex
  }

  private func handleOnChangeDropdownIndex(_ arg0: Int) {
    onChangeDropdownIndex?(arg0)
  }
}

// MARK: - Parameters

extension InfoBar {
  public struct Parameters: Equatable {
    public var dropdownValues: [String]
    public var dropdownIndex: Int
    public var onChangeDropdownIndex: ((Int) -> Void)?

    public init(dropdownValues: [String], dropdownIndex: Int, onChangeDropdownIndex: ((Int) -> Void)? = nil) {
      self.dropdownValues = dropdownValues
      self.dropdownIndex = dropdownIndex
      self.onChangeDropdownIndex = onChangeDropdownIndex
    }

    public init() {
      self.init(dropdownValues: [], dropdownIndex: 0)
    }

    public static func ==(lhs: Parameters, rhs: Parameters) -> Bool {
      return lhs.dropdownValues == rhs.dropdownValues && lhs.dropdownIndex == rhs.dropdownIndex
    }
  }
}

// MARK: - Model

extension InfoBar {
  public struct Model: LonaViewModel, Equatable {
    public var id: String?
    public var parameters: Parameters
    public var type: String {
      return "InfoBar"
    }

    public init(id: String? = nil, parameters: Parameters) {
      self.id = id
      self.parameters = parameters
    }

    public init(_ parameters: Parameters) {
      self.parameters = parameters
    }

    public init(dropdownValues: [String], dropdownIndex: Int, onChangeDropdownIndex: ((Int) -> Void)? = nil) {
      self
        .init(
          Parameters(
            dropdownValues: dropdownValues,
            dropdownIndex: dropdownIndex,
            onChangeDropdownIndex: onChangeDropdownIndex))
    }

    public init() {
      self.init(dropdownValues: [], dropdownIndex: 0)
    }
  }
}
