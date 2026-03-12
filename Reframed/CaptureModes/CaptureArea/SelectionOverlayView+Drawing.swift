import AppKit

extension SelectionOverlayView {
  func drawGrid(context: CGContext, rect: CGRect) {
    let gridColor = ReframedColors.selectionGrid
    context.setStrokeColor(gridColor.cgColor)
    context.setLineWidth(0.5)
    context.setLineDash(phase: 0, lengths: [4, 4])

    let thirdW = rect.width / 3
    for i in 1...2 {
      let x = rect.minX + thirdW * CGFloat(i)
      context.move(to: CGPoint(x: x, y: rect.minY))
      context.addLine(to: CGPoint(x: x, y: rect.maxY))
      context.strokePath()
    }

    let thirdH = rect.height / 3
    for i in 1...2 {
      let y = rect.minY + thirdH * CGFloat(i)
      context.move(to: CGPoint(x: rect.minX, y: y))
      context.addLine(to: CGPoint(x: rect.maxX, y: y))
      context.strokePath()
    }

    let centerColor = ReframedColors.selectionCenter
    context.setStrokeColor(centerColor.cgColor)
    context.setLineWidth(0.5)
    context.setLineDash(phase: 0, lengths: [6, 3])

    let cx = rect.midX
    let cy = rect.midY

    context.move(to: CGPoint(x: cx, y: rect.minY))
    context.addLine(to: CGPoint(x: cx, y: rect.maxY))
    context.strokePath()

    context.move(to: CGPoint(x: rect.minX, y: cy))
    context.addLine(to: CGPoint(x: rect.maxX, y: cy))
    context.strokePath()
  }

  func drawCircularHandles(context: CGContext, rect: CGRect) {
    context.setLineDash(phase: 0, lengths: [])

    for handle in ResizeHandle.allCases {
      let handleRect = handle.rect(for: rect)
      let insetRect = handleRect.insetBy(dx: 1, dy: 1)

      context.setFillColor(ReframedColors.handleFill.cgColor)
      context.fillEllipse(in: insetRect)

      context.setStrokeColor(ReframedColors.handleStroke.cgColor)
      context.setLineWidth(1.5)
      context.strokeEllipse(in: insetRect)
    }
  }
}
