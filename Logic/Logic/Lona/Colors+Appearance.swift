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

        return #colorLiteral(red: 0.9725490196, green: 0.9725490196, blue: 0.9725490196, alpha: 1)
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
                return NSColor.white.blended(withFraction: 0.5, of: NSColor.black)!
            default:
                break
            }
        }

        return NSColor.systemGray
    }()

    public static let textComment: NSColor = {
        if #available(OSX 10.14, *) {
            switch NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .some(.darkAqua):
                return NSColor.white.withAlphaComponent(0.25)
            default:
                break
            }
        }

        return NSColor.black.withAlphaComponent(0.4)
    }()

    public static let commentBackground: NSColor = {
        if #available(OSX 10.14, *) {
            switch NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .some(.darkAqua):
                return NSColor.black.withAlphaComponent(0.15)
            default:
                break
            }
        }

        return NSColor.black.withAlphaComponent(0.05)
    }()

    public static let indentGuide: NSColor = {
        if #available(OSX 10.14, *) {
            switch NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .some(.darkAqua):
                return NSColor.black.withAlphaComponent(0.18)
            default:
                break
            }
        }

        return NSColor.black.withAlphaComponent(0.06)
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

    public static let highlightedCode: NSColor = {
        if #available(OSX 10.14, *) {
            switch NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .some(.darkAqua):
                return NSColor.selectedMenuItemColor.withAlphaComponent(0.3)
            default:
                break
            }
        }

        return NSColor.selectedMenuItemColor.highlight(withLevel: 0.8)!
    }()

    public static let highlightedLine: NSColor = {
        if #available(OSX 10.14, *) {
            switch NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .some(.darkAqua):
                return NSColor.selectedMenuItemColor.withAlphaComponent(0.3)
            default:
                break
            }
        }

        return NSColor.selectedMenuItemColor.highlight(withLevel: 0.9)!
    }()

    public static let suggestionListBackground: NSColor = {
        if #available(OSX 10.14, *) {
            switch NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .some(.darkAqua):
                return Colors.raisedBackground
            default:
                break
            }
        }

        return NSColor.controlBackgroundColor
    }()

    public static let suggestionWindowBackground: NSColor = {
        if #available(OSX 10.14, *) {
            switch NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .some(.darkAqua):
                return Colors.raisedBackground
            default:
                break
            }
        }

        return Colors.background
    }()

    public static let filterLabelBackground: NSColor = {
        if #available(OSX 10.14, *) {
            switch NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .some(.darkAqua):
                return NSColor.parse(css: "rgb(60,60,60)")!
            default:
                break
            }
        }

        return NSColor.parse(css: "rgb(200,200,200)")!
    }()
}
