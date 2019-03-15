import AppKit

public enum Shadows {
}

extension NSShadow {
  convenience init(color: NSColor, offset: NSSize, blur: CGFloat) {
    self.init()

    shadowColor = color
    shadowOffset = offset
    shadowBlurRadius = blur
  }
}
