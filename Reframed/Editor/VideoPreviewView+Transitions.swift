import Foundation

extension VideoPreviewView {
  static func computeTransitionProgress(
    time: Double,
    start: Double,
    end: Double,
    entryTransition: RegionTransitionType,
    entryDuration: Double,
    exitTransition: RegionTransitionType,
    exitDuration: Double
  ) -> CGFloat {
    let elapsed = time - start
    let remaining = end - time
    if entryTransition != .none && elapsed < entryDuration {
      return smoothstep(elapsed / entryDuration)
    }
    if exitTransition != .none && remaining < exitDuration {
      return smoothstep(remaining / exitDuration)
    }
    return 1.0
  }

  static func resolveTransitionType(
    time: Double,
    start: Double,
    end: Double,
    entryTransition: RegionTransitionType,
    entryDuration: Double,
    exitTransition: RegionTransitionType,
    exitDuration: Double
  ) -> RegionTransitionType {
    let elapsed = time - start
    let remaining = end - time
    if entryTransition != .none && elapsed < entryDuration { return entryTransition }
    if exitTransition != .none && remaining < exitDuration { return exitTransition }
    return .none
  }
}
