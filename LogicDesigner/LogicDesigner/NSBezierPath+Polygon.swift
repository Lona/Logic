//
//  NSBezierPath+Polygon.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/18/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

extension NSBezierPath {
    convenience init(regularPolygonAt centre: NSPoint, startPoint startCorner: NSPoint, sides: Int) {
        self.init()

        let xDiff = abs(startCorner.x - centre.x)
        let yDiff = abs(startCorner.y - centre.y)
        let radius = sqrt(xDiff * xDiff + yDiff * yDiff)

        if xDiff <= 0 { return }

        // Calc angle at which centre & startCorner are, so we know at what angle to put the first point.
        var degrees = (xDiff == 0) ? 0 : ((yDiff == 0) ? 0.5 * CGFloat.pi : yDiff / xDiff)
        let stepSize = (2.0 * CGFloat.pi) / CGFloat(sides)

        // Draw first corner at start angle:
        var firstCorner = CGPoint.zero
        firstCorner.x = centre.x + radius * cos(degrees)
        firstCorner.y = centre.y + radius * sin(degrees)

        move(to: firstCorner)

        // Now draw following corners:
        for _ in 0..<sides {
            var currCorner = CGPoint.zero

            degrees += stepSize

            if degrees > (2.0 * CGFloat.pi) {
                degrees -= (2.0 * CGFloat.pi)
            }

            currCorner.x = centre.x + radius * cos( degrees )
            currCorner.y = centre.y + radius * sin( degrees )

            line(to: currCorner)
        }

        line(to: firstCorner)
    }
}
