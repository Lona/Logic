//
//  Unification+Core.swift
//  Logic
//
//  Created by Devin Abbott on 6/2/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension Unification.T {
    public static var unit: Unification.T = .cons(name: "Void")
    public static var bool: Unification.T = .cons(name: "Boolean")
    public static var number: Unification.T = .cons(name: "Number")
    public static var string: Unification.T = .cons(name: "String")

    public static var color: Unification.T = .cons(name: "Color")
    public static var shadow: Unification.T = .cons(name: "Shadow")
    public static var textStyle: Unification.T = .cons(name: "TextStyle")

    public static func optional(_ type: Unification.T) -> Unification.T {
        return .cons(name: "Optional", parameters: [type])
    }

    public static func array(_ type: Unification.T) -> Unification.T {
        return .cons(name: "Array", parameters: [type])
    }
}
