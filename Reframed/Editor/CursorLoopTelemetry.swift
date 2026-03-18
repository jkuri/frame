import CoreGraphics
import Foundation

enum CursorLoopTelemetry {
  static let freezeDuration: Double = 0.67
  static let returnSteps: Int = 20
  static let settleDuration: Double = 0.12
  static let movementThreshold: Double = 0.0015

  static func makeLoopable(
    samples: [CursorSample],
    duration: Double
  ) -> [CursorSample] {
    guard samples.count >= 2, duration > freezeDuration + settleDuration + 0.5 else {
      return samples
    }

    let startPos = CGPoint(x: samples[0].x, y: samples[0].y)
    let startCursorType = samples[0].c

    let lastMovingTime = findLastMovingTime(samples: samples)
    let freezeStart = lastMovingTime
    let returnStart = duration - freezeDuration
    let returnEnd = duration - settleDuration

    guard returnStart > freezeStart else { return samples }

    var result: [CursorSample] = []
    result.reserveCapacity(samples.count + returnSteps + 5)

    for sample in samples {
      if sample.t <= freezeStart {
        result.append(sample)
      }
    }

    guard let lastSample = result.last else { return samples }
    let endPos = CGPoint(x: lastSample.x, y: lastSample.y)
    let endCursorType = lastSample.c

    if returnStart > freezeStart + 0.01 {
      let freezeMid = (freezeStart + returnStart) / 2
      result.append(CursorSample(t: freezeMid, x: endPos.x, y: endPos.y, p: false, c: endCursorType))
      result.append(CursorSample(t: returnStart, x: endPos.x, y: endPos.y, p: false, c: endCursorType))
    }

    let returnDuration = returnEnd - returnStart
    for i in 1...returnSteps {
      let progress = Double(i) / Double(returnSteps)
      let eased = easeOutQuint(progress)
      let t = returnStart + returnDuration * progress
      let x = endPos.x + (startPos.x - endPos.x) * eased
      let y = endPos.y + (startPos.y - endPos.y) * eased
      let cursorType = progress > 0.5 ? startCursorType : endCursorType
      result.append(CursorSample(t: t, x: x, y: y, p: false, c: cursorType))
    }

    result.append(CursorSample(t: duration, x: startPos.x, y: startPos.y, p: false, c: startCursorType))

    return result
  }

  private static func findLastMovingTime(samples: [CursorSample]) -> Double {
    guard samples.count >= 2 else { return samples.last?.t ?? 0 }
    var lastMoving = samples[0].t
    for i in 1..<samples.count {
      let dx = abs(samples[i].x - samples[i - 1].x)
      let dy = abs(samples[i].y - samples[i - 1].y)
      if dx > movementThreshold || dy > movementThreshold {
        lastMoving = samples[i].t
      }
    }
    return lastMoving
  }

  private static func easeOutQuint(_ t: Double) -> Double {
    1.0 - pow(1.0 - t, 5)
  }
}
