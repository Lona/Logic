//
//  NSBezierPath+Plus.swift
//  Logic
//
//  Created by Devin Abbott on 5/15/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

extension NSBezierPath {
    convenience init(plusWithin rect: CGRect, lineWidth: CGFloat, margin: CGSize) {
        self.init()

        self.lineWidth = lineWidth

        let halfLineWidth = lineWidth / 2

        move(to: .init(x: rect.minX + halfLineWidth + margin.width, y: rect.midY))
        line(to: .init(x: rect.maxX - halfLineWidth - margin.width, y: rect.midY))

        move(to: .init(x: rect.midX, y: rect.minY + halfLineWidth + margin.height))
        line(to: .init(x: rect.midX, y: rect.maxY - halfLineWidth - margin.height))

        move(to: .init(x: rect.minX + halfLineWidth + margin.width, y: rect.midY))

        lineCapStyle = .square
        lineJoinStyle = .bevel
    }

    convenience init(ellipsisWithin rect: CGRect, radius: CGFloat, spacing: CGFloat) {
        self.init()

        let rect1 = CGRect(
            x: rect.midX - radius,
            y: rect.midY - radius - (spacing + radius),
            width: radius * 2,
            height: radius * 2
        )

        let rect2 = CGRect(
            x: rect.midX - radius,
            y: rect.midY - radius,
            width: radius * 2,
            height: radius * 2
        )

        let rect3 = CGRect(
            x: rect.midX - radius,
            y: rect.midY - radius + (spacing + radius),
            width: radius * 2,
            height: radius * 2
        )

        [rect1, rect2, rect3].forEach { append(NSBezierPath(ovalIn: $0)) }

        lineCapStyle = .round
        lineJoinStyle = .round
    }

    convenience init(hamburgerWithin rect: CGRect, thickness: CGFloat, margin: CGSize) {
        self.init()

        self.lineWidth = thickness

        let halfLineWidth = lineWidth / 2

        move(to: .init(x: rect.minX + halfLineWidth + margin.width, y: rect.minY + halfLineWidth + margin.height))
        line(to: .init(x: rect.maxX - halfLineWidth - margin.width, y: rect.minY + halfLineWidth + margin.height))

        move(to: .init(x: rect.minX + halfLineWidth + margin.width, y: rect.midY))
        line(to: .init(x: rect.maxX - halfLineWidth - margin.width, y: rect.midY))

        move(to: .init(x: rect.minX + halfLineWidth + margin.width, y: rect.maxY - halfLineWidth - margin.height))
        line(to: .init(x: rect.maxX - halfLineWidth - margin.width, y: rect.maxY - halfLineWidth - margin.height))

        lineCapStyle = .square
        lineJoinStyle = .bevel
    }
}
