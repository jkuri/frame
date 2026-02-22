import CoreGraphics

func smoothstep(_ t: Double) -> CGFloat {
  let c = max(0, min(1, t))
  return CGFloat(c * c * c * (c * (c * 6 - 15) + 10))
}
