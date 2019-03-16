//
//  GenericTypeParameterSubstitution.swift
//  Logic
//
//  Created by Devin Abbott on 9/26/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import Foundation

public struct GenericTypeParameterSubstitution: Codable & Equatable {
    public init(generic: String, instance: String) {
        self.generic = generic
        self.instance = instance
    }

    public let generic: String
    public let instance: String
}
