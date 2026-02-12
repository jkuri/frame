import CoreGraphics
import SwiftUI

struct GradientPreset: Identifiable, Sendable {
  let id: Int
  let name: String
  let colors: [Color]
  let startPoint: UnitPoint
  let endPoint: UnitPoint

  var cgColors: [CGColor] {
    colors.map { NSColor($0).cgColor }
  }

  var cgStartPoint: CGPoint {
    CGPoint(x: startPoint.x, y: 1.0 - startPoint.y)
  }

  var cgEndPoint: CGPoint {
    CGPoint(x: endPoint.x, y: 1.0 - endPoint.y)
  }
}

enum GradientPresets {
  static let all: [GradientPreset] = [
    GradientPreset(
      id: 0,
      name: "Purple Blue",
      colors: [Color(red: 0.5, green: 0.2, blue: 0.9), Color(red: 0.2, green: 0.4, blue: 1.0)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    ),
    GradientPreset(
      id: 1,
      name: "Blue Cyan",
      colors: [Color(red: 0.1, green: 0.4, blue: 1.0), Color(red: 0.0, green: 0.8, blue: 0.9)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    ),
    GradientPreset(
      id: 2,
      name: "Green Teal",
      colors: [Color(red: 0.1, green: 0.8, blue: 0.5), Color(red: 0.0, green: 0.6, blue: 0.7)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    ),
    GradientPreset(
      id: 3,
      name: "Orange Red",
      colors: [Color(red: 1.0, green: 0.5, blue: 0.2), Color(red: 0.9, green: 0.2, blue: 0.3)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    ),
    GradientPreset(
      id: 4,
      name: "Pink Purple",
      colors: [Color(red: 1.0, green: 0.3, blue: 0.6), Color(red: 0.6, green: 0.2, blue: 0.9)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    ),
    GradientPreset(
      id: 5,
      name: "Sunset",
      colors: [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 1.0, green: 0.3, blue: 0.5)],
      startPoint: .top,
      endPoint: .bottom
    ),
    GradientPreset(
      id: 6,
      name: "Ocean",
      colors: [Color(red: 0.0, green: 0.3, blue: 0.6), Color(red: 0.1, green: 0.6, blue: 0.8)],
      startPoint: .top,
      endPoint: .bottom
    ),
    GradientPreset(
      id: 7,
      name: "Forest",
      colors: [Color(red: 0.1, green: 0.4, blue: 0.2), Color(red: 0.2, green: 0.7, blue: 0.4)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    ),
    GradientPreset(
      id: 8,
      name: "Berry",
      colors: [Color(red: 0.5, green: 0.1, blue: 0.4), Color(red: 0.8, green: 0.2, blue: 0.5)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    ),
    GradientPreset(
      id: 9,
      name: "Midnight",
      colors: [Color(red: 0.05, green: 0.05, blue: 0.2), Color(red: 0.15, green: 0.15, blue: 0.4)],
      startPoint: .top,
      endPoint: .bottom
    ),
    GradientPreset(
      id: 10,
      name: "Warm Gold",
      colors: [Color(red: 0.9, green: 0.7, blue: 0.3), Color(red: 0.8, green: 0.5, blue: 0.2)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    ),
    GradientPreset(
      id: 11,
      name: "Slate",
      colors: [Color(red: 0.3, green: 0.35, blue: 0.4), Color(red: 0.15, green: 0.18, blue: 0.22)],
      startPoint: .top,
      endPoint: .bottom
    ),
  ]

  static func preset(for id: Int) -> GradientPreset? {
    all.first { $0.id == id }
  }
}
