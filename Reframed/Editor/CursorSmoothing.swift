import CoreGraphics
import Foundation

enum CursorMovementSpeed: String, Codable, Sendable, CaseIterable, Identifiable {
  case slow
  case medium
  case fast
  case rapid

  var id: String { rawValue }

  var label: String {
    switch self {
    case .slow: "Slow"
    case .medium: "Medium"
    case .fast: "Fast"
    case .rapid: "Rapid"
    }
  }

  var tension: Double {
    switch self {
    case .slow: 80
    case .medium: 170
    case .fast: 300
    case .rapid: 500
    }
  }

  var friction: Double {
    switch self {
    case .slow: 20
    case .medium: 26
    case .fast: 34
    case .rapid: 44
    }
  }

  var mass: Double {
    switch self {
    case .slow: 3.0
    case .medium: 1.5
    case .fast: 1.0
    case .rapid: 0.6
    }
  }
}

enum CursorSmoothing {
  static func smooth(
    samples: [CursorSample],
    speed: CursorMovementSpeed
  ) -> [CursorSample] {
    guard samples.count >= 2 else { return samples }

    let tension = speed.tension
    let friction = speed.friction
    let mass = speed.mass

    var result: [CursorSample] = []
    result.reserveCapacity(samples.count)

    var posX = samples[0].x
    var posY = samples[0].y
    var velX = 0.0
    var velY = 0.0

    result.append(CursorSample(t: samples[0].t, x: posX, y: posY, p: samples[0].p))

    for i in 1..<samples.count {
      let target = samples[i]
      let prev = samples[i - 1]
      let dt = target.t - prev.t
      guard dt > 0 && dt < 1.0 else {
        posX = target.x
        posY = target.y
        velX = 0
        velY = 0
        result.append(CursorSample(t: target.t, x: posX, y: posY, p: target.p))
        continue
      }

      let steps = max(1, Int(ceil(dt / 0.001)))
      let stepDt = dt / Double(steps)

      for _ in 0..<steps {
        let accelX = (tension * (target.x - posX) - friction * velX) / mass
        let accelY = (tension * (target.y - posY) - friction * velY) / mass
        velX += accelX * stepDt
        velY += accelY * stepDt
        posX += velX * stepDt
        posY += velY * stepDt
      }

      result.append(CursorSample(t: target.t, x: posX, y: posY, p: target.p))
    }

    return result
  }
}
