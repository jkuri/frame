import Foundation

extension SelectionOverlayView {
  func constrainToAspect(
    _ original: CGRect,
    delta: CGPoint,
    aspect: CGFloat,
    handle: ResizeHandle
  ) -> CGRect {
    let dw: CGFloat
    let dh: CGFloat

    switch handle {
    case .right:
      dw = delta.x
      dh = dw / aspect
      return CGRect(
        x: original.minX,
        y: original.maxY - (original.height + dh),
        width: max(original.width + dw, 10),
        height: max(original.height + dh, 10)
      )
    case .left:
      dw = -delta.x
      dh = dw / aspect
      let newW = max(original.width + dw, 10)
      let newH = max(original.height + dh, 10)
      return CGRect(
        x: original.maxX - newW,
        y: original.maxY - newH,
        width: newW,
        height: newH
      )
    case .top:
      dh = delta.y
      dw = dh * aspect
      let newW = max(original.width + dw, 10)
      let newH = max(original.height + dh, 10)
      return CGRect(
        x: original.minX,
        y: original.minY,
        width: newW,
        height: newH
      )
    case .bottom:
      dh = -delta.y
      dw = dh * aspect
      let newW = max(original.width + dw, 10)
      let newH = max(original.height + dh, 10)
      return CGRect(
        x: original.minX,
        y: original.maxY - newH,
        width: newW,
        height: newH
      )
    case .topRight:
      dw = delta.x
      dh = dw / aspect
      let newW = max(original.width + dw, 10)
      let newH = max(original.height + dh, 10)
      return CGRect(
        x: original.minX,
        y: original.minY,
        width: newW,
        height: newH
      )
    case .topLeft:
      dw = -delta.x
      dh = dw / aspect
      let newW = max(original.width + dw, 10)
      let newH = max(original.height + dh, 10)
      return CGRect(
        x: original.maxX - newW,
        y: original.minY,
        width: newW,
        height: newH
      )
    case .bottomRight:
      dw = delta.x
      dh = dw / aspect
      let newW = max(original.width + dw, 10)
      let newH = max(original.height + dh, 10)
      return CGRect(
        x: original.minX,
        y: original.maxY - newH,
        width: newW,
        height: newH
      )
    case .bottomLeft:
      dw = -delta.x
      dh = dw / aspect
      let newW = max(original.width + dw, 10)
      let newH = max(original.height + dh, 10)
      return CGRect(
        x: original.maxX - newW,
        y: original.maxY - newH,
        width: newW,
        height: newH
      )
    }
  }
}
