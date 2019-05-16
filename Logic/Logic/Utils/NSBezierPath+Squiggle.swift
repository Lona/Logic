//
//  NSBezierPath+Squiggle.swift
//  Logic
//
//  Created by Devin Abbott on 5/15/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

extension NSBezierPath {
    convenience init(squiggleWithin rect: CGRect, lineWidth: CGFloat) {
        self.init()

        self.lineWidth = lineWidth

        let halfLineWidth = lineWidth / 2

        move(to: CGPoint(x: rect.minX + halfLineWidth, y: rect.minY + halfLineWidth))

        for (index, x) in stride(from: rect.minX + halfLineWidth, to: rect.maxX - halfLineWidth, by: rect.height).enumerated() {
            line(to: CGPoint(x: x, y: index % 2 == 0 ? rect.minY + halfLineWidth : rect.maxY - halfLineWidth))
        }

        lineCapStyle = .round
        lineJoinStyle = .round
    }
}
