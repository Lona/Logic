//
//  Compiler.swift
//  Logic
//
//  Created by Devin Abbott on 5/28/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public enum Compiler {
    public enum CompilerError: Error {
        case namespace(Compiler.NamespaceError)
        case unification(Unification.UnificationError)
    }
}
