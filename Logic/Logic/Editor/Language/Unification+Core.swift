//
//  Unification+Core.swift
//  Logic
//
//  Created by Devin Abbott on 6/2/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension Unification.T {
    static var unit: Unification.T = .cons(name: "Void")
    static var bool: Unification.T = .cons(name: "Boolean")
    static var number: Unification.T = .cons(name: "Number")
    static var string: Unification.T = .cons(name: "String")

    static var cssColor: Unification.T = .cons(name: "CSSColor")
    static var color: Unification.T = .cons(name: "Color")
}
