//
//  SyntaxNodePlaceholderList.swift
//  Logic
//
//  Created by Devin Abbott on 4/5/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension LGCList where T: SyntaxNodeProtocol, T: SyntaxNodePlaceholdable {
    func replace(id: UUID, with syntaxNode: LGCSyntaxNode, preservingEndingPlaceholder: Bool) -> LGCList {
        let result = self.map { $0.replace(id: id, with: syntaxNode) }

        if preservingEndingPlaceholder {
            return LGCList(result).normalizedPlaceholders
        }

        return LGCList(result)
    }

    var normalizedPlaceholders: LGCList {
        var result = self.map { $0 }.filter { !$0.isPlaceholder }

        let placeholder = T.self.makePlaceholder()
        result.append(placeholder)

        return LGCList(result)
    }
}

extension LGCList where T == LGCDeclaration {
    func replace(id: UUID, with syntaxNode: LGCSyntaxNode, preservingEndingPlaceholder: Bool) -> LGCList {
        let result = self.map { $0.replace(id: id, with: syntaxNode) }

        if preservingEndingPlaceholder {
            return LGCList(result).normalizedPlaceholders
        }

        return LGCList(result)
    }

    var normalizedPlaceholders: LGCList {
        var result = self.map { $0 }

        if let last = result.last, !last.isPlaceholder {
            let placeholder = T.self.makePlaceholder()
            result.append(placeholder)
        }

        return LGCList(result)
    }
}
