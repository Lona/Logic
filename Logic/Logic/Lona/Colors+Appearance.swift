//
//  Colors+Appearance.swift
//  Logic
//
//  Created by Devin Abbott on 3/24/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension Colors {
    public static let background: NSColor = {
        if #available(OSX 10.14, *) {
            switch NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .some(.darkAqua):
                return NSColor.controlBackgroundColor
            default:
                break
            }
        }

        return NSColor.white
    }()

    public static let raisedBackground: NSColor = {
        if #available(OSX 10.14, *) {
            switch NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .some(.darkAqua):
                return NSColor.controlBackgroundColor.blended(withFraction: 0.01, of: NSColor.white)!
            default:
                break
            }
        }

        return NSColor.black.withAlphaComponent(0.03)
    }()

    public static let text: NSColor = {
        if #available(OSX 10.14, *) {
            switch NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .some(.darkAqua):
                return NSColor.white
            default:
                break
            }
        }

        return NSColor.black
    }()

    public static let textNoneditable: NSColor = {
        if #available(OSX 10.14, *) {
            switch NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .some(.darkAqua):
                return NSColor.white.blended(withFraction: 0.3, of: NSColor.black)!
            default:
                break
            }
        }

        return NSColor.systemGray
    }()

    public static let divider: NSColor = {
        if #available(OSX 10.14, *) {
            switch NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .some(.darkAqua):
                return #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
            default:
                break
            }
        }

        return #colorLiteral(red: 0.9294117647, green: 0.9294117647, blue: 0.9294117647, alpha: 1)
    }()
}
