//
//  ImageBackground.swift
//  Logic
//
//  Created by Devin Abbott on 2/23/20.
//  Copyright © 2020 BitDisco, Inc. All rights reserved.
//

import AppKit

// MARK: - ImageBackground

public class ImageBackground: NSView {

    // MARK: Lifecycle

    public init(_ parameters: Parameters) {
        self.parameters = parameters

        super.init(frame: .zero)

        setUpViews()
        setUpConstraints()

        update()

        addTrackingArea(trackingArea)
    }

    public convenience init(image: NSImage?) {
        self.init(Parameters(image: image))
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

    public var image: NSImage? {
        get { return parameters.image }
        set {
            if parameters.image != newValue {
                parameters.image = newValue
            }
        }
    }

    public var onPressImage: (() -> Void)? {
        get { return parameters.onPressImage }
        set { parameters.onPressImage = newValue }
    }

    public var parameters: Parameters {
        didSet {
            if parameters != oldValue {
                update()
                invalidateIntrinsicContentSize()
            }
        }
    }

    // MARK: Private

    private lazy var trackingArea = NSTrackingArea(
        rect: self.frame,
        options: [.mouseEnteredAndExited, .activeAlways, .mouseMoved, .inVisibleRect],
        owner: self)

    private var hovered = false
    private var pressed = false
    private var onPress: (() -> Void)?

    private var minimumImageHeightAnchorConstraint: NSLayoutConstraint?
    private var heightAnchorConstraint: NSLayoutConstraint?
    private var widthAnchorConstraint: NSLayoutConstraint?
    private var aspectRatioConstraint: NSLayoutConstraint?

    private func setUpViews() {}

    private func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        minimumImageHeightAnchorConstraint = heightAnchor.constraint(lessThanOrEqualToConstant: 100)
        minimumImageHeightAnchorConstraint?.isActive = true

        heightAnchorConstraint = heightAnchor.constraint(equalToConstant: 100)
        widthAnchorConstraint = heightAnchor.constraint(equalToConstant: 100)
    }

    private func update() {
        onPress = handleOnPressImage
        alphaValue = hovered ? 0.75 : 1

        if let _ = image {
            heightAnchorConstraint?.isActive = false
            widthAnchorConstraint?.isActive = false

            let imageSize = image?.size ?? NSSize(width: 100, height: 100)
            let aspectRatio = imageSize.height / imageSize.width
            let constraintMultiplier = aspectRatio > 0 ? aspectRatio : 1

            minimumImageHeightAnchorConstraint?.constant = imageSize.height

            if aspectRatioConstraint?.multiplier != constraintMultiplier {
                aspectRatioConstraint?.isActive = false

                aspectRatioConstraint = NSLayoutConstraint(
                    item: self,
                    attribute: .height,
                    relatedBy: .equal,
                    toItem: self,
                    attribute: .width,
                    multiplier: constraintMultiplier,
                    constant: 0
                )

                aspectRatioConstraint?.isActive = true
            }
        } else {
            heightAnchorConstraint?.isActive = true
            widthAnchorConstraint?.isActive = true

            aspectRatioConstraint?.isActive = false
        }
    }

    public override func draw(_ dirtyRect: NSRect) {
        Colors.blockBackground.set()
        bounds.fill()

        if let image = image {
            let imageRect = image.size.resized(within: dirtyRect.size, usingResizingMode: .scaleAspectFit)
            image.draw(in: backingAlignedRect(imageRect, options: .alignAllEdgesNearest))
        }
    }

    private func handleOnPressImage() {
        onPressImage?()
    }

    public override func mouseEntered(with event: NSEvent) {
        self.hovered = true

        update()
    }

    public override func mouseExited(with event: NSEvent) {
        self.hovered = false

        update()
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

extension ImageBackground {
    public struct Parameters: Equatable {
        public var image: NSImage?
        public var onPressImage: (() -> Void)?

        public init(image: NSImage?, onPressImage: (() -> Void)? = nil) {
            self.image = image
            self.onPressImage = onPressImage
        }

        public init() {
            self.init(image: nil)
        }

        public static func ==(lhs: Parameters, rhs: Parameters) -> Bool {
            return lhs.image == rhs.image
        }
    }
}
